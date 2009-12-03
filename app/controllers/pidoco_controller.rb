require 'net/http'
require 'json'

class PidocoController < ApplicationController
  unloadable
  before_filter :find_project, :check_project_privacy, :setup_pidoco
  #before_filter :find_apikey, :only => :discussions

  def index

  end
  
  def prototypes
    result = []
    prototypes = []
    @project.pidoco_keys.each do |pidoco_key|
      # Retrieve the list of prototypes for each key
      prototypes_uri = @pidoco_path_prefix + 'prototypes.json?'
      prototypes_uri_with_api_key = prototypes_uri + 'api_key=' + pidoco_key.key # no '&'
      req = @request_classes[request.method].new(prototypes_uri_with_api_key)

      # TODO: think about caching or at least error handling and gracefully failing here in case pidoco server can't be reached (jsh)
      res = Net::HTTP.start(@pidoco_host, @pidoco_port) {|http| http.request(req) }
      case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          prototypes = JSON.parse(res.body)

          # TODO: need to limit number of requests here or do caching. this can easily become a bottleneck! (jsh)
          prototypes.each do |prototype|
            # Retrieve the details for each prototype (usually only 1)
            pages_uri = @pidoco_path_prefix + 'prototypes/' + prototype.to_s + '.json?'
            pages_uri_with_api_key = pages_uri + 'api_key=' + pidoco_key.key # no '&'
            req = @request_classes[request.method].new(pages_uri_with_api_key)
            res = Net::HTTP.start(@pidoco_host, @pidoco_port) {|http| http.request(req) }
            case res
              when Net::HTTPSuccess, Net::HTTPRedirection
                result << [JSON.parse(res.body), pidoco_key.key]
            end
          end
      end
    end
    render(:json => result)
  end

  def discussions
    @prototypes = []
    @project.pidoco_keys.each do |pidoco_key|
      # Retrieve the list of prototypes for each key
      prototypes_uri = @pidoco_path_prefix + 'prototypes.json?'
      prototypes_uri_with_api_key = prototypes_uri + 'api_key=' + pidoco_key.key # no '&'
      req = @request_classes[request.method].new(prototypes_uri_with_api_key)

      # TODO: think about caching or at least error handling and gracefully failing here in case pidoco server can't be reached (jsh)
      res = Net::HTTP.start(@pidoco_host, @pidoco_port) {|http| http.request(req) }
      case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          _prototypes = JSON.parse(res.body)

          # TODO: need to limit number of requests here or do caching. this can easily become a bottleneck! (jsh)
          # QUESTION: why start a variable name with _ ? ;)
          _prototypes.each do |prototype|
          # Retrieve the details for each prototype (usually only 1)
          pages_uri = @pidoco_path_prefix + 'prototypes/' + prototype.to_s + '.json?'
          pages_uri_with_api_key = pages_uri + 'api_key=' + pidoco_key.key # no '&'
          req = @request_classes[request.method].new(pages_uri_with_api_key)
          res = Net::HTTP.start(@pidoco_host, @pidoco_port) {|http| http.request(req) }
          case res
            when Net::HTTPSuccess, Net::HTTPRedirection
              _prototype = JSON.parse(res.body)
              @prototypes << _prototype
              #@prototype_name = _prototype["prototypeData"]["name"]
              @discussions = _prototype["discussions"]
            else
              render(:inline => res.body)
          end
        end
      end
    end
  end
  
  # TODO: remove deprecated code!
  def discussions_old
    uri = @pidoco_path_prefix + "prototypes/" + params[:prototype_id] + ".json?api_key=" + @pidoco_key.key
    req = @request_classes[:get].new(uri)
    res = Net::HTTP.start(@pidoco_host, @pidoco_port) {|http| http.request(req) }
    case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        prototype = JSON.parse(res.body)
        @prototype_name = prototype["prototypeData"]["name"]
        @discussions = prototype["discussions"]
      else
        render(:inline => res.body)
    end
  end
  
private

  # TODO: remove deprecated code! (if you need it later, there's always a VCS history)
  def api(*arg)
    # This method is obsolete. … But maybe we'll need it later.
    # This is a proxy that forwards ajax requests from our plugin to the redmine api.
    result = []
    uri = @pidoco_path_prefix + URI.decode(params[:api_resource]) + '?'
    append_to_request = lambda {|key, value| uri = uri + key + '=' + value + '&' }
    request.parameters.each_pair &append_to_request
    @project.pidoco_keys.each do |pidoco_key|
      uri_with_api_key = uri + 'api_key=' + pidoco_key.key # no '&'
      req = @request_classes[request.method].new(uri_with_api_key)
      res = Net::HTTP.start(@pidoco_host, @pidoco_port) {|http| http.request(req) }
      case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          result << JSON.parse(res.body)
      end
    end
    render(:json => result)
  end
  
private
  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

private

  # TODO: would be nice to have this in a custom field rather than a separate model
  def find_apikey
    @pidoco_key = @project.pidoco_keys.find(:first, :conditions => {:key => params[:api_key]}) 
  rescue ActiveRecord::RecordNotFound
    render_403
  end

private  

  # TODO: should move this to a "Pidoco" module and use constants, like so:
  # module Pidoco
  #   HOST = 'alphasketch.com'
  #   PORT = 80
  #   ...
  #   module AccountControllerPatch
  #     ...
  #   end
  # end
  def setup_pidoco
    @request_classes = {:get => Net::HTTP::Get,
      :post => Net::HTTP::Post,
      :put => Net::HTTP::Put,
      :delete => Net::HTTP::Delete}
    @pidoco_host = 'alphasketch.com'
    @pidoco_port = 80
    @pidoco_path_prefix = '/rabbit/api/'
  end
end
