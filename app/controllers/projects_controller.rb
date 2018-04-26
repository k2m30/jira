class ProjectsController < ApplicationController
  def index
    Project.get_list if Project.all.empty?
    @projects = Project.all
  end

  def view
    @project = Project.find_by(name: params[:name])
    period = params[:period].try(:to_i) || 15
    @table = @project.table(period)
    @dates = ((Date.today - period)..Date.today).to_a
  end

  def refresh
    project = Project.find_by(name: params[:name])
    project.snapshots.where(date: Date.today).last.try(:destroy)
    redirect_to view_path(params[:name], params[:period])
  end
end
