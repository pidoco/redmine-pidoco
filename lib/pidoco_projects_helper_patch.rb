# Pidoco Redmine Integration Plugin
# Copyright (C) 2010 pidoco GmbH
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

module PidocoProjectsHelperPatch
  def self.included(base)
    base.send(:include, PidocoProjectsHelperPatch::InstanceMethods)
    
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
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
