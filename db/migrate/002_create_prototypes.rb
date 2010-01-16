class CreatePrototypes < ActiveRecord::Migration
  def self.up
    create_table :prototypes do |t|
      t.column :name, :string
      t.column :pidoco_key_id, :integer
      t.column :last_modified, :integer # TODO: this overflows!
      t.timestamps
    end
  end
  
  def self.down
    drop_table :prototypes
  end
end