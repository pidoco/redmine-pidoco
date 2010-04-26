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
  
  has_one :pidoco_key
  has_many :discussions, :dependent => :destroy
  serialize :page_names
  
  alias_method :real_discussions, :discussions
  def discussions
    should_update = Discussion.poll_if_necessary(self)
    items = real_discussions
    if should_update
      items.each do |discussion|
        discussion.refresh_from_api_if_necessary
      end
    end
    items
  end
  
  def refresh_from_api_if_necessary
    uri = "prototypes/#{api_id}.json"
    res = PidocoRequest::request_if_necessary(uri, self.pidoco_key, self.id)
    case res
      when Net::HTTPSuccess
        log_message = "single prototype modified "
        log_message += res.body if res.body
        RAILS_DEFAULT_LOGGER.info(log_message)
        api_data = JSON.parse(res.body)
        update_with_api_data(api_data)
        return true
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
    page_names = get_page_names_from_api
    attributes[:page_names] = page_names if page_names
    attributes[:last_modified] = api_data["prototypeData"]["lastModification"].to_s
    update_attributes(attributes)
  end
  
  def get_page_names_from_api
    uri = "prototypes/#{self.api_id}/pages.json"
    res = PidocoRequest::request_if_necessary(uri, self.pidoco_key, self.id)
    case res
      when Net::HTTPSuccess
        page_names = JSON.parse(res.body)
      else
        page_names = nil
    end
    page_names
  end
  
end