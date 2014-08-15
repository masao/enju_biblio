class Extent < ActiveRecord::Base
  attr_accessible :name, :display_name, :note
  include MasterModel
  default_scope order: 'extents.position'
  has_many :manifestations
end

# == Schema Information
#
# Table name: extents
#
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  display_name :text
#  note         :text
#  position     :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

