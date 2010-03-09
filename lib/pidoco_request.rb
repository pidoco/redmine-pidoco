module PidocoRequest
  default_settings = Redmine::Plugin.find(:redmine_pidoco).settings[:default]
  HOST = default_settings["HOST"]
  PORT = default_settings["PORT"]
  SSL = default_settings["SSL"]||false
  URI_PREFIX = default_settings["URI_PREFIX"]
  
  def request_if_necessary(uri, pidoco_key)
    request_uri = URI_PREFIX + uri + "?api_key=" + pidoco_key.key
    request = Net::HTTP::Get.new(request_uri)
    last_mod = Setting[:plugin_redmine_pidoco]["last_modified_" + request_uri]
    date = Setting[:plugin_redmine_pidoco]["date_" + request_uri]
    # Don't request more than once every 60 seconds. Otherwise we would end up requesting the prototype too often
    # when displaying all discussions, e.g.
    if date.try(:length) && ((Time.parse(date) + 60) > Time.now)
      return nil
    end
    request['If-Modified-Since'] = last_mod if last_mod
    begin
      http = Net::HTTP.new(HOST, PORT)
      http.use_ssl = SSL
      response = http.start {|session| session.request(request) }
      # This looks unnecessarily complicated. But if you don't assign the setting with []=, Redmine will not persist it. :-(
      Setting[:plugin_redmine_pidoco] = Setting[:plugin_redmine_pidoco].merge(
        "last_modified_" + request_uri => response['Last-Modified'],
        "date_" + request_uri => response['Date']
      )
      return response
    rescue Errno::ECONNREFUSED, Timeout::Error, SocketError => e
    # TODO: Not really sure which errors to check for here... but this seems to work at least.
      return nil
    end
  end
  
  module_function :request_if_necessary
end