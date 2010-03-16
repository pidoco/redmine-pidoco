class PidocoKeysController < ApplicationController
  unloadable
  before_filter :find_project, :authorize

  def new
    @pidoco_key = PidocoKey.new((params[:pidoco_key]||{}).merge(:project => @project))
  end
  
  def create
    if request.post? 
      pp params[:pidoco_key][:key]
      key = params[:pidoco_key][:key]
      key = $1 if /api_key=([\w\d]+)/.match(key)
      @pidoco_key = PidocoKey.new(({:key => key}).merge(:project => @project))
      if @pidoco_key.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'pidoco'
      else
        flash.now[:error] = l(:notice_create_failed)
        render :action => 'new'
      end
    end
  end
  
  def edit
  end

  def update
    # TODO I know I should PUT. No idea how, though. Probably need to fuzz with the routes?
    if request.post? && @pidoco_key.update_attributes(params[:pidoco_key])
      redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'pidoco'
    end
  end

  def destroy
    @pidoco_key.destroy
    
    # clear the cache
    Setting[:plugin_redmine_pidoco] = {}
    
    redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'pidoco'
  end
  
  def clear_cache
    # TODO Maybe this should not be possible for everyone, as soon as we go into production. :)
    Setting[:plugin_redmine_pidoco] = {}
    flash[:notice] = l(:pidoco_cache_cleared)
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
