class Own < ActiveRecord::Base
  attr_accessible :patron_id, :item_id
  belongs_to :patron #, :counter_cache => true #, :polymorphic => true, :validate => true
  belongs_to :item #, :counter_cache => true #, :validate => true

  validates_associated :patron, :item
  validates_presence_of :patron, :item
  validates_uniqueness_of :item_id, :scope => :patron_id
  after_save :reindex
  after_destroy :reindex

  acts_as_list :scope => :item

  attr_accessor :item_identifier

  def reindex
    patron.try(:index)
    item.try(:index)
  end
end

# == Schema Information
#
# Table name: owns
#
#  id         :integer         not null, primary key
#  patron_id  :integer         not null
#  item_id    :integer         not null
#  position   :integer
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

