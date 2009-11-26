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
      res = Net::HTTP.start(@pidoco_host, @pidoco_port) {|http| http.request(req) }
      case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          prototypes = JSON.parse(res.body)
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
      res = Net::HTTP.start(@pidoco_host, @pidoco_port) {|http| http.request(req) }
      case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          _prototypes = JSON.parse(res.body)
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
  def find_apikey
    @pidoco_key = @project.pidoco_keys.find(:first, :conditions => {:key => params[:api_key]}) 
  rescue ActiveRecord::RecordNotFound
    render_403
  end

private  
  def setup_pidoco
    @request_classes = {:get => Net::HTTP::Get,
      :post => Net::HTTP::Post,
      :put => Net::HTTP::Put,
      :delete => Net::HTTP::Delete}
    @pidoco_host = 'localhost'
    @pidoco_port = 8180
    @pidoco_path_prefix = '/rabbit/api/'
  end
end