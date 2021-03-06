require 'mavenlink'
require_relative '../spec_helper'

describe Mavenlink do

  before do
    @cl = Mavenlink::Client.new("999")
  end

  describe "expenses" do
    use_vcr_cassette "expenses", :record => :new_episodes

    it "save an existing expense" do
      exp = @cl.expenses({:workspace_id => 3457635, :order => "date:asc" }).first
      exp.category = "Random Category X"
      exp.save
      saved_exp = @cl.expenses({:workspace_id => 3457635, :order => "date:asc" }).first
      saved_exp.category.should eql("Random Category X")
    end

    it "delete an existing expense" do
      exp = @cl.expenses({:workspace_id => 3403465, :order => "date:asc" }).first
      exp_id = exp.id
      exp.delete
      new_exp = @cl.expenses({:workspace_id => 3403465, :order => "date:asc" }).first
      new_exp.id.should_not eq(exp_id)
    end

    it "reloads an existing workspace" do
      exp = @cl.expenses({:workspace_id => 3457635, :order => "date:asc" })[1]
      exp_copy = @cl.expenses({:workspace_id => 3457635, :order => "date:asc" })[1]
      exp.category.should eq(exp_copy.category)
      exp.category = "Random Category Y"
      exp.save
      exp_copy.category.should_not eq(exp.category)
      exp_copy.reload
      exp_copy.category.should eq(exp.category)
    end

  end

  describe "workspaces" do
    use_vcr_cassette "workspaces", :record => :new_episodes

    it "has a creator" do
      workspace = @cl.workspaces({:search => "8105"}).first
      workspace.creator.should be_an_instance_of Mavenlink::User
      workspace.creator.full_name.should eql("Parth")
    end

    it "has participants" do
      workspace = @cl.workspaces({:search => "API Test Project"}).first
      participants = workspace.participants
      participants.should be_an_array_of(Mavenlink::User, 2)
      participants[1].full_name.should eql("API Test Account 1")
    end

    it "has a primary counterpart" do
      workspace = @cl.workspaces({:search => "API Test Project"}).first
      primary_counterpart = workspace.primary_counterpart
      primary_counterpart.should be_an_instance_of Mavenlink::User
      primary_counterpart.full_name.should eql("API Test Account 1")
    end

    it "doesn't have a primary counterpart" do
      workspace = @cl.workspaces({:search => "8105"}).first
      primary_counterpart = workspace.primary_counterpart
      primary_counterpart.should be_nil
    end

    it "saves an existing workspace" do
      workspace = @cl.workspaces.first
      workspace_title = "Random New Workspace"
      workspace.title = workspace_title
      workspace.save
      workspace_new = @cl.workspaces.first
      workspace_new.title.should eql("Random New Workspace")
    end

    it "reloads an existing workspace" do
      workspace = @cl.workspaces({:only => "3467515"}).first
      workspace_copy = @cl.workspaces({:only => "3467515"}).first
      workspace.title.should eq(workspace_copy.title)
      workspace.title = "Random Workspace MG"
      workspace.save
      workspace_copy.title.should_not eq(workspace.title)
      workspace_copy.reload
      workspace_copy.title.should eq(workspace_copy.title)
    end
  end

  describe "invoices" do
    use_vcr_cassette "invoices", :record => :new_episodes

    it "has time entries" do
      inv = @cl.invoices({:workspace_id => "3457635,3467515", :only => "280315"}).first
      time_entries = inv.time_entries
      time_entries.should be_an_array_of(Mavenlink::TimeEntry, 2)
      time_entry = time_entries[1]
      time_entry.notes.should eql("Additional Notes Example")
      time_entry.time_in_minutes.should eq(300)
    end

    it "has expenses" do
      inv = @cl.invoices({:workspace_id => "3457635,3467515", :only => "280315"}).first
      expenses = inv.expenses
      expenses.should be_an_array_of(Mavenlink::Expense, 1)
      exp = expenses.first
      exp.is_invoiced.should be_true
      exp.notes.should eql("Expense Notes")
    end

    it "returns empty array when no expenses exist" do
      inv = @cl.invoices({:workspace_id => "3457635,3467515", :only => "280335"}).first
      inv.expenses.should be_empty
    end

    it "has additional items" do
      inv = @cl.invoices({:workspace_id => "3457635,3467515", :only => "280335"}).first
      additional_items = inv.additional_items
      additional_items.should be_an_array_of(Hash, 1)
      itm = additional_items.first
      itm["notes"].should eql("Additional Item 1")
    end

    it "has workspaces" do
      inv = @cl.invoices({:workspace_id => "3457635,3467515", :only => "280335"}).first
      workspaces = inv.workspaces
      workspaces.should be_an_array_of(Mavenlink::Workspace, 1)
      wks = workspaces.first
      wks.title.should eql("Random Workspace MG")
      wks.archived.should be_false
    end

    it "has a user" do
      inv = @cl.invoices({:workspace_id => "3457635,3467515", :only => "280335"}).first
      user = inv.user
      user.should be_an_instance_of Mavenlink::User
      user.full_name.should eql("Parth")
      user.headline.should be_nil
    end

  end

  describe "time_entries" do
    use_vcr_cassette "time_entries", :record => :new_episodes

    it "has a user" do
      entries = @cl.time_entries({:workspace_id => 3457635})
      entry = entries.first
      user = entry.user
      user.should be_an_instance_of Mavenlink::User
      user.full_name.should eql("Parth")
    end

    it "has a workspace" do
      entry = @cl.time_entries({:workspace_id => 3457635}).first
      workspace = entry.workspace
      workspace.should be_an_instance_of Mavenlink::Workspace
      workspace.title.should eql("Random New Workspace")
    end

    it "has a story" do
      entry = @cl.time_entries({:workspace_id => 3457635}).first
      story = entry.story
      story.should be_an_instance_of Mavenlink::Post
      story.created_at.should eql("2013-07-29T19:36:48-07:00")
    end

    it "returns nil if no story exists" do
      entry = @cl.time_entries({:only => 8590085}).first
      story = entry.story
      story.should be_nil
    end

    it "can be deleted" do
      ent = @cl.time_entries({:workspace_id => 3467515, :order => "date:asc" }).first
      ent.delete
      new_entries = @cl.expenses({:workspace_id => 3467515, :order => "date:asc" })
      new_entries.should be_empty
    end

    it "can be saved" do
      ent = @cl.time_entries({:only => 8590085}).first
      ent.time_in_minutes = 75
      ent.save
      new_ent = @cl.time_entries({:only => ent.id}).first
      new_ent.time_in_minutes.should eq(75)
    end

  end

end