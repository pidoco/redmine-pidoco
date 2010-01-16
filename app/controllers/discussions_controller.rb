require 'net/http'
require 'json'

class DiscussionsController < ApplicationController
  unloadable
  before_filter :find_project, :check_project_privacy
  #before_filter :find_apikey, :only => :discussions
  
  def index
    @prototypes = Prototype.find_with_api(:all, :conditions => {:pidoco_key_id => @project.pidoco_keys})
    @discussions = Discussion.find_with_api(:all, :conditions => {:prototype_id => @prototypes})
  end

  private
  def find_project
    @project = Project.find(params[:project])
    rescue ActiveRecord::RecordNotFound
      render_404
  end
end