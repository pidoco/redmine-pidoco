class CreatePrototypes < ActiveRecord::Migration
  def self.up
    create_table :prototypes do |t|
      t.column :name, :string
      t.column :pidoco_key_id, :integer
      t.column :last_modified, :string # more convenient not to use AR timestamps here
    end
  end
  
  def self.down
    drop_table :prototypes
  end
end