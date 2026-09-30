module Api
  module V1
    # Base para todos los endpoints de la API. Valida el token Bearer y comparte el usuario autenticado.
    class BaseController < ApplicationController
      skip_before_action :require_authentication
      skip_before_action :verify_authenticity_token
      before_action :authenticate_api_user!

      private

      # Busca un usuario activo por el token enviado en el header Authorization.
      def authenticate_api_user!
        token = request.headers["Authorization"]&.split(" ")&.last
        return render_unauthorized unless token

        @current_user = User.find_by(api_token: token)
        render_unauthorized unless @current_user
      end

      # Responde con error 401 cuando el token no es válido o falta.
      def render_unauthorized
        render json: { error: "No autorizado" }, status: :unauthorized
      end

      def current_user
        @current_user
      end
    end
  end
end
