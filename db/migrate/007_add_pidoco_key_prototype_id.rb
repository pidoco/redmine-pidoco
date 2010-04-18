class AddPidocoKeyPrototypeId < ActiveRecord::Migration
  def self.up
    # TODO: remove this for final release (jsh)
    Thread.current[:host_with_port] = "#{ENV['RAILS_ENV']}.plan.io:443"

    add_column :pidoco_keys, :prototype_id, :integer
    add_index :pidoco_keys, :prototype_id
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