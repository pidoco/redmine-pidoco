require_dependency 'projects_helper'
#require 'dispatcher'

module PidocoProjectsHelperPatch
  def self.included(base)
    base.send(:include, PidocoProjectsHelperPatch::InstanceMethods)
    
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      puts "Ping"
      alias_method_chain :project_settings_tabs, :pidoco_tab
    end
  end

module InstanceMethods
  def project_settings_tabs_with_pidoco_tab
    tabs = project_settings_tabs_without_pidoco_tab
    pidoco_tab = {:name => 'pidoco', :action => :manage_pidoco, :project_id => @project, :partial => 'projects/settings/pidoco', :label => 'Pidoco'}
    tabs << pidoco_tab if(User.current.allowed_to?(pidoco_tab[:action], @project))
    tabs
  end
end
end
  ProjectsHelper.send(:include, PidocoProjectsHelperPatch) #unless ProjectsHelper.include?(PidocoProjectsHelperPatch)
