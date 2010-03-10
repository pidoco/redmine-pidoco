class PidocoProjectsHook < Redmine::Hook::ViewListener
  def view_projects_show_left(context = {})
    require 'pp'
    pp context[:project]
    if context[:project].module_enabled?(:pidoco)
      context[:controller].send(
          :render_to_string,
          :partial => "pidocobox",
          :locals => {:project => context[:project]})
    end
  end
#  render_on :view_projects_show_left, :partial => "pidocobox" 
  
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
