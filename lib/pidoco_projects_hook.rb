class PidocoProjectsHook < Redmine::Hook::ViewListener
  render_on :view_projects_show_left, :partial => "prototypes" 
end