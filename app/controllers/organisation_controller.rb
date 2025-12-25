class OrganisationController < ApplicationController
  def index
    @organisations = Organisation.includes(:users)

    # Build presence summaries per organisation
    @presence_summary = {}
    @organisations.each do |org|
      user_ids = org.users.select(:id)
      latest = ClockEvent
        .where(organisation_id: org.id, user_id: user_ids)
        .select('DISTINCT ON (user_id) clock_events.*')
        .order('user_id, occurred_at DESC')
      present_count = latest.count(&:clock_in?)
      @presence_summary[org.id] = { users_count: org.users.size, present_count: present_count }
    end
  end

  def show
    @organisation = Organisation.includes(:users).find(params[:id])

    user_ids = @organisation.users.select(:id)

    # Latest event per user for this organisation using Postgres DISTINCT ON
    @latest_events = ClockEvent
      .where(organisation_id: @organisation.id, user_id: user_ids)
      .select('DISTINCT ON (user_id) clock_events.*')
      .order('user_id, occurred_at DESC')
      .includes(:user)
      .index_by(&:user_id)

    today_range = Time.zone.now.beginning_of_day..Time.zone.now.end_of_day
    @todays_events = ClockEvent
      .where(organisation_id: @organisation.id, occurred_at: today_range)
      .includes(:user)
      .order(:occurred_at)
  end
end
