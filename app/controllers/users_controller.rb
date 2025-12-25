class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = User.includes(:organisation).find(params[:id])
    @organisation = @user.organisation

    @latest_event = @user.latest_clock_event_for(@organisation)

    today_range = Time.zone.now.beginning_of_day..Time.zone.now.end_of_day
    @todays_events = @user.clock_events
      .where(organisation_id: @organisation.id, occurred_at: today_range)
      .order(:occurred_at)

    @recent_events = @user.clock_events
      .where(organisation_id: @organisation.id)
      .order(occurred_at: :desc)
      .limit(50)

    @lateness_count = @recent_events.count(&:late?)
    @early_leave_count = @recent_events.count(&:early_leave?)
  end
end
