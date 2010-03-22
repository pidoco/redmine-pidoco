class RemoveDiscussionPidocoKeyId < ActiveRecord::Migration
  def self.up
    remove_column :discussions, :pidoco_key_id
  end
  
  def self.down
    add_column :discussions, :pidoco_key_id, :integer
  end
end