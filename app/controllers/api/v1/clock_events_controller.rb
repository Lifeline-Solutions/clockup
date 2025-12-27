module Api
  module V1
    class ClockEventsController < BaseController
      def create
        organisation = Organisation.find_by!(clock_qr_token: params[:qr_token])

        return render json: { error: 'Organisation is deactivated' }, status: :forbidden unless organisation.active?

        clock_event = ClockEventService.call(
          user: current_user,
          organisation: organisation,
          latitude: params[:latitude],
          longitude: params[:longitude]
          # event_type intentionally omitted → auto decision
        )

        render json: {
          message: "#{clock_event.event_type.humanize} successful",
          event_type: clock_event.event_type,
          distance: clock_event.distance_from_org_meters,
          occurred_at: clock_event.occurred_at,
          late: (clock_event.respond_to?(:late?) ? clock_event.late? : false),
          early_leave: (clock_event.respond_to?(:early_leave?) ? clock_event.early_leave? : false)
        }, status: :created
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Invalid QR code' }, status: :not_found
      rescue ClockEventService::OutsideGeofenceError,
             ClockEventService::DuplicateEventError => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.join(', ') },
               status: :unprocessable_entity
      end
    end
  end
end
