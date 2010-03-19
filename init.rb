require 'redmine'

require 'pidoco_projects_hook'

require 'dispatcher'
require 'pidoco_project_patch'
require 'pidoco_projects_helper_patch'
require 'redmine/wiki_formatting/textile/helper'
require 'pidoco_wiki_formatting_helper_patch'

Dispatcher.to_prepare do
  Project.send(:include, PidocoProjectPatch)
  ProjectsHelper.send(:include, PidocoProjectsHelperPatch)
  Redmine::WikiFormatting::Textile::Helper.send(:include, PidocoWikiFormattingHelperPatch)
end

Redmine::Plugin.register :redmine_pidoco do
  name 'Redmine Pidoco Integration plugin'
  author 'Martin Kreichgauer'
  description 'This plugin integrates pidoco° with Redmine.'
  version '0.1'
  
  # require json gem
  config.gem 'json'
  
  project_module :pidoco do
    permission :manage_pidoco, {:pidoco_keys => [:new, :create, :edit, :update, :destroy, :clear_cache]}
    permission :pidoco, {:discussions => [:index]}, :public => true
  end

  menu :project_menu, :pidoco_menu, { :controller => 'discussions', :action => 'index' }, :caption => 'Pidoco°', :after => :activity, :param => :project
  
  activity_provider :discussions
  settings(:default => {
    "HOST" => 'localhost',
    "PORT" => 8180,
    "SSL" => false,
    "URI_PREFIX" => '/rabbit/api/'
  })
  
#  settings(:default => {
#    "HOST" => 'pidoco.com',
#    "PORT" => 443,
#    "SSL" => true,
#    "URI_PREFIX" => '/rabbit/api/'
#  })
  
end