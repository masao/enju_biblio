# -*- encoding: utf-8 -*-
class Manifestation < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  index_name "#{name.downcase.pluralize}-#{Rails.env}"

  after_commit on: :create do
    index_document
    self.parent.__elasticsearch__.update_document if self.parent
    self.index_series_statement
  end

  after_commit on: :update do
    update_document
    self.parent.__elasticsearch__.update_document if self.parent
    self.index_series_statement
  end

  after_commit on: :destroy do
    delete_document
    self.parent.__elasticsearch__.update_document if self.parent
    self.index_series_statement
  end

  settings do
    mappings dynamic: 'false', _routing: {required: true, path: :required_role_id} do
      indexes :title, boost: 2
      indexes :fulltext
      indexes :note
      indexes :creator
      indexes :contributor
      indexes :publisher
      indexes :description
      indexes :statement_of_responsibility
      indexes :item_identifier
      indexes :isbn
      indexes :issn
      indexes :lccn
      indexes :jpno
      indexes :carrier_type
      indexes :library
      indexes :language
      indexes :created_at, type: 'date'
      indexes :updated_at, type: 'date'
      indexes :deleted_at, type: 'date'
      indexes :date_of_publication, type: 'date'
      indexes :pub_date, type: 'date'
      indexes :pub_year, type: 'integer'
      indexes :height, type: 'integer'
      indexes :width, type: 'integer'
      indexes :depth, type: 'integer'
      indexes :volume_number, type: 'integer'
      indexes :issue_number, type: 'integer'
      indexes :serial_number, type: 'integer'
      indexes :start_page, type: 'integer'
      indexes :end_page, type: 'integer'
      indexes :number_of_pages, type: 'integer'
      indexes :price, type: 'integer'
      indexes :repository_content, type: 'boolean'
      indexes :doi
      indexes :periodical, type: 'boolean'
      indexes :series_master, type: 'boolean'
      indexes :acquired_at
      #indexes :creators, type: 'nested' do
      #  indexes :full_name
      #end
    end
  end

  def as_indexed_json(options={})
    as_json(
      #include: {
      #  creators: {only: :full_name},
      #}
    ).merge(
      title: titles,
      item_identifier:
        if series_master?
          root_series_statement.root_manifestation.items.pluck(:item_identifier)
        else
          items.pluck(:item_identifier)
        end,
      creator: creator,
      contributor: contributor,
      publisher: publisher,
      isbn:
        identifier_contents(:isbn).map{|i|
          [Lisbn.new(i).isbn10, Lisbn.new(i).isbn13]
        }.flatten,
      issn:
        if series_statements.exists?
          [identifier_contents(:issn), (series_statements.map{|s| s.manifestation.identifier_contents(:issn)})].flatten.uniq.compact
        else
          identifier_contents(:issn)
        end,
      lccn: identifier_contents(:lccn),
      jpno: identifier_contents(:jpno),
      carrier_type: carrier_type.name,
      library: items.map{|i| i.shelf.library.name},
      language: language.try(:name),
      shelf: items.collect{|i| "#{i.shelf.library.name}_#{i.shelf.name}"},
      pub_date: 
        if series_master?
          root_series_statement.root_manifestation.pub_dates
        else
          pub_dates
        end,
      pub_year: date_of_publication.try(:year),
      doi: identifier_contents(:doi),
      periodical: periodical?,
      series_master: series_master?,
      acquired_at: acquired_at
    )
  end

  enju_circulation_manifestation_model if defined?(EnjuCirculation)
  enju_subject_manifestation_model if defined?(EnjuSubject)
  enju_manifestation_viewer if defined?(EnjuManifestationViewer)
  enju_ndl_ndl_search if defined?(EnjuNdl)
  enju_nii_cinii_books if defined?(EnjuNii)
  enju_export if defined?(EnjuExport)
  enju_oai if defined?(EnjuOai)
  enju_question_manifestation_model if defined?(EnjuQuestion)
  enju_bookmark_manifestation_model if defined?(EnjuBookmark)

  has_many :creates, :dependent => :destroy, :foreign_key => 'work_id'
  has_many :creators, -> {order('creates.position')}, :through => :creates, :source => :agent
  has_many :realizes, :dependent => :destroy, :foreign_key => 'expression_id'
  has_many :contributors, -> {order('realizes.position')}, :through => :realizes, :source => :agent
  has_many :produces, :dependent => :destroy, :foreign_key => 'manifestation_id'
  has_many :publishers, -> {order('produces.position')}, :through => :produces, :source => :agent
  #has_many :exemplifies, :dependent => :destroy
  #has_many :items, :through => :exemplifies
  has_many :items #, :dependent => :destroy
  has_many :children, :foreign_key => 'parent_id', :class_name => 'ManifestationRelationship', :dependent => :destroy
  has_many :parents, :foreign_key => 'child_id', :class_name => 'ManifestationRelationship', :dependent => :destroy
  has_many :derived_manifestations, :through => :children, :source => :child
  has_many :original_manifestations, :through => :parents, :source => :parent
  has_many :picture_files, :as => :picture_attachable, :dependent => :destroy
  belongs_to :language
  belongs_to :carrier_type
  belongs_to :manifestation_content_type, :class_name => 'ContentType', :foreign_key => 'content_type_id'
  has_many :series_statements
  has_one :root_series_statement, :foreign_key => 'root_manifestation_id', :class_name => 'SeriesStatement'
  belongs_to :frequency
  belongs_to :required_role, :class_name => 'Role', :foreign_key => 'required_role_id', :validate => true
  has_one :resource_import_result
  has_many :identifiers, :dependent => :destroy
  belongs_to :nii_type if defined?(EnjuNii)
  accepts_nested_attributes_for :creators, :allow_destroy => true, :reject_if => :all_blank
  accepts_nested_attributes_for :contributors, :allow_destroy => true, :reject_if => :all_blank
  accepts_nested_attributes_for :publishers, :allow_destroy => true, :reject_if => :all_blank
  accepts_nested_attributes_for :series_statements, :allow_destroy => true, :reject_if => :all_blank
  accepts_nested_attributes_for :identifiers, :allow_destroy => true, :reject_if => :all_blank

  #searchable do
    # text フィールドだと区切りのない文字列の index が上手く作成
    #できなかったので。 downcase することにした。
    #他の string 項目も同様の問題があるので、必要な項目は同様の処置が必要。
  #  string :connect_title do
  #    title.join('').gsub(/\s/, '').downcase
  #  end
  #  string :connect_creator do
  #    creator.join('').gsub(/\s/, '').downcase
  #  end
  #  string :connect_publisher do
  #    publisher.join('').gsub(/\s/, '').downcase
  #  end
  #  integer :creator_ids, :multiple => true
  #  integer :contributor_ids, :multiple => true
  #  integer :publisher_ids, :multiple => true
  #  integer :item_ids, :multiple => true
  #  integer :original_manifestation_ids, :multiple => true
  #  integer :parent_ids, :multiple => true do
  #    original_manifestations.pluck(:id)
  #  end
  #  integer :required_role_id
  #  integer :series_statement_ids, :multiple => true
  #  # for OpenURL
  #  text :aulast do
  #    creators.pluck(:last_name)
  #  end
  #  text :aufirst do
  #    creators.pluck(:first_name)
  #  end
  #  text :au do
  #    creator
  #  end
  #  text :atitle do
  #    if periodical? and root_series_statement.nil?
  #      titles
  #    end
  #  end
  #  text :btitle do
  #    title unless periodical?
  #  end
  #  text :jtitle do
  #    if periodical?
  #      if root_series_statement
  #        root_series_statement.titles
  #      else
  #        titles
  #      end
  #    end
  #  end
  #  string :sort_title
  #  boolean :resource_master do
  #    if periodical?
  #      if series_master?
  #        true
  #      else
  #        false
  #      end
  #    else
  #      true
  #    end
  #  end
  #end

  if Setting.uploaded_file.storage == :s3
    has_attached_file :attachment, :storage => :s3,
      :s3_credentials => "#{Setting.amazon}",
      :s3_permissions => :private
  else
    has_attached_file :attachment,
      :path => ":rails_root/private/system/:class/:attachment/:id_partition/:style/:filename"
  end

  validates_presence_of :original_title, :carrier_type, :language
  validates_associated :carrier_type, :language
  validates :start_page, :numericality => true, :allow_blank => true
  validates :end_page, :numericality => true, :allow_blank => true
  validates :manifestation_identifier, :uniqueness => true, :allow_blank => true
  validates :pub_date, :format => {:with => /\A\[{0,1}\d+([\/-]\d{0,2}){0,2}\]{0,1}\z/}, :allow_blank => true
  validates :access_address, :url => true, :allow_blank => true, :length => {:maximum => 255}
  validates :issue_number, :numericality => {:greater_than => 0}, :allow_blank => true
  validates :volume_number, :numericality => {:greater_than => 0}, :allow_blank => true
  validates :serial_number, :numericality => {:greater_than => 0}, :allow_blank => true
  validates :edition, :numericality => {:greater_than => 0}, :allow_blank => true
  after_create :clear_cached_numdocs
  before_save :set_date_of_publication, :set_number
  before_update :touch
  before_destroy :touch, :reload
  normalize_attributes :manifestation_identifier, :pub_date, :original_title
  paginates_per 10

  attr_accessor :during_import, :parent_id

  def set_date_of_publication
    return if pub_date.blank?
    begin
      date = Time.zone.parse(pub_date)
    rescue ArgumentError, TZInfo::AmbiguousTime
      date = nil
    end
    pub_date_string = pub_date.split(';').first.gsub(/[\[\]]/, '')

    while date.nil? do
      pub_date_string += '-01'
      break if pub_date_string =~ /-01-01-01$/
      begin
        date = Time.zone.parse(pub_date_string)
      rescue ArgumentError
        date = nil
      rescue TZInfo::AmbiguousTime
        date = nil
        self.year_of_publication = pub_date_string.to_i if pub_date_string =~ /^\d+$/
        break
      end
    end

    if date
      self.year_of_publication = date.year
      self.month_of_publication = date.month
      if date.year > 0
        self.date_of_publication = date
      end
    end
  end

  def self.cached_numdocs
    Rails.cache.fetch("manifestation_search_total"){Manifestation.search('*').total_count}
  end

  def clear_cached_numdocs
    Rails.cache.delete("manifestation_search_total")
  end

  def parent_of_series
    original_manifestations
  end

  def number_of_pages
    if self.start_page and self.end_page
      page = self.end_page.to_i - self.start_page.to_i + 1
    end
  end

  def titles
    title = []
    title << original_title.to_s.strip
    title << title_transcription.to_s.strip
    title << title_alternative.to_s.strip
    title << volume_number_string
    title << issue_number_string
    title << serial_number.to_s
    title << edition_string
    title << series_statements.map{|s| s.titles}
    #title << original_title.wakati
    #title << title_transcription.wakati rescue nil
    #title << title_alternative.wakati rescue nil
    title.flatten
  end

  def url
    #access_address
    "#{LibraryGroup.site_config.url}#{self.class.to_s.tableize}/#{self.id}"
  end

  def creator
    creators.collect(&:name).flatten
  end

  def contributor
    contributors.collect(&:name).flatten
  end

  def publisher
    publishers.collect(&:name).flatten
  end

  def title
    titles
  end

  # TODO: よりよい推薦方法
  def self.pickup(keyword = nil)
    return nil if self.cached_numdocs < 5
    manifestation = nil
    # TODO: ヒット件数が0件のキーワードがあるときに指摘する
    response = Manifestation.search(
      query: {
        function_score: {
          query: {match_all: {}},
          random_score: {}
        }
      }
    )
    manifestation = response.records.first
  end

  def extract_text
    return nil unless attachment.path
    # TODO: S3 support
    response = `curl "#{Sunspot.config.solr.url}/update/extract?&extractOnly=true&wt=ruby" --data-binary @#{attachment.path} -H "Content-type:text/html"`
    self.fulltext = eval(response)[""]
    save(:validate => false)
  end

  def created(agent)
    creates.where(:agent_id => agent.id).first
  end

  def realized(agent)
    realizes.where(:agent_id => agent.id).first
  end

  def produced(agent)
    produces.where(:agent_id => agent.id).first
  end

  def sort_title
    return nil if RUBY_PLATFORM == 'java'
    if series_master?
      if root_series_statement.title_transcription?
        NKF.nkf('-w --katakana', root_series_statement.title_transcription)
      else
        root_series_statement.original_title
      end
    else
      if title_transcription?
        NKF.nkf('-w --katakana', title_transcription)
      else
        original_title
      end
    end
  end

  def self.find_by_isbn(isbn)
    identifier_type = IdentifierType.where(:name => 'isbn').first
    return nil unless identifier_type
    Manifestation.includes(:identifiers => :identifier_type).where(:"identifiers.body" => isbn, :"identifier_types.name" => 'isbn')
  end

  def index_series_statement
    series_statements.map{|s| s.__elasticsearch__.update_document}
  end

  def acquired_at
    items.order(:acquired_at).first.try(:acquired_at)
  end

  def series_master?
    return true if root_series_statement
    false
  end

  def web_item
    items.where(:shelf_id => Shelf.web.id).first
  end

  def set_agent_role_type(agent_lists, options = {:scope => :creator})
    agent_lists.each do |agent_list|
      name_and_role = agent_list[:full_name].split('||')
      if agent_list[:agent_identifier].present?
        agent = Agent.where(:agent_identifier => agent_list[:agent_identifier]).first
      end
      agent = Agent.where(:full_name => name_and_role[0]).first unless agent
      next unless agent
      type = name_and_role[1].to_s.strip

      case options[:scope]
      when :creator
        type = 'author' if type.blank?
        role_type = CreateType.where(:name => type).first
        create = Create.where(:work_id => self.id, :agent_id => agent.id).first
        if create
          create.create_type = role_type
          create.save(:validate => false)
        end
      when :publisher
        type = 'publisher' if role_type.blank?
        produce = Produce.where(:manifestation_id => self.id, :agent_id => agent.id).first
        if produce
          produce.produce_type = ProduceType.where(:name => type).first
          produce.save(:validate => false)
        end
      else
        raise "#{options[:scope]} is not supported!"
      end
    end
  end

  def set_number
    self.volume_number = volume_number_string.scan(/\d*/).map{|s| s.to_i if s =~ /\d/}.compact.first if volume_number_string and !volume_number?
    self.issue_number = issue_number_string.scan(/\d*/).map{|s| s.to_i if s =~ /\d/}.compact.first if issue_number_string and !issue_number?
    self.edition = edition_string.scan(/\d*/).map{|s| s.to_i if s =~ /\d/}.compact.first if edition_string and !edition?
  end

  def pub_dates
    return [] unless pub_date
    pub_date_array = pub_date.split(';')
    pub_date_array.map{|pub_date_string|
      date = nil
      while date.nil? do
        pub_date_string += '-01'
        break if pub_date_string =~ /-01-01-01$/
        begin
          date = Time.zone.parse(pub_date_string)
        rescue ArgumentError
        rescue TZInfo::AmbiguousTime
        end
      end
      date
    }.compact
  end

  def latest_issue
    if series_master?
      derived_manifestations.where('date_of_publication IS NOT NULL').order('date_of_publication DESC').first
    end
  end

  def first_issue
    if series_master?
      derived_manifestations.where('date_of_publication IS NOT NULL').order('date_of_publication DESC').first
    end
  end

  def identifier_contents(name)
    if IdentifierType.where(:name => name.to_s).exists?
      identifiers.where(:identifier_type_id => IdentifierType.where(:name => name).first.id).pluck(:body)
    else
      []
    end
  end

  def self.export(options = {format: :txt})
    header = %w(
      manifestation_id
      original_title
      creator
      publisher
      pub_date
      price
      isbn
      item_identifier
      call_number
      item_price
      acquired_at
      bookstore
      budget_type
      circulation_status
      shelf
      library
    ).join("\t")
    items = Manifestation.all.map{|m|
      if m.items.exists?
        lines = []
        m.items.each do |i|
          item_lines = []
          item_lines << m.id
          item_lines << m.original_title
          item_lines << m.creators.pluck(:full_name).join("//")
          item_lines << m.publishers.pluck(:full_name).join("//")
          item_lines << m.pub_date
          item_lines << m.price
          item_lines << m.identifier_contents(:isbn).first
          item_lines << i.item_identifier
          item_lines << i.call_number
          item_lines << i.price
          item_lines << i.acquired_at
          item_lines << i.bookstore.try(:name)
          item_lines << i.budget_type.try(:name)
          item_lines << i.circulation_status.try(:name)
          item_lines << i.shelf.name
          item_lines << i.shelf.library.name
          #raise item_lines.to_s if i.item_identifier == '10202'
        lines << item_lines
        end
        lines
      else
        lines = []
        lines << m.id
        lines << m.original_title
        lines << m.creators.pluck(:full_name).join(";")
        lines << m.publishers.pluck(:full_name).join(";")
        lines << m.pub_date
        lines << m.price
        lines << m.identifier_contents(:isbn).first
        [lines]
      end
    }
    if options[:format] == :txt
      items.map{|m| m.map{|i| i.join("\t")}}.flatten.unshift(header).join("\r\n")
    else
      items
    end
  end
