class PidocoKey < ActiveRecord::Base

  # TODO: This would be better implemented using custom fields
  # Not anymore! :)

  belongs_to :project
  has_many :prototypes, :dependent => :destroy
  validates_presence_of :key

end