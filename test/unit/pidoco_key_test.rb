require File.dirname(__FILE__) + '/../test_helper'
require 'json'
require 'fakeweb'

class PidocoKeyTest < Test::Unit::TestCase

  context "A PidocoKey instance" do
    setup do      
      default_settings = Redmine::Plugin.find(:redmine_pidoco).settings[:default]
      @HOST = default_settings["HOST"]
      @PORT = default_settings["PORT"]
      @URI_PREFIX = default_settings["URI_PREFIX"]
      @key = PidocoKey.first
      FakeWeb.allow_net_connect = false
      FakeWeb.clean_registry
      Setting[:plugin_redmine_pidoco] = {} # clear the cache
    end
    
    should "refresh a prototype before returning it" do
      key = PidocoKey.first
      p = Prototype.first
      key.expects(:real_prototype).returns(p)
      p.expects(:refresh_from_api_if_necessary).returns(true)
      assert_equal p, key.prototype
    end
        
  end
  
end
