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
    uri = "prototypes/#{prototype.api_id}/discussions/#{api_id}.json"
    pidoco_key = prototype.pidoco_key
    res = request_if_necessary(uri, pidoco_key) if pidoco_key
    case res
      when Net::HTTPSuccess
        api_data = JSON.parse(res.body)
        update_with_api_data(api_data)
      when Net::HTTPNotModified
        return false
      when Net::HTTPForbidden
        delete
        return false
      else
        return false
    end
  end
  
  def update_with_api_data(api_data)
    update_attributes(
      :title => api_data["title"],
      :page_id => api_data["pageId"],
      :entries => api_data["entries"],
      :timestamp => api_data["timestamp"].to_s,
      :last_discussed_at => Time.at(api_data["lastEntryDate"].to_i/1000).to_datetime
    )
  end
  
  def self.poll_if_necessary(prototype)
    uri = "prototypes/#{prototype.api_id}/discussions.json"
    pidoco_key = prototype.pidoco_key
    res = PidocoRequest::request_if_necessary(uri, pidoco_key) if pidoco_key
    case res
      when Net::HTTPSuccess
        id_list = JSON.parse(res.body)
        result = []

        # remove discussions that are not in the id list
        Discussion.destroy_all(["api_id NOT IN (?) AND prototype_id = ?", id_list, prototype.id])

        id_list.each do |id|
          discussion = Discussion.find_or_create_by_api_id_and_prototype_id(id, prototype.id)
          discussion.prototype_id = prototype.id
          discussion.save # Protoype.discussions will call refresh_from_api_if_necessary and get rest of the data
        end
        return true
      when Net::HTTPNotModified
        log_message = "discussions not modified"
        RAILS_DEFAULT_LOGGER.info(log_message)
        return false
      else
        RAILS_DEFAULT_LOGGER.warn("Unable to reach pidoco when polling discussions for prototype #{prototype.id}")
        return false
    end
  end
  
end