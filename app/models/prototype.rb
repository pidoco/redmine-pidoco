require 'net/http'
require 'json'

class Prototype < ActiveRecord::Base
  belongs_to :pidoco_key
  validates_presence_of :last_modified
  # TODO: m:n with pidoco_key ?

  def update_api
    uri = Pidoco::URI_PREFIX + "prototypes/#{self.id}.json"
    uri += "?api_key=#{self.pidoco_key.key}"
    puts uri
    req = Net::HTTP::Get.new(uri)
    begin
      res = Net::HTTP.start(Pidoco::HOST, Pidoco::PORT) { |http| http.request(req) }
    rescue Errno::ECONNREFUSED, Timeout::Error, SocketError => e
    # TODO: Not really sure which errors to check for here... but this seems to work at least.
    end
    case res
      when Net::HTTPSuccess
        api_data = JSON.parse(res.body)
        self.update_api_data(api_data)
      when Net::HTTPForbidden
        self.delete
        return false
      else
        return false
    end
  end
  
  def update_api_data(api_data)
    attributes = {}
    attributes[:last_modified] = api_data["prototypeData"]["lastModification"]
    if self.last_modified == attributes[:last_modified]
      return false
    attributes[:name] = api_data["prototypeData"]["name"]
    self.update_attributes(attributes)
  end
  
  def self.update_all_api
    self.all.each do |prototype|
      prototype.update_api
    end
  end
  
end