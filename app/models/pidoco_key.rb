class PidocoKey < ActiveRecord::Base
  belongs_to :project  
  validates_presence_of :key
end