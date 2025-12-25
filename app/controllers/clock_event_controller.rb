class ClockEventsController < ApplicationController
  def create
    org = Organisation.find(params[:organisation_id])
    user = current_user
    lat = params[:latitude]
    lon = params[:longitude]

    clock_event = ClockEventService.call(
      user: user,
      organisation: org,
      latitude: lat,
      longitude: lon
    )

    flash[:notice] = "#{clock_event.event_type.humanize} successful"
    redirect_to organisation_path(org)
  rescue ClockEventService::OutsideGeofenceError => e
    flash[:alert] = e.message
    redirect_to organisation_path(org)
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = e.record.errors.full_messages.join(', ')
    redirect_to organisation_path(org)
  end
end
