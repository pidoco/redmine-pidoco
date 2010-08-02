# Pidoco Redmine Integration Plugin
# Copyright (C) 2010 
#   Martin Kreichgauer, Pidoco GmbH
#   Jan Schulz-Hofen, Rocket Rentals GmbH
#   Volker Gersabeck, Pidoco GmbH
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
  ProjectsController.send(:helper, :projects)
  Redmine::WikiFormatting::Textile::Helper.send(:include, PidocoWikiFormattingHelperPatch)
end

Redmine::Plugin.register :redmine_pidoco do
  name 'Redmine Pidoco Integration plugin'
  author 'Pidoco GmbH, ROCKET RENTALS GmbH'
  description 'This plugin integrates pidoco° with Redmine.'
  version '1.0'
  
  # require json gem
  config.gem 'json'
  
  project_module :pidoco do
    permission :manage_pidoco, {:pidoco_keys => [:new, :create, :edit, :update, :destroy, :clear_cache]}
    permission :pidoco, {:discussions => [:index]}, :public => true
  end

  menu :project_menu, :pidoco_menu, { :controller => 'discussions', :action => 'index' }, :caption => 'Pidoco°', :after => :activity, :param => :project
  
  activity_provider :discussions
  
  # Production
  settings(:default => {
    "HOST" => 'pidoco.com',
    "PORT" => 443,
    "SSL" => true,
    "URI_PREFIX" => '/rabbit/api/'
  })
  
  # Local testing
  #  settings(:default => {
  #    "HOST" => 'localhost',
  #   "PORT" => 8180,
  #    "SSL" => false,
  #    "URI_PREFIX" => '/rabbit/api/'
  #  })
end
