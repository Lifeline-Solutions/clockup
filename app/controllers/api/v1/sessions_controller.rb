module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_api_user!, only: [:login]

      def login
        user = User.find_by(email: params[:email])
        if user&.authenticate(params[:password])
          user.generate_api_token
          user.save!
          render json: { api_token: user.api_token }, status: :ok
        else
          render json: { error: 'Invalid credentials' }, status: :unauthorized
        end
      end
    end
  end
end
