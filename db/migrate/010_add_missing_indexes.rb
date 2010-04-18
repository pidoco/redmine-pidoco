class AddMissingIndexes < ActiveRecord::Migration
  def self.up
    add_index :pidoco_keys, :project_id
    add_index :discussions, :prototype_id
    add_index :discussions, :page_id
  end

  def self.down
    remove_index :pidoco_keys, :project_id
    remove_index :discussions, :prototype_id
    remove_index :discussions, :page_id
  end
end
