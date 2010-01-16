require 'net/http'
require 'json'

class Discussion < ActiveRecord::Base
  # TODO: Should probably refactor a BaseClass from this so all pidoco resources look the same

  include PidocoRequest
  
  belongs_to :prototype
  belongs_to :pidoco_key, :include => :project # this is is redundant information... on the other hand: prototype means querying!
  serialize :entries
  after_create :refresh_from_api_if_necessary
  
  acts_as_event(
    :author => l(:via_pidoco_API), 
    :url => Proc.new {|o| {:controller => 'discussions', :action => 'index'}},
    :description => Proc.new {|o| l(:review_of_prototype) + o.prototype.name})
  acts_as_activity_provider :find_options => {:include => {:pidoco_key, :project}}

  def after_find
    if self.prototype && self.pidoco_key
      refresh_from_api_if_necessary
    end
  end
  
  def project
    self.pidoco_key.project
  end

  def refresh_from_api_if_necessary
    uri = "prototypes/#{prototype_id}/discussions/#{id}.json"
    res = PidocoRequest::request_if_necessary(uri, self.pidoco_key)
    case res
      when Net::HTTPSuccess
        api_data = JSON.parse(res.body)
        update_with_api_data(api_data)
      when Net::HTTPForbidden
        delete
        return false
      else
        return false
    end
  end
  
  def update_with_api_data(api_data)
    attributes = {}
    attributes[:title] = api_data["title"]
    attributes[:prototype_id] = api_data["prototypeId"]
    attributes[:entries] = api_data["entries"]
    attributes[:timestamp] = api_data["timestamp"]
    attributes[:last_entry] = api_data["lastEntryDate"]
    update_attributes(attributes)
  end
  
  def self.poll_if_necessary
    # TODO: only consider keys for a specific project
    Prototype.all.each do |prototype| # Not entirely sure over what to iterate here
      pidoco_key = prototype.pidoco_key
      uri = "prototypes/#{prototype.id}/discussions.json"
      res = PidocoRequest::request_if_necessary(uri, pidoco_key)
      case res
        when Net::HTTPSuccess
          id_list = JSON.parse(res.body)
          result = []
          id_list.each do |id|
            unless self.exists? id
              p = self.new()
              p.id = id
              p.pidoco_key = pidoco_key
              p.prototype = prototype
              p.save
            end
          end
      end
    end
  end
  
  def self.find_with_api(*args)
    self.poll_if_necessary
    self.find(*args)
  end
  
  
  
end