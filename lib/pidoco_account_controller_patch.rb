require 'redmine'
require 'application'
require 'account_controller'

module PidocoLoginAccountControllerPatch
  def self.included(base)
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :logout, :delete_pidoco_cookie
    end
  end
  module InstanceMethods
    def logout_with_delete_pidoco_cookie
      cookies.delete :JSESSIONID, { :value => '', :path => '/rabbit' }
      logout_without_delete_pidoco_cookie
    end
  end
end

AccountController.send(:include, PidocoLoginAccountControllerPatch)