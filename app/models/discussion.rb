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

class Discussion < ActiveRecord::Base

  include PidocoRequest
  
  belongs_to :prototype
  serialize :entries
  
  acts_as_event(
    :author => l(:via_pidoco_API), 
    :datetime => :last_discussed_at,
    :title => Proc.new {|o| l(:Discussion) + " #{o.title}"},
    :url => Proc.new {|o| {
      :controller => 'discussions', 
      :project => o.project.identifier,
      :action => 'index',
      :anchor => "prototype_#{o.prototype_id}_#{o.id}"
    }},
    :description => Proc.new {|o| l(:review_of_prototype) + o.prototype.name}
  )
  acts_as_activity_provider(
    :timestamp => "#{table_name}.last_discussed_at",
    :find_options => {
      :include => { :prototype => { :pidoco_key => :project } }
    }
  )
  
  def project
    prototype.pidoco_key.project
  end
  
  def refresh_from_api_if_necessary
    uri = "prototypes/#{prototype_id}/discussions/#{api_id}.json"
    res = request_if_necessary(uri, self.pidoco_key, self.id)
    case res
      when Net::HTTPSuccess
        log_message = "single discussion modified " + res.body
        RAILS_DEFAULT_LOGGER.info(log_message)
        api_data = JSON.parse(res.body)
        update_with_api_data(api_data)
      when Net::HTTPNotModified
        log_message = "single discussion not modified"
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
    attributes[:title] = api_data["title"]
    attributes[:page_id] = api_data["pageId"]
    attributes[:entries] = api_data["entries"]
    attributes[:timestamp] = api_data["timestamp"].to_s
    attributes[:last_discussed_at] = Time.at(api_data["lastEntryDate"].to_i/1000).to_datetime
    update_attributes(attributes)
  end
  
  def self.poll_if_necessary(prototype)
    pidoco_key = prototype.pidoco_key
    uri = "prototypes/#{prototype.id}/discussions.json"
    res = PidocoRequest::request_if_necessary(uri, pidoco_key, prototype.id)
    case res
      when Net::HTTPSuccess
        log_message = "discussions modified "
        log_message += res.body if res.body
        RAILS_DEFAULT_LOGGER.info(log_message)
        id_list = JSON.parse(res.body)
        result = []

        # remove discussions that are not in the id list
        Discussion.destroy_all(["id NOT IN (?) AND prototype_id = ?", id_list, prototype.id])

        id_list.each do |id|
          unless self.exists? id
            p = self.new()
            p.id = id
            p.prototype_id = prototype.id
            p.save # Protoype.discussions will call refresh_from_api_if_necessary and get rest of the data
          end
        end
        return true
      when Net::HTTPNotModified
        log_message = "discussions not modified"
        RAILS_DEFAULT_LOGGER.info(log_message)
        return false
    end
  end
  
  def self.find_with_api(*args)
    should_update = self.poll_if_necessary
    discussions = self.find(*args)
    if should_update
      discussions.each do |discussion|
        discussion.refresh_from_api_if_necessary
      end
    end
    discussions
  end
  
end