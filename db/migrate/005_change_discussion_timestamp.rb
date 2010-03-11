class ChangeDiscussionTimestamp < ActiveRecord::Migration
  def self.up
    Discussion.delete_all
    change_column :discussions, :last_entry, :timestamp
    Setting[:plugin_redmine_pidoco] = {}
  end
  
  def self.down
    change_column :discussions, :last_entry, :string
  end
end