module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :require_authentication
      skip_before_action :verify_authenticity_token

      def create
        user = User.authenticate_by(
          email_address: params[:email_address],
          password: params[:password]
        )

        if user
          token = user.regenerate_api_token
          render json: {
            token: token,
            user: {
              id: user.id,
              email: user.email_address,
              role: user.role
            }
          }, status: :ok
        else
          render json: { error: "Credenciales incorrectas" }, status: :unauthorized
        end
      end

      def destroy
        token = request.headers["Authorization"]&.split(" ")&.last
        user = User.find_by(api_token: token)
        user&.update(api_token: nil)
        render json: { message: "Sesión cerrada" }, status: :ok
      end
    end
  end
end
