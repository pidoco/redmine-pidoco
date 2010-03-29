require File.dirname(__FILE__) + '/../test_helper'
require 'json'
require 'fakeweb'

class DiscussionTest < Test::Unit::TestCase
  include Mocha::API

  context "A Discussion instance" do
    setup do
      default_settings = Redmine::Plugin.find(:redmine_pidoco).settings[:default]
      @HOST = default_settings["HOST"]
      @PORT = default_settings["PORT"]
      @URI_PREFIX = default_settings["URI_PREFIX"]
      @prototype = Prototype.first
      @key = PidocoKey.first
      @discussion = Discussion.first
      @http_mock = mock('Net::HTTPSuccess')
      FakeWeb.allow_net_connect = false
      FakeWeb.clean_registry
      Setting[:plugin_redmine_pidoco] = {} # clear the cache
    end

    should "update given api data correctly" do
      fake_data = '{"timestamp":1269721471205,"prototypeId":1,"id":5,"title":"Let\'s get a little discussion going","positionX":296,"pageId":"page7830","positionY":156,"entries":[{"timestamp":1263726016000,"author":"volker@rapidrabb.it","text":"Title set to: Let\'s get a little discussion going"},{"timestamp":1263726033000,"author":"volker@rapidrabb.it","text":"Cats or dogs?"},{"timestamp":1263726038000,"author":"volker@rapidrabb.it","text":"Coffee or tea?"}],"readAt":0,"lastEntryDate":1263726038000,"deleted":-1}'
      @discussion = Discussion.first
      @discussion.update_with_api_data(JSON.parse(fake_data))
      assert_equal "Let's get a little discussion going", @discussion.title 
      assert_equal "page7830", @discussion.page_id
      assert_equal "1269721471205", @discussion.timestamp
    end
  end
  
end