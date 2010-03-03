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
  version '0.0.1'
  
  menu :project_menu, :redmine_pidoco, { :controller => :discussions, :action => 'index' }, :caption => 'pidoco°'
    
  project_module :pidoco do
    permission :manage_pidoco, {:pidoco_keys => [:new, :create, :edit, :update, :destroy, :clear_cache]}
  end
  
  activity_provider :discussions
  settings(:default => {
    "HOST" => 'localhost',
    "PORT" => 8180,
    "URI_PREFIX" => '/rabbit/api/'
  })
  
end