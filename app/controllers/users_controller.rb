class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!, only: %i[new create]

  def new
    @organisation = Organisation.find(params[:organisation_id])
    @user = User.new(organisation: @organisation)
  end

  def create
    @organisation = Organisation.find(user_create_params[:organisation_id])
    @user = User.new(user_create_params.except(:role))
    temp_password = nil
    if @user.password.blank?
      temp_password = SecureRandom.urlsafe_base64(12)
      @user.password = temp_password
    end
    if @user.save
      role = params.dig(:user, :role)
      if role.present?
        case role
        when 'admin_global'
          @user.add_role(:admin)
        when 'admin_org'
          @user.add_role(:admin, @organisation)
        end
      end
      # Send invitation email (logged in development)
      UserMailer.invite_user(@user, temp_password: temp_password).deliver_now
      notice = 'User created successfully.'
      notice += " Temporary password: #{temp_password}" if temp_password
      redirect_to organisation_path(@organisation), notice: notice
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

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

  private

  def require_admin!
    # Allow global admins or org admins for the target organisation
    org_id = params[:organisation_id] || params.dig(:user, :organisation_id)
    org = Organisation.find_by(id: org_id)
    allowed = current_user&.has_role?(:admin) || (org && current_user&.has_role?(:admin, org))
    return if allowed

    redirect_to root_path, alert: 'You are not authorized to manage users.'
  end

  def user_create_params
    params.require(:user).permit(:email, :password, :first_name, :last_name, :organisation_id, :role)
  end
end
