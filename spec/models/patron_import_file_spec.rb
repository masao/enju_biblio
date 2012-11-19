# -*- encoding: utf-8 -*-
require 'spec_helper'

describe PatronImportFile do
  fixtures :all

  describe "when its mode is 'create'" do
    before(:each) do
      @file = PatronImportFile.create! :patron_import => File.new("#{Rails.root.to_s}/../../examples/patron_import_file_sample1.tsv")
    end

    it "should be imported" do
      old_patrons_count = Patron.count
      old_import_results_count = PatronImportResult.count
      @file.state.should eq 'pending'
      @file.import_start.should eq({:patron_imported => 3, :user_imported => 0, :failed => 0})
      Patron.order('id DESC')[0].full_name.should eq '原田 ushi 隆史'
      Patron.order('id DESC')[1].full_name.should eq '田辺浩介'
      Patron.order('id DESC')[2].date_of_birth.should eq Time.zone.parse('1978-01-01')
      Patron.count.should eq old_patrons_count + 3
      PatronImportResult.count.should eq old_import_results_count + 4

      @file.patron_import_fingerprint.should be_true
      @file.executed_at.should be_true
    end
  end

  describe "when it is written in shift_jis" do
    before(:each) do
      @file = PatronImportFile.create! :patron_import => File.new("#{Rails.root.to_s}/../../examples/patron_import_file_sample3.tsv")
    end

    it "should be imported" do
      old_patrons_count = Patron.count
      old_import_results_count = PatronImportResult.count
      @file.state.should eq 'pending'
      @file.import_start.should eq({:patron_imported => 4, :user_imported => 0, :failed => 0})
      Patron.count.should eq old_patrons_count + 4
      Patron.order('id DESC')[0].full_name.should eq '原田 ushi 隆史'
      Patron.order('id DESC')[1].full_name.should eq '田辺浩介'
      Patron.order('id DESC')[2].email.should eq 'fugafuga@example.jp'
      Patron.order('id DESC')[3].required_role.should eq Role.find_by_name('Guest')
      Patron.order('id DESC')[1].email.should eq 'tanabe@library.example.jp'
      PatronImportResult.count.should eq old_import_results_count + 5

      @file.patron_import_fingerprint.should be_true
      @file.executed_at.should be_true
    end
  end

  describe "when its mode is 'update'" do
    it "should update users" do
      @file = PatronImportFile.create :patron_import => File.new("#{Rails.root.to_s}/../../examples/patron_update_file.tsv")
      @file.modify
      patron_1 = Patron.find(1)
      patron_1.full_name.should eq 'たなべこうすけ'
      patron_1.address_1.should eq '東京都'
      patron_2 = Patron.find(2)
      patron_2.full_name.should eq '田辺浩介'
      patron_2.address_1.should eq '岡山県'
    end
  end

  describe "when its mode is 'destroy'" do
    it "should remove users" do
      old_count = Patron.count
      @file = PatronImportFile.create :patron_import => File.new("#{Rails.root.to_s}/../../examples/patron_delete_file.tsv")
      @file.remove
      Patron.count.should eq old_count - 7
    end
  end
end

# == Schema Information
#
# Table name: patron_import_files
#
#  id                         :integer          not null, primary key
#  parent_id                  :integer
#  content_type               :string(255)
#  size                       :integer
#  user_id                    :integer
#  note                       :text
#  executed_at                :datetime
#  state                      :string(255)
#  patron_import_file_name    :string(255)
#  patron_import_content_type :string(255)
#  patron_import_file_size    :integer
#  patron_import_updated_at   :datetime
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  patron_import_fingerprint  :string(255)
#  error_message              :text
#  edit_mode                  :string(255)
#

