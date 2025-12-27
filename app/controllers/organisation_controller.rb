class OrganisationController < ApplicationController
  before_action :set_organisation, only: %i[show edit update]
  before_action :require_admin!, only: %i[new create edit update]

  def index
    base_scope = Organisation.includes(:users)

    # Pagination
    @per_page = 20
    @page = (params[:page] || 1).to_i
    @page = 1 if @page < 1
    @total_count = base_scope.count
    @total_pages = (@total_count / @per_page.to_f).ceil
    @page = if @total_pages.zero?
              1
            else
              [[@page, 1].max, @total_pages].min
            end
    @start_count = @total_count.zero? ? 0 : ((@page - 1) * @per_page) + 1
    @end_count = [@page * @per_page, @total_count].min

    @organisations = base_scope
      .offset((@page - 1) * @per_page)
      .limit(@per_page)

    # Build presence summaries per displayed organisation
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

    # Users in organisation pagination (separate from events pagination)
    @users_per_page = 10
    @users_page = (params[:users_page] || 1).to_i
    @users_page = 1 if @users_page < 1
    @users_total_count = @organisation.users.count
    @users_total_pages = (@users_total_count / @users_per_page.to_f).ceil
    @users_page = if @users_total_pages.zero?
                    1
                  else
                    [[@users_page, 1].max, @users_total_pages].min
                  end
    @users_start_count = @users_total_count.zero? ? 0 : ((@users_page - 1) * @users_per_page) + 1
    @users_end_count = [@users_page * @users_per_page, @users_total_count].min

    @users = @organisation.users
      .order(:id)
      .offset((@users_page - 1) * @users_per_page)
      .limit(@users_per_page)

    # Determine filter range
    period = params[:period].presence || 'today'
    now = Time.zone.now
    default_range = now.beginning_of_day..now.end_of_day
    m = params[:month].to_i
    y = params[:year].to_i
    valid_month = m.between?(1, 12) && y.positive?
    range = case period
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
              if valid_month
                start = Time.zone.local(y, m, 1).beginning_of_day
                finish = start.end_of_month.end_of_day
                start..finish
              end
            else
              default_range
            end
    range ||= default_range

    @period_label = case period
                    when 'yesterday' then 'Yesterday'
                    when 'this_week' then 'This Week'
                    when 'last_week' then 'Last Week'
                    when 'last_month' then 'Last Month'
                    when 'month' then (valid_month ? Date::MONTHNAMES[m] + " #{y}" : 'Selected Month')
                    else 'Today'
                    end

    # Build events scope
    events_scope = ClockEvent
      .where(organisation_id: @organisation.id, occurred_at: range)
      .includes(:user)
      .order(:occurred_at)

    # Pagination
    @per_page = 15
    @page = params[:page].to_i
    @page = 1 if @page < 1
    @total_count = ClockEvent.where(organisation_id: @organisation.id, occurred_at: range).count
    @total_pages = (@total_count / @per_page.to_f).ceil
    @page = if @total_pages.zero?
              1
            else
              [[@page, 1].max, @total_pages].min
            end
    @start_count = @total_count.zero? ? 0 : ((@page - 1) * @per_page) + 1
    @end_count = [@page * @per_page, @total_count].min

    @events = events_scope
      .offset((@page - 1) * @per_page)
      .limit(@per_page)
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
