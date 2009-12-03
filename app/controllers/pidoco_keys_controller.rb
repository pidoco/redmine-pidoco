class PidocoKeysController < ApplicationController
  before_filter :find_project, :authorize

  # TODO: should be separate methods: new should handle GET to pidoco_keys/new; create should handle POST to pidoco_keys/
  # http://api.rubyonrails.org/classes/ActionController/Resources.html
  def new
    @pidoco_key = PidocoKey.new((params[:pidoco_key]||{}).merge(:project => @project))
    if request.post? && @pidoco_key.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'pidoco'
    end
  end
  
  # TODO: should be separate methods: edit should handle GET to pidoco_keys/edit; update should handle PUT to pidoco_keys/:id
  # http://api.rubyonrails.org/classes/ActionController/Resources.html
  def edit
    if request.post? && @pidoco_key.update_attributes(params[:pidoco_key])
      redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'pidoco'
    end
  end

  def destroy
    @pidoco_key.destroy
    redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'pidoco'
  end

private
  def find_project
    @project = Project.find(params[:project_id])
    @pidoco_key = @project.pidoco_keys.find(params[:id]) if params[:id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
