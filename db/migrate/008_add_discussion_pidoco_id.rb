class AddDiscussionPidocoId < ActiveRecord::Migration
  def self.up
    # Don't use the pidoco internal id as rails id
    add_column :discussions, :pidoco_id, :integer, :null => :false
    Discussion.find(:all).each do |discussion|
      discussion.pidoco_id = discussion.id
      discussion.save
    end
  end
  
  def self.down
    remove_column :discussions, :pidoco_id
  end
end