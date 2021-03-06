# Pidoco Redmine Integration Plugin
# Copyright (C) 2010 
#   Martin Kreichgauer, Pidoco GmbH
#   Jan Schulz-Hofen, Rocket Rentals GmbH
#   Volker Gersabeck, Pidoco GmbH
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class PidocoKey < ActiveRecord::Base

  belongs_to :project
  belongs_to :prototype, :dependent => :destroy
  validates_presence_of :key, :project
  validates_associated :project
  after_create :fetch_prototype
    
  attr_accessor :api_id
  include PidocoRequest
  
  alias_method :real_prototype, :prototype
  def prototype
    returning(real_prototype) do |p|
      p.refresh_from_api_if_necessary if p
    end
  end
  
  validates_each( :key, :on => :create ) do |record, attr, value|
    begin
      uri = "prototypes.json"
      # Request the prototype id without caching. We do not care if another key has the result cached.
      res = record.send(:request_if_necessary, uri, record, caching=false) 
      case res
        when Net::HTTPSuccess
          record.api_id = JSON.parse(res.body).first
        else
          if res
            RAILS_DEFAULT_LOGGER.warn "Could not fetch Prototype for key #{record.key}, response was #{res.code}: #{res.body}"
          else
            RAILS_DEFAULT_LOGGER.warn "Could not fetch Prototype for key #{record.key}, response was nil. Maybe a timeout?"
          end
          raise
      end
    rescue
      RAILS_DEFAULT_LOGGER.warn "Could not fetch Prototype api id for key #{record.key}"
      record.errors.add(attr, :invalid)
      false
    end        
  end
  
  
  def fetch_prototype
    begin
      self.prototype = Prototype.create!(:api_id => @api_id)
      self.save!
      self.prototype # invokes refresh_from_api_if_necessary
    rescue
      RAILS_DEFAULT_LOGGER.warn "Could not create Prototype for key #{self.key}"
      return false
    end        
  end
  

end