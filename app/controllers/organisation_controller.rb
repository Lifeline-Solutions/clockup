class OrganisationController < ApplicationController
  before_action :set_organisation, only: %i[show edit update]
  before_action :require_admin!, only: %i[new create edit update]

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

    # Determine filter range
    period = params[:period].presence || 'today'
    now = Time.zone.now
    range = case period
            when 'today'
              now.beginning_of_day..now.end_of_day
            when 'yesterday'
              (now - 1.day).beginning_of_day..(now - 1.day).end_of_day
            when 'this_week'
              now.beginning_of_week..now.end_of_week
            when 'last_week'
              (now - 1.week).beginning_of_week..(now - 1.week).end_of_week
            when 'last_month'
              last_month = now.last_month
              last_month.beginning_of_month..last_month.end_of_month
            when 'month'
              m = params[:month].to_i
              y = params[:year].to_i
              if m.between?(1, 12) && y.positive?
                start = Time.zone.local(y, m, 1).beginning_of_day
                finish = start.end_of_month.end_of_day
                start..finish
              else
                now.beginning_of_day..now.end_of_day
              end
            else
              now.beginning_of_day..now.end_of_day
            end

    @period_label = case period
                    when 'today' then 'Today'
                    when 'yesterday' then 'Yesterday'
                    when 'this_week' then 'This Week'
                    when 'last_week' then 'Last Week'
                    when 'last_month' then 'Last Month'
                    when 'month'
                      m = params[:month].to_i
                      y = params[:year].to_i
                      m.between?(1, 12) && y.positive? ? Date::MONTHNAMES[m] + " #{y}" : 'Selected Month'
                    else
                      'Today'
                    end

    @events = ClockEvent
      .where(organisation_id: @organisation.id, occurred_at: range)
      .includes(:user)
      .order(:occurred_at)
  end

  def new
    @organisation = Organisation.new
  end

  def create
    @organisation = Organisation.new(organisation_create_params)
    if @organisation.save
      redirect_to organisation_path(@organisation), notice: 'Organisation created successfully.'
    else
      flash.now[:alert] = @organisation.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
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

  def organisation_create_params
    params.require(:organisation).permit(
      :name,
      :email,
      :latitude,
      :longitude,
      :allowed_radius_meters,
      :timezone,
      :work_start_time,
      :work_end_time
    )
  end
end
