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

module PidocoWikiFormattingHelperPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    
    base.class_eval do
      alias_method_chain :wikitoolbar_for, :pidoco unless method_defined?(:wikitoolbar_for_without_pidoco)
    end
  end
  module InstanceMethods
    def wikitoolbar_for_with_pidoco(field_id)
      
      # jsh: WE NEED TO DISCUSS THIS :) THIS IS LIKELY TO BREAK IN FUTURE REDMINE VERSIONS... 
      
      if @project and @project.module_enabled?(:pidoco)
        # Is there a simple way to link to a public resource?
        url = "#{Redmine::Utils.relative_url_root}/help/wiki_syntax.html"
        
        help_link = l(:setting_text_formatting) + ': ' +
          link_to(l(:label_help), url,
                  :onclick => "window.open(\"#{ url }\", \"\", \"resizable=yes, location=no, width=300, height=640, menubar=no, status=no, scrollbars=yes\"); return false;")
    
        stylesheet_link_tag("pidoco", :plugin => 'redmine_pidoco') +
          javascript_include_tag('jstoolbar/jstoolbar') +
          javascript_include_tag('jstoolbar/textile') +
          render(:partial => 'wiki/pidocobar') +
          javascript_include_tag("jstoolbar/lang/jstoolbar-#{current_language.to_s.downcase}") +
          javascript_tag("var wikiToolbar = new jsToolBar($('#{field_id}')); wikiToolbar.setHelpLink('#{help_link}'); wikiToolbar.draw();")
      else
        wikitoolbar_for_without_pidoco(field_id)
      end
    end
  end
end
