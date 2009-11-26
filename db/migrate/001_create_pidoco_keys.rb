class CreatePidocoKeys < ActiveRecord::Migration
  def self.up
    create_table :pidoco_keys do |t|
      t.column :key, :string
      t.column :project_id, :int
    end
  end

  def self.down
    drop_table :pidoco_keys
  end
end
