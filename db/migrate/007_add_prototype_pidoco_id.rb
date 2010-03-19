class AddPrototypePidocoId < ActiveRecord::Migration
  def self.up
    # Don't use the pidoco internal id as rails id
    add_column :prototypes, :pidoco_id, :integer, :null => :false
    Prototype.find(:all).each do |prototype|
      prototype.pidoco_id = prototype.id
      prototype.save
    end
  end
  
  def self.down
    remove_column :prototypes, :pidoco_id
  end
end