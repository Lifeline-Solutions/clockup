class ClockEventsController < ApplicationController
  def create
    org = Organisation.find(params[:organisation_id])
    user = current_user
    lat = params[:latitude]
    lon = params[:longitude]
    type = params[:event_type]&.to_sym # :clock_in or :clock_out

    unless %i[clock_in clock_out].include?(type)
      flash[:alert] = 'Invalid event type'
      return redirect_to organisation_path(org)
    end

    clock_event = ClockEventService.call(
      user: user,
      organisation: org,
      latitude: lat,
      longitude: lon,
      event_type: type
    )

    flash[:notice] = "#{clock_event.event_type.humanize} successful"
    redirect_to organisation_path(org)
  rescue ClockEventService::OutsideGeofenceError, ClockEventService::DuplicateEventError => e
    flash[:alert] = e.message
    redirect_to organisation_path(org)
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = e.record.errors.full_messages.join(', ')
    redirect_to organisation_path(org)
  end
end
