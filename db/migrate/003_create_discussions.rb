class CreateDiscussions < ActiveRecord::Migration
  def self.up
    create_table :discussions do |t|
      t.column :title, :string
      t.column :prototype_id, :integer
      t.column :page_id, :string
      t.column :entries, :text
      t.column :timestamp, :string
      t.column :last_entry, :string
      t.timestamps
    end
  end
  
  def self.down
    drop_table :discussions
  end
end