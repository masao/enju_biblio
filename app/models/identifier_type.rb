class IdentifierType < ActiveRecord::Base
  include MasterModel
  default_scope {order("identifier_types.position")}
  has_many :identifiers
  validates :name, :format => {:with => /\A[0-9a-z][0-9a-z_\-]*[0-9a-z]\Z/}
end

# == Schema Information
#
# Table name: identifier_types
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  display_name :text
#  note         :text
#  position     :integer
#  created_at   :datetime
#  updated_at   :datetime
#