end

# == Schema Information
#
# Table name: manifestations
#
#  id                              :integer          not null, primary key
#  original_title                  :text             not null
#  title_alternative               :text
#  title_transcription             :text
#  classification_number           :string(255)
#  manifestation_identifier        :string(255)
#  date_of_publication             :datetime
#  date_copyrighted                :datetime
#  created_at                      :datetime
#  updated_at                      :datetime
#  deleted_at                      :datetime
#  access_address                  :string(255)
#  language_id                     :integer          default(1), not null
#  carrier_type_id                 :integer          default(1), not null
#  extent_id                       :integer          default(1), not null
#  start_page                      :integer
#  end_page                        :integer
#  height                          :integer
#  width                           :integer
#  depth                           :integer
#  price                           :integer
#  fulltext                        :text
#  volume_number_string            :string(255)
#  issue_number_string             :string(255)
#  serial_number_string            :string(255)
#  edition                         :integer
#  note                            :text
#  repository_content              :boolean          default(FALSE), not null
#  lock_version                    :integer          default(0), not null
#  required_role_id                :integer          default(1), not null
#  required_score                  :integer          default(0), not null
#  frequency_id                    :integer          default(1), not null
#  subscription_master             :boolean          default(FALSE), not null
#  attachment_file_name            :string(255)
#  attachment_content_type         :string(255)
#  attachment_file_size            :integer
#  attachment_updated_at           :datetime
#  title_alternative_transcription :text
#  description                     :text
#  abstract                        :text
#  available_at                    :datetime
#  valid_until                     :datetime
#  date_submitted                  :datetime
#  date_accepted                   :datetime
#  date_caputured                  :datetime
#  pub_date                        :string(255)
#  edition_string                  :string(255)
#  volume_number                   :integer
#  issue_number                    :integer
#  serial_number                   :integer
#  content_type_id                 :integer          default(1)
#  year_of_publication             :integer
#  attachment_meta                 :text
#  month_of_publication            :integer
#  fulltext_content                :boolean
#  doi                             :string(255)
#  periodical                      :boolean
#  statement_of_responsibility     :text
#
