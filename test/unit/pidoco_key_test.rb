require File.dirname(__FILE__) + '/../test_helper'
require 'json'
require 'fakeweb'

class PidocoKeyTest < Test::Unit::TestCase

  context "A PidocoKey instance" do
    setup do      
      @key = PidocoKey.new
      @key.key = "mykey"
      @key.project_id = "1"
      # TODO Consider using FakeWeb (http://github.com/chrisk/fakeweb)
      default_settings = Redmine::Plugin.find(:redmine_pidoco).settings[:default]
      @HOST = default_settings["HOST"]
      @PORT = default_settings["PORT"]
      @URI_PREFIX = default_settings["URI_PREFIX"]
      FakeWeb.allow_net_connect = true
#      FakeWeb.register_uri(:get, "http://#{@HOST}:#{@PORT}#{@URI_PREFIX}prototypes.json?api_key=mykey",
#        :body => "[1]", :status => [200, "OK"])
    end
    
    #FIXME
    should "find_or_create_by_id a Prototype when saved" do
      @key.expects(:request_if_necessary).with('prototypes.json', @key, false).once
      #JSON.expects(:parse)
      #Prototype.expects(:find_or_create_by_id).with(1).once.returns(Prototype.new(:id => 1))
      @key.save(false)
    end
        
  end
  
end
