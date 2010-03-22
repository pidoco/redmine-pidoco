class RemovePrototypePidocoKeyId < ActiveRecord::Migration
  def self.up
    remove_column :prototypes, :pidoco_key_id
  end
  
  def self.down
    add_column :prototypes, :pidoco_key_id, :integer
  end
end