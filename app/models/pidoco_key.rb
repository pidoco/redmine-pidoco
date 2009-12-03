class PidocoKey < ActiveRecord::Base

  # TODO: This would be better implemented using custom fields

  belongs_to :project  
  validates_presence_of :key
end