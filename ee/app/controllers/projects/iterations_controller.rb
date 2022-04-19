# frozen_string_literal: true

class Projects::IterationsController < Projects::ApplicationController
  before_action :check_project_is_group_namespace!
  before_action :check_iterations_available!
  before_action :authorize_show_iteration!
  before_action :set_iteration!, only: [:show], if: -> { project.group.iteration_cadences_feature_flag_enabled? }

  feature_category :team_planning

  def index
    redirect_to project_iteration_cadences_path(project) if project.group.iteration_cadences_feature_flag_enabled?
  end

  def show
    if project.group.iteration_cadences_feature_flag_enabled?
      redirect_to project_iteration_cadence_iteration_path(project, iteration_cadence_id: cadence_id, id: params[:id])
    end
  end

  private

  def check_project_is_group_namespace!
    render_404 if project.personal?
  end

  def set_iteration!
    @iteration ||= IterationsFinder
      .new(current_user, id: params[:id], parent: project.group, include_ancestors: true)
      .execute
      .first

    render_404 if @iteration.nil?
  end

  def cadence_id
    @iteration.iterations_cadence.id
  end

  def check_iterations_available!
    render_404 unless project.feature_available?(:iterations)
  end

  def authorize_show_iteration!
    render_404 unless can?(current_user, :read_iteration, project)
  end
end
