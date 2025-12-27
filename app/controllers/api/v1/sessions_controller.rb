module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_api_user!, only: [:login]

      def login
        user = User.find_by(email: params[:email])
        if user&.valid_password?(params[:password])
          user.regenerate_api_token!
          render json: { api_token: user.api_token }, status: :ok
        else
          render json: { error: 'Invalid credentials' }, status: :unauthorized
        end
      end

      def logout
        current_user.clear_api_token!
        render json: { message: 'Logged out' }, status: :ok
      end
    end
  end
end
