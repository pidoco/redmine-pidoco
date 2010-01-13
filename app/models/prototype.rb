require 'net/http'
require 'json'

class Prototype < ActiveRecord::Base
  # TODO: Should probably refactor a BaseClass from this so all pidoco resources look the same

  include PidocoRequest
  
  belongs_to :pidoco_key
  after_create :refresh_from_api_if_necessary
  
  def after_find
    self.refresh_from_api_if_necessary
  end

  protected
  def refresh_from_api_if_necessary
    uri = "prototypes/#{self.id}.json"
    res = PidocoRequest::request_if_necessary(uri, self.pidoco_key)
    case res
      when Net::HTTPSuccess
        api_data = JSON.parse(res.body)
        self.update_with_api_data(api_data)
      when Net::HTTPForbidden
        self.delete
        return false
      else
        return false
    end
  end
  
  protected
  def update_with_api_data(api_data)
    attributes = {}
    attributes[:last_modified] = api_data["prototypeData"]["lastModification"]
    if self.last_modified == attributes[:last_modified]
      return false
    end
    attributes[:name] = api_data["prototypeData"]["name"]
    self.update_attributes(attributes)
  end
  
  protected
  def self.poll_prototypes_if_necessary
    # TODO: only consider keys for a specific project
    PidocoKey.all.each do |pidoco_key|
      uri = "prototypes.json"
      res = PidocoRequest::request_if_necessary(uri, pidoco_key)
      case res
        when Net::HTTPSuccess
          id_list = JSON.parse(res.body)
          result = []
          id_list.each do |id|
            unless Prototype.exists? id
              # The following does not set the id. Why?
              #p = Prototype.new(:id => id, :pidoco_key => pidoco_key)
              p = Prototype.new(:pidoco_key => pidoco_key)
              p.id = id
              result << p if p.save 
              # prototype.after_create will take care of fetching the complete data from the api.
            end
          end
      end
    end
  end
  
  def self.find_with_api(*args)
    self.poll_prototypes_if_necessary
    self.find(*args)
  end
  
end