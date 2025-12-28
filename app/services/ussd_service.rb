class UssdService
  MENU = {
    initial: "Welcome to ClockUp\n1. Clock In\n2. Clock Out\n3. View Status\n4. Exit",
    invalid: 'Invalid option. Please try again.'
  }.freeze

  def initialize(phone_number, text, session_id)
    @phone_number = normalize_phone(phone_number)
    @text = text.to_s.strip
    @session_id = session_id
    @user = User.find_by(phone_number: @phone_number)
  end

  def process
    return end_response('User not found. Please register first.') unless @user

    case @text
    when ''
      continue_response(MENU[:initial])
    when '1'
      handle_clock_in
    when '2'
      handle_clock_out
    when '3'
      handle_view_status
    when '4'
      end_response('Thank you for using ClockUp. Goodbye!')
    else
      continue_response("#{MENU[:invalid]}\n\n#{MENU[:initial]}")
    end
  end

  private

  def handle_clock_in
    if @user.clocked_in?
      end_response('You are already clocked in.')
    elsif create_clock_in
      end_response("✓ Clock In successful at #{Time.current.strftime('%H:%M')}")
    else
      end_response('✗ Clock In failed. Please try again.')
    end
  end

  def handle_clock_out
    if !@user.clocked_in?
      end_response('You are not clocked in.')
    elsif update_clock_out
      end_response("✓ Clock Out successful at #{Time.current.strftime('%H:%M')}")
    else
      end_response('✗ Clock Out failed. Please try again.')
    end
  end

  def handle_view_status
    if @user.clocked_in?
      latest = @user.latest_clock_event_for
      clock_in_time = begin
        latest.occurred_at.strftime('%H:%M')
      rescue StandardError
        'N/A'
      end
      status = "Status: Clocked In\nTime: #{clock_in_time}"
    else
      status = 'Status: Clocked Out'
    end

    end_response(status)
  end

  def create_clock_in
    ClockEvent.create(
      user: @user,
      organisation: @user.organisation,
      event_type: :clock_in,
      occurred_at: Time.current
    ).persisted?
  end

  def update_clock_out
    latest = @user.latest_clock_event_for
    return false unless latest&.clock_in?

    ClockEvent.create(
      user: @user,
      organisation: @user.organisation,
      event_type: :clock_out,
      occurred_at: Time.current
    ).persisted?
  end

  def normalize_phone(phone)
    phone = phone.gsub(/\D/, '')
    phone.start_with?('+') ? phone : "+#{phone}"
  end

  def continue_response(text)
    "CON #{text}"
  end

  def end_response(text)
    "END #{text}"
  end
end
