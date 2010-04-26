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

module PidocoRequest
  default_settings = Redmine::Plugin.find(:redmine_pidoco).settings[:default]
  HOST = default_settings["HOST"]
  PORT = default_settings["PORT"]
  SSL = default_settings["SSL"]||false
  URI_PREFIX = default_settings["URI_PREFIX"]
  
  def request_if_necessary(uri, pidoco_key, resource_id="", caching=true)
    request_uri = URI_PREFIX + uri + "?api_key=" + pidoco_key.key
    caching_key = request_uri + resource_id.to_s # different resources share the same uri, so we have to append the id
    request = Net::HTTP::Get.new(request_uri)
    last_mod = Setting[:plugin_redmine_pidoco]["last_modified_" + caching_key]
    date = Setting[:plugin_redmine_pidoco]["date_" + caching_key]
    # Don't request more than once every 20 seconds. Otherwise we would end up requesting the prototype too often
    # when displaying all discussions, e.g.
    if date.try(:length) && ((Time.parse(date) + 20) > Time.now) && caching
      log_message = "skipping request for " + uri + ", too frequent"
      RAILS_DEFAULT_LOGGER.info(log_message)
      return nil
    end
    request['If-Modified-Since'] = last_mod if (last_mod && caching)
    begin
      http = Net::HTTP.new(HOST, PORT)
      http.use_ssl = SSL
      response = http.start {|session| session.request(request) }
      # This looks unnecessarily complicated. But if you don't assign the setting with []=, Redmine will not persist it. :-(
      Setting[:plugin_redmine_pidoco] = Setting[:plugin_redmine_pidoco].merge(
        "last_modified_" + caching_key => response['Last-Modified'],
        "date_" + caching_key => response['Date']
      )
      log_message = "response for " + uri
      log_message += " - " + last_mod if last_mod
      log_message += " - " + response['Last-Modified'] if response['Last-Modified']
      RAILS_DEFAULT_LOGGER.info(log_message)
      return response
    rescue Errno::ECONNREFUSED, Timeout::Error, SocketError => e
    # TODO: Not really sure which errors to check for here... but this seems to work at least.
      return response || nil
    end
  end
  
  module_function :request_if_necessary
end