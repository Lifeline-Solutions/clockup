module Api
  module V1
    class UssdController < BaseController
      skip_before_action :authenticate_request!, only: [:handle]

      def handle
        phone_number = params[:phoneNumber]
        text = params[:text] || ""
        session_id = params[:sessionId]

        unless phone_number.present?
          return render plain: "END Invalid request"
        end

        response = UssdService.new(phone_number, text, session_id).process
        render plain: response
      end
    end
  end
end