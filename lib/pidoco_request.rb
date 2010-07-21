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
  class NotModifiedException < Exception
  end
  default_settings = Redmine::Plugin.find(:redmine_pidoco).settings[:default]
  HOST = default_settings["HOST"]
  PORT = default_settings["PORT"]
  SSL = default_settings["SSL"]||false
  URI_PREFIX = default_settings["URI_PREFIX"]
  
  def request_if_necessary(uri, pidoco_key, caching=true)
    if pidoco_key.nil? || pidoco_key.key.nil?
        RAILS_DEFAULT_LOGGER.error "Requesting #{uri} failed, because no pidoco key was given."
        return nil
    end
    
    request_uri = URI_PREFIX + uri + "?api_key=" + pidoco_key.key
    # different records of the same resource may share the same uri, so we prepend the pidoco_key id
    caching_key = "pidoco_key_#{pidoco_key.id.to_s}"
    settings_for_pidoco_key = Setting[:plugin_redmine_pidoco][caching_key] || {}
    last_mod = settings_for_pidoco_key["last_modified_" + request_uri]
    date = settings_for_pidoco_key["date_" + request_uri]
    
    # Don't request more than once every 20 seconds. Otherwise we would end up requesting the prototype too often
    # when displaying all discussions, e.g.
    if date.try(:length) && ((Time.parse(date) + 20) > Time.now) && caching
      return nil
    end
    begin
      RAILS_DEFAULT_LOGGER.info "Requesting #{request_uri}"
      request = Net::HTTP::Get.new(request_uri)
      request['If-Modified-Since'] = last_mod if (last_mod && caching)
      http = Net::HTTP.new(HOST, PORT)
      http.use_ssl = SSL
      http.open_timeout = 3
      http.read_timeout = 3
      response = http.start {|session| session.request(request) }
      settings_for_pidoco_key["last_modified_" + request_uri] = response['Last-Modified']
      settings_for_pidoco_key["date_" + request_uri] = response['Date']

      # This looks unnecessarily complicated. But if you don't assign the setting with []=, Redmine will not persist it. :-(
      new_settings = Setting[:plugin_redmine_pidoco]
      if new_settings[caching_key].nil?
        new_settings[caching_key] = {}
      end
      new_settings[caching_key].update(settings_for_pidoco_key)
      Setting[:plugin_redmine_pidoco] = Setting[:plugin_redmine_pidoco].merge(new_settings)
      return response
    rescue Net::HTTPBroken => e
      log_message = "Request for #{request_uri} failed with exception #{e.to_s}"
      RAILS_DEFAULT_LOGGER.warn log_message
      return response || nil
    end
  end
  
  module_function :request_if_necessary
  
  # cf. http://tammersaleh.com/posts/rescuing-net-http-exceptions
  module Net::HTTPBroken; end
  [Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError,
    Errno::ECONNREFUSED, SocketError].each {
     |m| m.send(:include, Net::HTTPBroken)
  }
end