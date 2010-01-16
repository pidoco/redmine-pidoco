class CreateDiscussions < ActiveRecord::Migration
  def self.up
    create_table :discussions do |t|
      t.column :title, :string
      t.column :prototype_id, :integer
      t.column :entries, :text
      t.column :timestamp, :integer
      t.column :last_entry, :integer
      t.timestamps
    end
  end
  
  def self.down
    drop_table :discussions
  end
end