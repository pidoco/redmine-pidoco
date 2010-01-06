module Pidoco
# HOST = 'alphasketch.com'
# PORT = 80
 HOST = 'localhost'
 PORT = 8180
 URI_PREFIX = '/rabbit/api/'
 REQUEST_CLASS = {:get => Net::HTTP::Get,
   :post => Net::HTTP::Post,
   :put => Net::HTTP::Put,
   :delete => Net::HTTP::Delete}
end