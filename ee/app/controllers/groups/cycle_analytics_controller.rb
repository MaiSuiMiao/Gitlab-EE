# frozen_string_literal: true

class Groups::CycleAnalyticsController < Groups::ApplicationController
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  include CycleAnalyticsParams

  before_action :whitelist_query_limiting, only: [:show]
  before_action :authorize_group_cycle_analytics!, only: [:show]
  before_action :authorize_cycle_analytics_duration_chart, only: [:duration_chart]

  def show
    respond_to do |format|
      format.json { render json: cycle_analytics_json }
    end
  end

  def duration_chart
    stage_class = ::Gitlab::CycleAnalytics::Stage[params[:stage_id]]
    stage = stage_class.new(options: options(cycle_analytics_params).merge(group: group))

    render json: stage.data_for_duration_chart
  end

  private

  def cycle_analytics_params
    return {} unless params[:cycle_analytics].present?

    params[:cycle_analytics].permit(:start_date, project_ids: [])
  end

  def cycle_analytics_json
    {
      summary: cycle_analytics_stats.summary,
      stats: cycle_analytics_stats.stats,
      permissions: cycle_analytics_stats.permissions(user: current_user)
    }
  end

  def cycle_analytics_stats
    @cycle_analytics_stats ||= ::CycleAnalytics::GroupLevel.new(group: group, options: options(cycle_analytics_params))
  end

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42671')
  end

  def authorize_group_cycle_analytics!
    unless can?(current_user, :read_group_cycle_analytics, group)
      render_403
    end
  end

  def authorize_cycle_analytics_duration_chart
    unless can?(current_user, :read_group_cycle_analytics_duration_chart, group)
      render_403
    end
  end
end
