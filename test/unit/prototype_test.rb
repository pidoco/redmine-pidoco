require File.dirname(__FILE__) + '/../test_helper'
require 'json'
require 'fakeweb'

class PidocoKeyTest < Test::Unit::TestCase

  context "A Prototype instance" do
    setup do
      default_settings = Redmine::Plugin.find(:redmine_pidoco).settings[:default]
      @HOST = default_settings["HOST"]
      @PORT = default_settings["PORT"]
      @URI_PREFIX = default_settings["URI_PREFIX"]
      @prototype = Prototype.first
      FakeWeb.allow_net_connect = false
      FakeWeb.clean_registry
      Setting[:plugin_redmine_pidoco] = {} # clear the cache
    end
    
    should "query the API when discussions is called and polling is necessary" do
      Discussion.expects(:poll_if_necessary).returns(true)
      fake_discussions = [Discussion.new, Discussion.new, Discussion.new]
      @prototype.stubs(:real_discussions).returns(fake_discussions)
      fake_discussions.each { |disc| disc.expects(:refresh_from_api_if_necessary).returns(true) }
      assert_equal fake_discussions, @prototype.discussions
    end
    
    should "not query the API when discussions is called and polling is not necessary" do
      Discussion.expects(:poll_if_necessary).returns(false)
      fake_discussions = [Discussion.new, Discussion.new, Discussion.new]
      @prototype.stubs(:real_discussions).returns(fake_discussions)
      Discussion.any_instance.expects(:refresh_from_api_if_necessary).never
      assert_equal fake_discussions, @prototype.discussions
    end
    
    should "update given API Data correctly" do
      @prototype.update_attributes(:name => "lala", :last_modified => 999)
      data = '{"id":3,"versions":{"milestones":[{"revision":1,"created":"1258733946000","name":"autosaved","user":{"id":0,"name":"System"}},{"revision":5,"created":"1259948146000","name":"autosaved","user":{"id":0,"name":"System"}},{"revision":4,"created":"1259765078000","name":"autosaved","user":{"id":0,"name":"System"}},{"revision":2,"created":"1259142273000","name":"autosaved","user":{"id":0,"name":"System"}},{"revision":3,"created":"1259147601000","name":"autosaved","user":{"id":0,"name":"System"}},{"revision":6,"created":"1260368758000","name":"autosaved","user":{"id":0,"name":"System"}},{"revision":7,"created":"1260373146000","name":"autosaved","user":{"id":0,"name":"System"}},{"revision":8,"created":"1260377705000","name":"autosaved","user":{"id":0,"name":"System"}},{"revision":9,"created":"1260557996000","name":"autosaved","user":{"id":0,"name":"System"}},{"revision":10,"created":"1261151361000","name":"autosaved","user":{"id":0,"name":"System"}},{"revision":11,"created":"1264035606000","name":"autosaved","user":{"id":0,"name":"System"}}]},"prototypeData":{"lastModification":1264006130000,"id":3,"lastUser":"Volker","name":"foo type"}}'
      page_names = '{"page2200":"MyPage 3","page7830":"MyPage 2"}'
      @prototype.expects(:get_page_names_from_api).returns(JSON.parse(page_names))
      @prototype.update_with_api_data(JSON.parse(data))
      assert_equal "foo type", @prototype.name
      assert_equal "1264006130000", @prototype.last_modified
      assert_equal "MyPage 2", @prototype.page_names["page7830"]
      assert_equal "MyPage 3", @prototype.page_names["page2200"]
    end
    
    should "return page names object, when page_names is called" do
      page_names = '{"page2200":"MyPage 3","page7830":"MyPage 2"}'
      key = @prototype.pidoco_key
      FakeWeb.register_uri(:get, "http://#{@HOST}:#{@PORT}#{@URI_PREFIX}prototypes/#{@prototype.id}/pages.json?api_key=#{key.key}",
        :body => page_names, :status => [200, "OK"])
      assert_equal JSON.parse(page_names), @prototype.get_page_names_from_api 
    end
        
  end
  
end
