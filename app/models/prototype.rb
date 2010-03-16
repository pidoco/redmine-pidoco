require 'net/http'
require 'json'

class Prototype < ActiveRecord::Base
  # TODO: Should probably refactor a BaseClass from this so all pidoco resources look the same

  include PidocoRequest
  
  belongs_to :pidoco_key
  has_many :discussions, :dependent => :destroy
  serialize :page_names
  after_create :refresh_from_api_if_necessary

  def after_find
    if self.pidoco_key
      refresh_from_api_if_necessary
    end
  end

  def refresh_from_api_if_necessary
    uri = "prototypes/#{id}.json"
    res = PidocoRequest::request_if_necessary(uri, self.pidoco_key)
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
    attributes = {}
    attributes[:name] = api_data["prototypeData"]["name"]
    page_names = get_page_names_from_api()
    attributes[:page_names] = page_names if page_names
    attributes[:last_modified] = api_data["prototypeData"]["lastModification"]
    update_attributes(attributes)
  end
  
  def get_page_names_from_api
    uri = "prototypes/#{self.id}/pages.json"
    res = PidocoRequest::request_if_necessary(uri, pidoco_key)
    case res
      when Net::HTTPSuccess
        page_names = JSON.parse(res.body)
      else
        page_names = nil
    end
    page_names
  end

  def self.poll_if_necessary
    # TODO: only consider keys for a specific project
    PidocoKey.all.each do |pidoco_key|
      uri = "prototypes.json"
      res = PidocoRequest::request_if_necessary(uri, pidoco_key)
      case res
        when Net::HTTPSuccess
          id_list = JSON.parse(res.body)
          result = []
          prototypes = self.find(:all, :conditions => {:pidoco_key_id => pidoco_key})
          
          # remove prototypes that are not in the id list
          prototypes.each do |prototype|
            id_found = false
            id_list.each do |id|
              if prototype.id == id
                id_found = true
                break
              end
            end
            prototype.destroy unless id_found
          end
          
          # create prototypes that are not yet in the database
          id_list.each do |id|
            unless self.exists? id
              p = self.new()
              p.id = id
              p.pidoco_key = pidoco_key
              p.save
            end
          end
        when Net::HTTPNotModified
          return false
      end
    end
  end
  
  def self.find_with_api(*args)
    self.poll_if_necessary
    self.find(*args)
  end
  
end