module PidocoWikiFormattingHelperPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    
    base.class_eval do
      alias_method_chain :wikitoolbar_for, :pidoco
    end
  end
  module InstanceMethods
    def wikitoolbar_for_with_pidoco(field_id)
      if @project and @project.module_enabled?(:pidoco)
        # Is there a simple way to link to a public resource?
        url = "#{Redmine::Utils.relative_url_root}/help/wiki_syntax.html"
        
        help_link = l(:setting_text_formatting) + ': ' +
          link_to(l(:label_help), url,
                  :onclick => "window.open(\"#{ url }\", \"\", \"resizable=yes, location=no, width=300, height=640, menubar=no, status=no, scrollbars=yes\"); return false;")
    
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
