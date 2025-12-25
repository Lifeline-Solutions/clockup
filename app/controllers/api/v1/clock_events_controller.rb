module Api
  module V1
    class ClockEventsController < BaseController
      def create
        org = Organisation.find(params[:organisation_id])
        lat = params[:latitude]
        lon = params[:longitude]
        type = params[:event_type]&.to_sym

        clock_event = ClockEventService.call(
          user: current_user,
          organisation: org,
          latitude: lat,
          longitude: lon,
          event_type: type
        )

        render json: {
          message: "#{clock_event.event_type.humanize} successful",
          distance: clock_event.distance_from_org_meters,
          occurred_at: clock_event.occurred_at
        }, status: :created
      rescue ClockEventService::OutsideGeofenceError, ClockEventService::DuplicateEventError => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end
    end
  end
end
