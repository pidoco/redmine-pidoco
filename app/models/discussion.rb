require 'net/http'
require 'json'

class Discussion < ActiveRecord::Base
  # TODO: Should probably refactor a BaseClass from this so all pidoco resources look the same

  include PidocoRequest
  
  belongs_to :pidoco_key # this is is redundant information... on the other hand: prototype means querying the api!
  has_one :project, :through => :pidoco_key
  belongs_to :prototype
  serialize :entries
  after_create :refresh_from_api_if_necessary
  
  acts_as_event(
    :author => l(:via_pidoco_API), 
    :datetime => :last_discussed_at,#Proc.new {|o| Time.at(o.last_entry[0..-4].to_i).to_datetime},
    :title => Proc.new {|o| l(:Discussion) + " #{o.title}"},
    :url => Proc.new {|o| {
      :controller => 'discussions', 
      :action => 'index', 
      :project => o.project.identifier,
      :anchor => "prototype_#{o.prototype_id}_#{o.id}"}},
    :description => Proc.new {|o| l(:review_of_prototype) + o.prototype.name})
  acts_as_activity_provider :timestamp => "#{table_name}.last_discussed_at", :find_options => {:include => {:pidoco_key, :project}}

  def after_find
    if self.prototype && self.pidoco_key
      refresh_from_api_if_necessary
    end
  end
  
  def refresh_from_api_if_necessary
    uri = "prototypes/#{prototype_id}/discussions/#{id}.json"
    res = PidocoRequest::request_if_necessary(uri, self.pidoco_key)
    case res
      when Net::HTTPSuccess
        log_message = "single discussion modified " + res.body
        RAILS_DEFAULT_LOGGER.info(log_message)
        api_data = JSON.parse(res.body)
        update_with_api_data(api_data)
      when Net::HTTPNotModified
        log_message = "single discussion not modified"
        RAILS_DEFAULT_LOGGER.info(log_message)
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
    attributes[:title] = api_data["title"]
    attributes[:prototype_id] = api_data["prototypeId"]
    attributes[:page_id] = api_data["pageId"]
    attributes[:entries] = api_data["entries"]
    attributes[:timestamp] = api_data["timestamp"]
    attributes[:last_discussed_at] = Time.at(api_data["lastEntryDate"].to_i/1000).to_datetime
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
          log_message = "discussions modified "
          log_message += res.body if res.body
          RAILS_DEFAULT_LOGGER.info(log_message)
          id_list = JSON.parse(res.body)
          result = []

          # remove prototypes that are not in the id list
          Discussion.destroy_all(["id NOT IN (?) AND pidoco_key_id = ? AND prototype_id = ?", id_list, pidoco_key, prototype.id])

          id_list.each do |id|
            unless self.exists? id
              p = self.new()
              p.id = id
              p.pidoco_key_id = pidoco_key.id
              p.prototype_id = prototype.id
              p.save
            end
          end
        when Net::HTTPNotModified
          log_message = "discussions not modified"
          RAILS_DEFAULT_LOGGER.info(log_message)
          return false
      end
    end
  end
  
  def self.find_with_api(*args)
    self.poll_if_necessary
    self.find(*args)
  end
  
  
  
end