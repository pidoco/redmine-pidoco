module PidocoWikiFormattingHelperPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    
    base.class_eval do
      alias_method_chain :wikitoolbar_for, :pidoco_wikitoolbar
    end
  end
  module InstanceMethods
    def wikitoolbar_for_with_pidoco_wikitoolbar(field_id)
      if @project and @project.module_enabled?(:pidoco)
        help_link = l(:setting_text_formatting) + ': ' +
          link_to(l(:label_help), compute_public_path('wiki_syntax', 'help', 'html'),
                  :onclick => "window.open(\"#{ compute_public_path('wiki_syntax', 'help', 'html') }\", \"\", \"resizable=yes, location=no, width=300, height=640, menubar=no, status=no, scrollbars=yes\"); return false;")

        stylesheet_link_tag("pidoco", :plugin => 'redmine_pidoco') +
          javascript_include_tag('jstoolbar/jstoolbar') +
          javascript_include_tag('jstoolbar/textile') +
          render(:partial => 'wiki/pidocobar') +
          #javascript_include_tag("pidocobar", :plugin => 'redmine_pidoco') +
          javascript_include_tag("jstoolbar/lang/jstoolbar-#{current_language}") +
          javascript_tag("var toolbar = new jsToolBar($('#{field_id}')); toolbar.setHelpLink('#{help_link}'); toolbar.draw();")
      else
        wikitoolbar_for_without_pidoco_wikitoolbar(field_id)
      end
    end
  end
end
