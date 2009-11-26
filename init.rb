require 'pidoco_account_controller_patch'
require 'pidoco_wiki_formatting_helper_patch'
require 'pidoco_projects_helper_patch'
require 'pidoco_project_patch'
require 'pidoco_projects_hook'

require 'redmine'

Redmine::Plugin.register :redmine_pidoco do
  name 'Redmine Pidoco Integration plugin'
  author 'Martin Kreichgauer'
  description 'This plugin integrates pidoco with Redmine.'
  version '0.0.1'
  
#  Redmine::MenuManager.map :project_menu do |menu|
#    menu.push :pidoco, "/pidoco/discussions/", :caption => 'Pidoco'
#  end
  #menu :top_menu, :pidoco, { :controller => 'pidoco', :action => 'index' }, :caption => 'Prototypes'
  menu :project_menu, :pidoco, { :controller => 'pidoco', :action => 'discussions' }, 
    :caption => 'Pidoco', :after => :activity, :param => :project_id, :public => true
  
  project_module :pidoco do
    permission :manage_pidoco, {:pidoco_keys => [:new, :edit, :destroy]}
  end
  
end