module PidocoRequest
  HOST = 'localhost'
  PORT = 8180
  URI_PREFIX = '/rabbit/api/'
  
  def request_if_necessary(uri, pidoco_key)    
    # TODO:
    # if Settings[:pidoco_expires][url] not yet expired return
    # HEAD <resource-url>
    # if Settings[:pidoco_etags][url] == etag from HEAD return
    # otherwise do this: (and don't forget to store new etags/expires!)
    request_uri = URI_PREFIX + uri + "?api_key=" + pidoco_key.key
    puts request_uri
    request = Net::HTTP::Get.new(request_uri)
    begin
      response = Net::HTTP.start(HOST, PORT) { |http| http.request(request) }
    rescue Errno::ECONNREFUSED, Timeout::Error, SocketError => e
    # TODO: Not really sure which errors to check for here... but this seems to work at least.
      return nil
    end
  end
  
  module_function :request_if_necessary
end