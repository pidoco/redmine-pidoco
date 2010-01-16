class AddPidocoKeyDiscussions < ActiveRecord::Migration
  def self.up
    change_table :discussions do |t|
      # Redundant, but should bring a little performance boost.
      # Otherwise we would call find on Prototype which potentially queries the db and pidoco.
      # Maybe there is a better solution.
      t.integer :pidoco_key_id
    end
  end
  
  def self.down
    drop_table :discussions
  end
end