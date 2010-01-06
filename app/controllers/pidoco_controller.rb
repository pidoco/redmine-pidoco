require 'net/http'
require 'json'

class PidocoController < ApplicationController
  unloadable
  before_filter :find_project, :check_project_privacy
  #before_filter :find_apikey, :only => :discussions

  def index

  end
  
  def prototypes
    # TODO Patch to projects controller instead and provide the index method with a @prototypes instance variable?
    result = []
    prototypes = []
    @project.pidoco_keys.each do |pidoco_key|
      # Retrieve the list of prototypes for each key
      prototypes_uri = Pidoco::URI_PREFIX + 'prototypes.json'
      prototypes_uri += '?api_key=' + pidoco_key.key
      req = Pidoco::REQUEST_CLASS[request.method].new(prototypes_uri)
      begin
        res = Net::HTTP.start(Pidoco::HOST, Pidoco::PORT) {|http| http.request(req) }
        case res
          when Net::HTTPSuccess, Net::HTTPRedirection
            prototypes = JSON.parse(res.body)
            # TODO: need to limit number of requests here or do caching. this can easily become a bottleneck! (jsh)
            prototypes.each do |prototype|
              # Retrieve the details for each prototype (usually only 1)
              pages_uri = Pidoco::URI_PREFIX + 'prototypes/' + prototype.to_s + '.json'
              pages_uri += '?api_key=' + pidoco_key.key
              req = Pidoco::REQUEST_CLASS[request.method].new(pages_uri)
              res = Net::HTTP.start(Pidoco::HOST, Pidoco::PORT) {|http| http.request(req) }
              case res
                when Net::HTTPSuccess, Net::HTTPRedirection
                  result << [JSON.parse(res.body), pidoco_key.key]
              end
            end
        end
      # Not really sure which errors to check for here... but this seems to work at least.
      rescue Errno::ECONNREFUSED, Timeout::Error, SocketError => e
        render_404
      end
    end
    render(:json => result)
  end

  def discussions
    @prototypes = []
    @project.pidoco_keys.each do |pidoco_key|
      # Retrieve the list of prototypes for each key
      prototypes_uri = Pidoco::URI_PREFIX + 'prototypes.json'
      prototypes_uri += '?api_key=' + pidoco_key.key
      req = Pidoco::REQUEST_CLASS[request.method].new(prototypes_uri)
      begin
        res = Net::HTTP.start(Pidoco::HOST, Pidoco::PORT) {|http| http.request(req) }
        case res
          when Net::HTTPSuccess, Net::HTTPRedirection
            prototypes = JSON.parse(res.body)
            # TODO: need to limit number of requests here or do caching. this can easily become a bottleneck! (jsh)
            prototypes.each do |prototype|
              # Retrieve the details for each prototype (usually only 1)
              pages_uri = Pidoco::URI_PREFIX + 'prototypes/' + prototype.to_s + '.json?'
              pages_uri += 'api_key=' + pidoco_key.key
              req = Pidoco::REQUEST_CLASS[request.method].new(pages_uri)
              res = Net::HTTP.start(Pidoco::HOST, Pidoco::PORT) {|http| http.request(req) }
              case res
                when Net::HTTPSuccess, Net::HTTPRedirection
                  prototype_data = JSON.parse(res.body)
                  @prototypes << prototype_data
                  @discussions = prototype_data["discussions"]
              end
            end
        end
      # Not really sure which errors to check for here... but this seems to work at least.
      rescue Errno::ECONNREFUSED, Timeout::Error, SocketError => e
        flash.now["error"] = "An error occured while trying to reach the pidoco° server."
      end
    end
  end
  
private
  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
