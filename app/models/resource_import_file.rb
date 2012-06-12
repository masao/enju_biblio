# -*- encoding: utf-8 -*-
class ResourceImportFile < ActiveRecord::Base
  attr_accessible :resource_import, :edit_mode
  include ImportFile
  default_scope :order => 'resource_import_files.id DESC'
  scope :not_imported, where(:state => 'pending')
  scope :stucked, where('created_at < ? AND state = ?', 1.hour.ago, 'pending')

  if configatron.uploaded_file.storage == :s3
    has_attached_file :resource_import, :storage => :s3, :s3_credentials => "#{Rails.root.to_s}/config/s3.yml",
      :path => "resource_import_files/:id/:filename",
      :s3_permissions => :private
  else
    has_attached_file :resource_import,
      :path => ":rails_root/private/system/:attachment/:id/:style/:filename",
      :url => "/system/:attachment/:id/:style/:filename"
  end
  validates_attachment_content_type :resource_import, :content_type => ['text/csv', 'text/plain', 'text/tab-separated-values', 'application/octet-stream']
  validates_attachment_presence :resource_import
  belongs_to :user, :validate => true
  has_many :resource_import_results

  state_machine :initial => :pending do
    event :sm_start do
      transition [:pending, :started] => :started
    end

    event :sm_complete do
      transition :started => :completed
    end

    event :sm_fail do
      transition :started => :failed
    end

    before_transition any => :started do |resource_import_file|
      resource_import_file.executed_at = Time.zone.now
    end

    before_transition any => :completed do |resource_import_file|
      resource_import_file.error_message = nil
    end
  end

  def import_start
    case edit_mode
    when 'create'
      import
    when 'update'
      modify
    when 'destroy'
      remove
    when 'update_relationship'
      update_relationship
    else
      import
    end
  end

  def import
    sm_start!
    self.reload
    num = {:manifestation_imported => 0, :item_imported => 0, :manifestation_found => 0, :item_found => 0, :failed => 0}
    rows = open_import_file
    row_num = 2

    field = rows.first
    if [field['isbn'], field['original_title']].reject{|field| field.to_s.strip == ""}.empty?
      raise "You should specify isbn or original_tile in the first line"
    end

    rows.each do |row|
      next if row['dummy'].to_s.strip.present?
      import_result = ResourceImportResult.create!(:resource_import_file_id => self.id, :body => row.fields.join("\t"))

      item_identifier = row['item_identifier'].to_s.strip
      item = Item.where(:item_identifier => item_identifier).first
      if item
        import_result.item = item
        import_result.manifestation = item.manifestation
        import_result.save!
        num[:item_found] += 1
        next
      end

      if row['manifestation_identifier'].present?
        manifestation = Manifestation.where(:manifestation_identifier => row['manifestation_identifier'].to_s.strip).first
      end

      if row['nbn'].present?
        manifestation = Manifestation.where(:nbn => row['nbn'].to_s.strip).first
      end

      unless manifestation
        if row['isbn'].present?
          isbn = StdNum::ISBN.normalize(row['isbn'])
          m = Manifestation.find_by_isbn(isbn)
          if m
            unless m.series_statement
              manifestation = m
            end
          end
        end
      end
      num[:manifestation_found] += 1 if manifestation

      if row['original_title'].blank?
        unless manifestation
          series_statement = find_series_statement(row)
          begin
            manifestation = Manifestation.import_isbn(isbn)
            if manifestation
              manifestation.series_statement = series_statement
              num[:manifestation_imported] += 1 if manifestation
            end
          rescue EnjuNdl::InvalidIsbn
            manifestation = nil
          rescue EnjuNdl::RecordNotFound
            manifestation = nil
          end
        end
      end

      unless manifestation
        manifestation = fetch(row)
        num[:manifestation_imported] += 1 if manifestation
      end
      import_result.manifestation = manifestation

      if manifestation and item_identifier.present?
        import_result.item = create_item(row, manifestation)
        manifestation.index
      else
        num[:failed] += 1
      end

      ExpireFragmentCache.expire_fragment_cache(manifestation)
      import_result.save!
      num[:item_imported] +=1 if import_result.item

      if row_num % 50 == 0
        Sunspot.commit
        GC.start
      end
      row_num += 1
    end

    Sunspot.commit
    rows.close
    sm_complete!
    Rails.cache.write("manifestation_search_total", Manifestation.search.total)
    return num
  rescue => e
    self.error_message = "line #{row_num}: #{e.message}"
    sm_fail!
    raise e
  end

  def self.import_work(title, patrons, options = {:edit_mode => 'create'})
    work = Manifestation.new(title)
    work.creators = patrons.uniq unless patrons.empty?
    work
  end

  def self.import_expression(work, patrons, options = {:edit_mode => 'create'})
    expression = work
    expression.contributors = patrons.uniq unless patrons.empty?
    expression
  end

  def self.import_manifestation(expression, patrons, options = {}, edit_options = {:edit_mode => 'create'})
    manifestation = expression
    manifestation.during_import = true
    manifestation.update_attributes!(options)
    manifestation.publishers = patrons.uniq unless patrons.empty?
    manifestation
  end

  def self.import_item(manifestation, options)
    item = Item.new(options)
    item.shelf = Shelf.web unless item.shelf
    item.manifestation = manifestation
    item
  end

  def import_marc(marc_type)
    file = File.open(self.resource_import.path)
    case marc_type
    when 'marcxml'
      reader = MARC::XMLReader.new(file)
    else
      reader = MARC::Reader.new(file)
    end
    file.close

    #when 'marc_xml_url'
    #  url = URI(params[:marc_xml_url])
    #  xml = open(url).read
    #  reader = MARC::XMLReader.new(StringIO.new(xml))
    #end

    # TODO
    for record in reader
      manifestation = Manifestation.new(:original_title => expression.original_title)
      manifestation.carrier_type = CarrierType.find(1)
      manifestation.frequency = Frequency.find(1)
      manifestation.language = Language.find(1)
      manifestation.save

      full_name = record['700']['a']
      publisher = Patron.where(:full_name => record['700']['a']).first
      unless publisher
        publisher = Patron.new(:full_name => full_name)
        publisher.save
      end
      manifestation.publishers << publisher
    end
  end

  def self.import
    ResourceImportFile.not_imported.each do |file|
      file.import_start
    end
  rescue
    Rails.logger.info "#{Time.zone.now} importing resources failed!"
  end

  #def import_jpmarc
  #  marc = NKF::nkf('-wc', self.db_file.data)
  #  marc.split("\r\n").each do |record|
  #  end
  #end

  def modify
    sm_start!
    rows = open_import_file
    row_num = 2

    rows.each do |row|
      item_identifier = row['item_identifier'].to_s.strip
      item = Item.where(:item_identifier => item_identifier).first if item_identifier.present?
      if item
        if item.manifestation
          fetch(row, :edit_mode => 'update')
        end
        shelf = Shelf.where(:name => row['shelf']).first
        circulation_status = CirculationStatus.where(:name => row['circulation_status']).first
        checkout_type = CheckoutType.where(:name => row['checkout_type']).first
        bookstore = Bookstore.where(:name => row['bookstore']).first
        required_role = Role.where(:name => row['required_role']).first

        item.shelf = shelf if shelf
        item.circulation_status = circulation_status if circulation_status
        item.checkout_type = checkout_type if checkout_type
        item.bookstore = bookstore if bookstore
        item.required_role = required_role if required_role
        item.include_supplements = row['include_supplements'] if row['include_supplements']
        item.call_number = row['call_number'] if row['call_number']
        item.item_price = row['item_price'] if row['item_price']
        item.acquired_at = row['acquired_at'] if row['acquired_at']
        item.note = row['note'] if row['note']
        item.save!
        ExpireFragmentCache.expire_fragment_cache(item.manifestation)
      else
        manifestation_identifier = row['manifestation_identifier'].to_s.strip
        manifestation = Manifestation.where(:manifestation_identifier => manifestation_identifier).first if manifestation_identifier.present?
        unless manifestation
          manifestation = Manifestation.where(:id => row['manifestation_id']).first
        end
        if manifestation
          fetch(row, :edit_mode => 'update')
        end
      end
      row_num += 1
    end
    sm_complete!
  rescue => e
    self.error_message = "line #{row_num}: #{e.message}"
    sm_fail!
    raise e
  end

  def remove
    sm_start!
    rows = open_import_file
    row_num = 2

    rows.each do |row|
      item_identifier = row['item_identifier'].to_s.strip
      item = Item.where(:item_identifier => item_identifier).first
      if item
        item.destroy if item.deletable?
      end
      row_num += 1
    end
    sm_complete!
  rescue => e
    self.error_message = "line #{row_num}: #{e.message}"
    sm_fail!
    raise e
  end

  def update_relationship
    sm_start!
    rows = open_import_file
    row_num = 2

    rows.each do |row|
      item_identifier = row['item_identifier'].to_s.strip
      item = Item.where(:item_identifier => item_identifier).first
      unless item
        item = Item.where(:id => row['item_id'].to_s.strip).first
      end

      manifestation_identifier = row['manifestation_identifier'].to_s.strip
      manifestation = Manifestation.where(:manifestation_identifier => manifestation_identifier).first
      unless manifestation
        manifestation = Manifestation.where(:id => row['manifestation_id'].to_s.strip).first
      end

      if item and manifestation
        item.manifestation = manifestation
        item.save!
      end

      import_result = ResourceImportResult.create!(:resource_import_file_id => self.id, :body => row.fields.join("\t"))
      import_result.item = item
      import_result.manifestation = manifestation
      import_result.save!
      row_num += 1
    end
    sm_complete!
  end

  private
  def open_import_file
    tempfile = Tempfile.new('patron_import_file')
    if configatron.uploaded_file.storage == :s3
      uploaded_file_path = resource_import.expiring_url(10)
    else
      uploaded_file_path = resource_import.path
    end
    open(uploaded_file_path){|f|
      f.each{|line|
        tempfile.puts(NKF.nkf('-w -Lu', line))
      }
    }
    tempfile.close

    file = CSV.open(tempfile.path, 'r:utf-8', :col_sep => "\t")
    header = file.first
    rows = CSV.open(tempfile.path, 'r:utf-8', :headers => header, :col_sep => "\t")
    ResourceImportResult.create!(:resource_import_file_id => self.id, :body => header.join("\t"))
    tempfile.close(true)
    file.close
    rows
  end

  def import_subject(row)
    subjects = []
    row['subject'].to_s.split('//').each do |s|
      subject = Subject.where(:term => s.to_s.strip).first
      unless subject
        # TODO: Subject typeの設定
        subject = Subject.create(:term => s.to_s.strip, :subject_type_id => 1)
      end
      subjects << subject
    end
    subjects
  end

  def create_item(row, manifestation)
    shelf = Shelf.where(:name => row['shelf'].to_s.strip).first || Shelf.web
    bookstore = Bookstore.where(:name => row['bookstore'].to_s.strip).first
    budget_type = BudgetType.where(:name => row['budget_type'].to_s.strip).first
    acquired_at = Time.zone.parse(row['acquired_at']) rescue nil
    item = self.class.import_item(manifestation, {
      :manifestation_id => manifestation.id,
      :item_identifier => row['item_identifier'],
      :price => row['item_price'],
      :call_number => row['call_number'].to_s.strip,
      :acquired_at => acquired_at,
    })
    if defined?(EnjuCirculation)
      circulation_status = CirculationStatus.where(:name => row['circulation_status'].to_s.strip).first || CirculationStatus.where(:name => 'In Process').first
      use_restriction = UseRestriction.where(:name => row['use_restriction'].to_s.strip).first
      item.circulation_status = circulation_status
      item.use_restriction = use_restriction
    end
    item.bookstore = bookstore
    item.budget_type = budget_type
    item.shelf = shelf
    item
  end

  def fetch(row, options = {:edit_mode => 'create'})
    shelf = Shelf.where(:name => row['shelf'].to_s.strip).first || Shelf.web
    case options[:edit_mode]
    when 'create'
      manifestation = nil
    when 'update'
      manifestation = Item.where(:item_identifier => row['item_identifier'].to_s.strip).first.try(:manifestation)
      unless manifestation
        manifestation_identifier = row['manifestation_identifier'].to_s.strip
        manifestation = Manifestation.where(:manifestation_identifier => manifestation_identifier).first if manifestation_identifier
        manifestation = Manifestation.where(:id => row['manifestation_id']).first unless manifestation
      end
    end

    title = {}
    title[:original_title] = row['original_title'].to_s.strip
    title[:title_transcription] = row['title_transcription'].to_s.strip
    title[:title_alternative] = row['title_alternative'].to_s.strip
    title[:title_alternative_transcription] = row['title_alternative_transcription'].to_s.strip
    if options[:edit_mode] == 'update'
      title[:original_title] = manifestation.original_title if row['original_title'].to_s.strip.blank?
      title[:title_transcription] = manifestation.title_transcription if row['title_transcription'].to_s.strip.blank?
      title[:title_alternative] = manifestation.title_alternative if row['title_alternative'].to_s.strip.blank?
      title[:title_alternative_transcription] = manifestation.title_alternative_transcription if row['title_alternative_transcription'].to_s.strip.blank?
    end
    #title[:title_transcription_alternative] = row['title_transcription_alternative']
    if title[:original_title].blank? and options[:edit_mode] == 'create'
      return nil
    end

    lisbn = Lisbn.new(row['isbn'].to_s.strip)
    if lisbn.isbn.valid?
      isbn = lisbn.isbn
    end
    # TODO: 小数点以下の表現
    width = NKF.nkf('-eZ1', row['width'].to_s).gsub(/\D/, '').to_i
    height = NKF.nkf('-eZ1', row['height'].to_s).gsub(/\D/, '').to_i
    depth = NKF.nkf('-eZ1', row['depth'].to_s).gsub(/\D/, '').to_i
    end_page = NKF.nkf('-eZ1', row['number_of_pages'].to_s).gsub(/\D/, '').to_i
    language = Language.where(:name => row['language'].to_s.strip.camelize).first
    language = Language.where(:iso_639_2 => row['language'].to_s.strip.downcase).first unless language
    language = Language.where(:iso_639_1 => row['language'].to_s.strip.downcase).first unless language

    if end_page >= 1
      start_page = 1
    else
      start_page = nil
      end_page = nil
    end

    creators = row['creator'].to_s.split('//')
    creator_transcriptions = row['creator_transcription'].to_s.split('//')
    creators_list = creators.zip(creator_transcriptions).map{|f,t| {:full_name => f.to_s.strip, :full_name_transcription => t.to_s.strip}}
    contributors = row['contributor'].to_s.split('//')
    contributor_transcriptions = row['contributor_transcription'].to_s.split('//')
    contributors_list = contributors.zip(contributor_transcriptions).map{|f,t| {:full_name => f.to_s.strip, :full_name_transcription => t.to_s.strip}}
    publishers = row['publisher'].to_s.split('//')
    publisher_transcriptions = row['publisher_transcription'].to_s.split('//')
    publishers_list = publishers.zip(publisher_transcriptions).map{|f,t| {:full_name => f.to_s.strip, :full_name_transcription => t.to_s.strip}}
    ResourceImportFile.transaction do
      creator_patrons = Patron.import_patrons(creators_list)
      contributor_patrons = Patron.import_patrons(contributors_list)
      publisher_patrons = Patron.import_patrons(publishers_list)
      #classification = Classification.where(:category => row['classification'].to_s.strip).first
      subjects = import_subject(row) if defined?(EnjuSubject)
      series_statement = import_series_statement(row)
      case options[:edit_mode]
      when 'create'
        work = self.class.import_work(title, creator_patrons, options)
        work.series_statement = series_statement
        if defined?(EnjuSubject)
          work.subjects = subjects.uniq unless subjects.empty?
        end
        expression = self.class.import_expression(work, contributor_patrons)
      when 'update'
        expression = manifestation
        work = expression
        work.series_statement = series_statement if series_statement
        work.creators = creator_patrons.uniq unless creator_patrons.empty?
        expression.contributors = contributor_patrons.uniq unless contributor_patrons.empty?
        if defined?(EnjuSubject)
          work.subjects = subjects.uniq unless subjects.empty?
        end
      end
      if row['volume_number'].present?
        volume_number = row['volume_number'].to_s.tr('０-９', '0-9').to_i
      end

      attributes = {
        :original_title => title[:original_title],
        :title_transcription => title[:title_transcription],
        :title_alternative => title[:title_alternative],
        :title_alternative_transcription => title[:title_alternative_transcription],
        :isbn => isbn,
        :wrong_isbn => row['wrong_isbn'],
        :issn => row['issn'],
        :lccn => row['lccn'],
        :nbn => row['nbn'],
        :ndc => row['ndc'],
        :pub_date => row['pub_date'],
        :volume_number_string => row['volume_number_string'].to_s.split('　').first.try(:tr, '０-９', '0-9'),
        :issue_number_string => row['issue_number_string'],
        :serial_number => row['serial_number'],
        :edition_string => row['edition_string'],
        :width => width,
        :depth => depth,
        :height => height,
        :price => row['manifestation_price'],
        :description => row['description'],
        #:description_transcription => row['description_transcription'],
        :note => row['note'],
        :start_page => start_page,
        :end_page => end_page,
        :access_address => row['access_addres'],
        :manifestation_identifier => row['manifestation_identifier']
      }.delete_if{|key, value| value.nil?}
      manifestation = self.class.import_manifestation(expression, publisher_patrons, attributes,
      {
        :edit_mode => options[:edit_mode]
      })
      manifestation.volume_number = volume_number if volume_number

      required_role = Role.where(:name => row['required_role_name'].to_s.strip.camelize).first
      if required_role and row['required_role_name'].present?
        manifestation.required_role = required_role
      else
        manifestation.required_role = Role.where(:name => 'Guest').first unless manifestation.required_role
      end

      if language and row['language'].present?
        manifestation.language = language
      else
        manifestation.language = Language.where(:name => 'unknown').first unless manifestation.language
      end

      manifestation.series_statement = series_statement if series_statement
      manifestation.save!

      if options[:edit_mode] == 'create'
        manifestation.set_patron_role_type(creators_list)
        manifestation.set_patron_role_type(contributors_list, :scope => :contributor)
        manifestation.set_patron_role_type(publishers_list, :scope => :publisher)
      end
    end
    manifestation
  end

  def import_series_statement(row)
    issn = StdNum::ISSN.normalize(row['issn'].to_s)
    series_statement = find_series_statement(row)
    unless series_statement
      if row['series_title'].to_s.strip.present?
        title = row['series_title'].to_s.strip.split('//')
        title_transcription = row['series_title_transcription'].to_s.strip.split('//')
        series_statement = SeriesStatement.new(
          :original_title => title[0],
          :title_transcription => title_transcription[0],
          :series_statement_identifier => row['series_statement_identifier'].to_s.strip.split('//').first,
          :title_subseries => "#{title[1]} #{title[2]}",
          :title_subseries_transcription => "#{title_transcription[1]} #{title_transcription[2]}"
        )
        if issn.present?
          series_statement.issn = issn
        end
        if row['periodical'].to_s.strip.present?
          series_statement.periodical = true
        end
        series_statement.save!
        if series_statement.periodical
          SeriesStatement.transaction do
            creators = row['series_statement_creator'].to_s.split('//')
            creator_transcriptions = row['series_statement_creator_transcription'].to_s.split('//')
            creators_list = creators.zip(creator_transcriptions).map{|f,t| {:full_name => f.to_s.strip, :full_name_transcription => t.to_s.strip}}
            creator_patrons = Patron.import_patrons(creators_list)
            series_statement.root_manifestation.creators = creator_patrons.uniq unless creator_patrons.empty?
          end
        end
      end
    end
    if series_statement
      series_statement
    else
      nil
    end
  end

  def find_series_statement(row)
    issn = StdNum::ISSN.normalize(row['issn'].to_s)
    series_statement_identifier = row['series_statement_identifier'].to_s.strip
    series_statement_id = row['series_statement_id'].to_s.strip
    series_statement = SeriesStatement.where(:issn => issn).first if issn.present?
    unless series_statement
      series_statement = SeriesStatement.where(:series_statement_identifier => series_statement_identifier).first if series_statement_identifier.present?
    end
    unless series_statement
      series_statement = SeriesStatement.where(:id => series_statement_id).first if series_statement_id
    end
    series_statement = SeriesStatement.where(:original_title => row['series_statement_original_title'].to_s.strip).first unless series_statement
    series_statement
  end
end

# == Schema Information
#
# Table name: resource_import_files
#
#  id                           :integer         not null, primary key
#  parent_id                    :integer
#  content_type                 :string(255)
#  size                         :integer
#  user_id                      :integer
#  note                         :text
#  executed_at                  :datetime
#  state                        :string(255)
#  resource_import_file_name    :string(255)
#  resource_import_content_type :string(255)
#  resource_import_file_size    :integer
#  resource_import_updated_at   :datetime
#  created_at                   :datetime        not null
#  updated_at                   :datetime        not null
#  edit_mode                    :string(255)
#  resource_import_fingerprint  :string(255)
#  error_message                :text
#

