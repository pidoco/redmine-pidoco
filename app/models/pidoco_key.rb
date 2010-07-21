# Pidoco Redmine Integration Plugin
# Copyright (C) 2010 pidoco GmbH
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
  
  include PidocoRequest
  
  alias_method :real_prototype, :prototype
  def prototype
    returning(real_prototype) do |p|
      p.refresh_from_api_if_necessary if p
    end
  end
  
  def fetch_prototype
    uri = "prototypes.json"
    # Request the prototype id without caching. We do not care if another key has the result cached.
    res = request_if_necessary(uri, self, caching=false) 
    case res
      when Net::HTTPSuccess
        begin
          id_list = JSON.parse(res.body)
          self.prototype = Prototype.create!(:api_id => id_list.first)
          self.save!
          self.prototype # invokes refresh_from_api_if_necessary
        rescue
          RAILS_DEFAULT_LOGGER.warn "Could not create Prototype for key #{self.key}"
          return false
        end        
      else
        if res
          RAILS_DEFAULT_LOGGER.warn "Could not fetch Prototype for key #{self.key}, response was #{res.code}: #{res.body}"
        else
          RAILS_DEFAULT_LOGGER.warn "Could not fetch Prototype for key #{self.key}, response was nil. Maybe a timeout?"
        end
        self.errors.add(:key, :invalid)
        false
    end
  end

end