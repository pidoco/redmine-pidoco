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

class PidocoKeysController < ApplicationController
  unloadable
  before_filter :find_project, :except => [:select_project]
  before_filter :authorize, :except => [:select_project, :assign_to_project]
  helper :pidoco

  def new
    @pidoco_key = PidocoKey.new :project => @project, :key => (params[:pidoco_key] || {}) 
  end
  
  def select_project
    @projects = Project.visible.find(:all, :order => 'lft').select{ |p| p.wiki && User.current.allowed_to?(:edit_project, p) && User.current.allowed_to?(:edit_wiki_pages, p) }
    flash[:error] = t(:pidoco_no_projects) if @projects.blank?
  end
  
  def assign_to_project
    if request.post?
      begin
        Project.transaction do 
          @project.enabled_modules << EnabledModule.new(:name => 'pidoco')
          key = @project.pidoco_keys.find_or_create_by_key params[:pidoco_key]
          raise unless key.valid?
        end
        flash[:notice] = t(:pidoco_key_assigned)
        redirect_to :controller => 'wiki', :action => 'index', :id => @project
      rescue
        flash[:error] = t(:pidoco_key_assign_error)
        redirect_to :action => 'select_project', :pidoco_key => params[:pidoco_key]
      end
    end
  end
  
  def create
    if request.post? 
      key = params[:pidoco_key][:key]
      key = $1 if /api_key=([\w\d]+)/.match(key)
      @pidoco_key = PidocoKey.new :key => key, :project => @project
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
    if request.post? && @pidoco_key.update_attributes(params[:pidoco_key])
      redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'pidoco'
    end
  end

  def destroy
    # clear the cache for this key
    Setting[:plugin_redmine_pidoco] = Setting[:plugin_redmine_pidoco].update("pidoco_key_#{@pidoco_key.id.to_s}" => nil)
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
