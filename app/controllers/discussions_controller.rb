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

require 'net/http'
require 'json'

class DiscussionsController < ApplicationController
  unloadable
  before_filter :find_project, :check_project_privacy
  #before_filter :find_apikey, :only => :discussions
  menu_item :pidoco_menu
  
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