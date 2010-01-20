module PidocoRequest
  HOST = 'localhost'
  PORT = 8180
  URI_PREFIX = '/rabbit/api/'
  
  def request_if_necessary(uri, pidoco_key)    
    request_uri = URI_PREFIX + uri + "?api_key=" + pidoco_key.key
    expires = Setting[:plugin_redmine_pidoco]["expires_" + request_uri]
    etag = Setting[:plugin_redmine_pidoco]["etag_" + request_uri]
    if expires.try(:length) && (Time.parse(expires) > Time.now)
      return nil
    else
      request = Net::HTTP::Get.new(request_uri)
      request['If-None-Match'] = etag if etag
      begin
        response = Net::HTTP.start(HOST, PORT) { |http| http.request(request) }
        # This looks unnecessarily complicated. But if you don't assign the setting with []=, Redmine will not persist it. :-(
        Setting[:plugin_redmine_pidoco] = Setting[:plugin_redmine_pidoco].merge(
          "expires_" + request_uri => response['Expires'],
          "etag_" + request_uri => response['ETag'])
        response
      rescue Errno::ECONNREFUSED, Timeout::Error, SocketError => e
      # TODO: Not really sure which errors to check for here... but this seems to work at least.
        return nil
      end
    end
  end
  
  module_function :request_if_necessary
end