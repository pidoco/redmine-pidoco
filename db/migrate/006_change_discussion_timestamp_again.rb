class ChangeDiscussionTimestampAgain < ActiveRecord::Migration
  def self.up
    rename_column :discussions, :last_entry, :last_discussed_at
  end
  
  def self.down
    rename_column :discussions, :last_discussed_at, :last_entry
  end
end
