class AddPidocoKeyPrototypeId < ActiveRecord::Migration
  def self.up
    add_column :pidoco_keys, :prototype_id, :integer
    Setting[:plugin_redmine_pidoco] = {}
    Prototype.all.each do |prototype|
      key = PidocoKey.find_by_id(prototype.pidoco_key_id)
      key.prototype_id = prototype.id
      key.fetch_prototype # Refresh the data, just to be sure.
    end
    PidocoKey.all.each do |key|
      unless key.prototype_id
        key.destroy
      end
    end
  end
  
  def self.down
    remove_column :pidoco_keys, :prototype_id
  end
end