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

require 'net/http'
require 'json'

class Prototype < ActiveRecord::Base
  # TODO too much code duplication

  include PidocoRequest
  
  belongs_to :pidoco_key
  has_many :discussions, :dependent => :destroy
  serialize :page_names
  after_create :refresh_from_api_if_necessary

  def refresh_from_api_if_necessary
    uri = "prototypes/#{id}.json"
    res = PidocoRequest::request_if_necessary(uri, self.pidoco_key)
    case res
      when Net::HTTPSuccess
        log_message = "single prototype modified "
        log_message += res.body if res.body
        RAILS_DEFAULT_LOGGER.info(log_message)
        api_data = JSON.parse(res.body)
        update_with_api_data(api_data)
      when Net::HTTPNotModified
        log_message = "single prototype not modified"
        RAILS_DEFAULT_LOGGER.info(log_message)
        return false
      when Net::HTTPForbidden
        delete
        return false
      else
        return false
    end
  end
  
  def update_with_api_data(api_data)
    attributes = {}
    attributes[:name] = api_data["prototypeData"]["name"]
    page_names = get_page_names_from_api()
    attributes[:page_names] = page_names if page_names
    attributes[:last_modified] = api_data["prototypeData"]["lastModification"]
    update_attributes(attributes)
  end
  
  def get_page_names_from_api
    uri = "prototypes/#{self.id}/pages.json"
    res = PidocoRequest::request_if_necessary(uri, pidoco_key)
    case res
      when Net::HTTPSuccess
        page_names = JSON.parse(res.body)
      else
        page_names = nil
    end
    page_names
  end

  def self.poll_if_necessary
    # TODO: only consider keys for a specific project
    PidocoKey.all.each do |pidoco_key|
      uri = "prototypes.json"
      res = PidocoRequest::request_if_necessary(uri, pidoco_key)
      case res
        when Net::HTTPSuccess
          log_message = "prototypes modified "
          log_message += res.body if res.body
          RAILS_DEFAULT_LOGGER.info(log_message)
          id_list = JSON.parse(res.body)
          result = []
          
          # delete all prototypes that are not in the id list
          self.destroy_all(["id NOT IN (?) AND pidoco_key_id = ?", id_list, pidoco_key])
          
          # create prototypes that are not yet in the database
          id_list.each do |id|
            unless self.exists? id
              p = self.new()
              p.id = id
              p.pidoco_key = pidoco_key
              p.save
            end
          end
        when Net::HTTPNotModified
          log_message = "prototypes not modified"
          RAILS_DEFAULT_LOGGER.info(log_message)
          return false
      end
    end
  end
  
  def self.find_with_api(*args)
    should_update = self.poll_if_necessary
    prototypes = self.find(*args)
    if should_update
      prototypes.each do |prototype|
        prototype.refresh_from_api_if_necessary
      end
    end
    prototypes
  end
  
end