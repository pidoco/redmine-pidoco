class AddPidocoKeyPrototypeId < ActiveRecord::Migration
  def self.up
    add_column :pidoco_keys, :prototype_id, :integer
    Prototype.all.each do |prototype|
      prototype.pidoco_key.prototype_id = prototype.id
    end
  end
  
  def self.down
    remove_column :pidoco_keys, :prototype_id
  end
end