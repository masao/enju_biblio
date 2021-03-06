# -*- encoding: utf-8 -*-
require 'spec_helper'

describe Item do
  #pending "add some examples to (or delete) #{__FILE__}"
  fixtures :all

  it "should be rent" do
    items(:item_00001).rent?.should be_true
  end

  it "should not be rent" do
    items(:item_00010).rent?.should be_false
  end

  it "should be checked out" do
    items(:item_00010).checkout!(users(:admin)).should be_true
    items(:item_00010).circulation_status.name.should eq 'On Loan'
  end

  it "should be checked in" do
    items(:item_00001).checkin!.should be_true
    items(:item_00001).circulation_status.name.should eq 'Available On Shelf'
  end

  it "should be retained" do
    old_count = MessageRequest.count
    items(:item_00013).retain(users(:librarian1)).should be_true
    items(:item_00013).reserves.first.state.should eq 'retained'
    MessageRequest.count.should eq old_count + 4
  end

  it "should not be checked out when it is reserved" do
    items(:item_00012).available_for_checkout?.should be_false
  end

  it "should have library_url" do
    items(:item_00001).library_url.should eq "#{LibraryGroup.site_config.url}libraries/web"
  end

  it "should not be able to checkout a removed item" do
    Item.for_checkout.include?(items(:item_00023)).should be_false
  end

  it "should update lending policies" do
    item = items(:item_00001)
    item.checkout_type = CheckoutType.where(:name => 'serial').first
    item.save
    item.reload
    item.lending_policies.where(:user_group_id => 1).first.loan_period.should eq 10
  end
end

# == Schema Information
#
# Table name: items
#
#  id                      :integer          not null, primary key
#  manifestation_id        :integer
#  call_number             :string(255)
#  item_identifier         :string(255)
#  created_at              :datetime
#  updated_at              :datetime
#  deleted_at              :datetime
#  shelf_id                :integer          default(1), not null
#  include_supplements     :boolean          default(FALSE), not null
#  note                    :text
#  url                     :string(255)
#  price                   :integer
#  lock_version            :integer          default(0), not null
#  required_role_id        :integer          default(1), not null
#  required_score          :integer          default(0), not null
#  acquired_at             :datetime
#  bookstore_id            :integer
#  budget_type_id          :integer
#  circulation_status_id   :integer          default(5), not null
#  checkout_type_id        :integer          default(1), not null
#  binding_item_identifier :string(255)
#  binding_call_number     :string(255)
#  binded_at               :datetime
#
