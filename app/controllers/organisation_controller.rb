class OrganisationController < ApplicationController
  before_action :set_organisation, only: %i[show edit update]
  before_action :require_admin!, only: %i[edit update]

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
    # @organisation is set via before_action

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

  def edit
    # @organisation is set via before_action
  end

  def update
    # Only allow updating working hours for now
    if @organisation.update(organisation_params)
      redirect_to organisation_path(@organisation), notice: 'Organisation working hours updated successfully.'
    else
      flash.now[:alert] = @organisation.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_organisation
    @organisation = Organisation.find(params[:id])
  end

  def require_admin!
    allowed = current_user&.has_role?(:admin) || current_user&.has_role?(:admin, @organisation)
    return if allowed

    redirect_to organisation_path(@organisation), alert: 'You are not authorized to edit this organisation.'
  end

  def organisation_params
    params.require(:organisation).permit(:work_start_time, :work_end_time)
  end
end
