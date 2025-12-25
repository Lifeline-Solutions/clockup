module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_user!

      private

      def authenticate_api_user!
        header = request.headers['Authorization']
        token = header&.match(/^Bearer (.+)$/)&.captures&.first

        @current_user = User.find_by(api_token: token)

        render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
      end

      attr_reader :current_user
    end
  end
end
