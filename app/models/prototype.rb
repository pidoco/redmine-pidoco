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
  # jsh: ;-)

  include PidocoRequest
  
  has_one :pidoco_key
  has_many :discussions, :dependent => :destroy
  serialize :page_names
  
  alias_method :real_discussions, :discussions
  def discussions
    should_update = Discussion.poll_if_necessary(self)
    returning(real_discussions) do |discussions|
      if should_update
        discussions.each do |discussion|
          discussion.refresh_from_api_if_necessary
        end
      end
    end
  end
  
  def refresh_from_api_if_necessary
    uri = "prototypes/#{api_id}.json"
    res = PidocoRequest::request_if_necessary(uri, pidoco_key) if pidoco_key
    case res
      when Net::HTTPSuccess
        api_data = JSON.parse(res.body)
        update_with_api_data(api_data)
        return true
      when Net::HTTPNotModified
        return false
      when Net::HTTPForbidden
        log_message = "Access to prototype #{id} has been forbidden in pidoco's api. This prototype will not be updated."
        RAILS_DEFAULT_LOGGER.info(log_message)
        return false
      else
        RAILS_DEFAULT_LOGGER.warn("Unable to reach pidoco when refreshing prototype #{id}")
        return false
    end
  end
  
  def update_with_api_data(api_data)
    self.name = api_data["prototypeData"]["name"]
    self.last_modified = api_data["prototypeData"]["lastModification"].to_s
    # this can cause the PidocoRequest::NotModifiedException
    self.page_names = get_page_names_from_api || nil
  rescue PidocoRequest::NotModifiedException
    # nop
  ensure
    save
  end
  
  def get_page_names_from_api
    uri = "prototypes/#{self.api_id}/pages.json"
    res = PidocoRequest::request_if_necessary(uri, self.pidoco_key)
    case res
      when Net::HTTPSuccess
        page_ids = JSON.parse(res.body)
        if page_ids.class == Array
          page_names = {}
          page_ids.each do |page_id|
            page_uri = "prototypes/#{self.api_id}/pages/#{page_id}.json"
            # force a response as we update all page names at once
            page_response = PidocoRequest::request_if_necessary(page_uri, self.pidoco_key, caching=false)
            case page_response
              when Net::HTTPSuccess
                page_json = JSON.parse(page_response.body)
                page_names[page_id] = page_json["name"]
              else
                page_names[page_id] = "unknown"
            end
          end
        elsif page_ids.class == Hash
          # old pidoco API (until 05/2010) returns an object of id-name pairs
          page_names = page_ids
        else
          RAILS_DEFAULT_LOGGER.error "Invalid response while getting page names for prototype #{id}."
        end
      when Net::HTTPNotModified # http says not modified, this is obvious
        raise PidocoRequest::NotModifiedException
      when nil # this could be caused by a general HTTP connection problem
        raise PidocoRequest::NotModifiedException
      else 
        raise PidocoRequest::NotModifiedException
    end
    page_names
  end
  
end