# jsh: will all your migrations work fine for our existing customers or will they lose data?

class ChangeDiscussionAndPrototypeAssociations < ActiveRecord::Migration
  def self.up
    # Don't use pidoco's internal ids as AR ids
    add_column :prototypes, :api_id, :integer
    add_column :discussions, :api_id, :integer
    Prototype.all.each do |prototype|
      prototype.api_id = prototype.id
      prototype.save!
    end
    Discussion.all.each do |discussion|
      discussion.api_id = discussion.id
      discussion.save!
    end
  end
  
  def self.down

  end
end