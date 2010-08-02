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

class PidocoProjectsHook < Redmine::Hook::ViewListener
  def view_projects_show_left(context = {})
    if context[:project].module_enabled?(:pidoco)
      context[:controller].send(
          :render_to_string,
          :partial => "pidocobox",
          :locals => {:project => context[:project]})
    end
  end
  
  # add pidoco icon to activity stream
  def view_layouts_base_html_head(context = {})
    project = context[:project]
    return '' unless project
    controller = context[:controller]
    return '' unless controller
    action_name = controller.action_name
    return '' unless action_name

    if (controller.class.name == 'ProjectsController' and action_name == 'activity')
      o = stylesheet_link_tag "pidoco.css", :plugin => "redmine_pidoco"
      return o
    end
  end
end
