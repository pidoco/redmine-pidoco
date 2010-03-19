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
  validates_presence_of :key
  after_create :get_prototype
  
  alias_method :real_prototype, :prototype
  def prototype
    p = real_prototype
    if p
      p.refresh_from_api_if_necessary
    end
    p
  end
  
  def get_prototype
    uri = "prototypes.json"
    # Request the prototype id without caching. We do not care if another key has the result cached.
    res = PidocoRequest::request_uncached(uri, self) 
    case res
      when Net::HTTPSuccess
        log_message = "prototypes modified "
        log_message += res.body if res.body
        RAILS_DEFAULT_LOGGER.info(log_message)
        id_list = JSON.parse(res.body)
        result = []

        # create prototypes that are not yet in the database or associate with existing
        id_list.each do |id|
          self.prototype_id = id
          self.save
          unless Prototype.exists? id
            p = Prototype.new()
            p.id = id
            p.save
          end
        end
      when Net::HTTPNotModified
        log_message = "prototypes not modified"
        RAILS_DEFAULT_LOGGER.info(log_message)
        return false
    end # case
  end # def

end