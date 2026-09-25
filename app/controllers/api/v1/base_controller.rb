module Api
  module V1
    class BaseController < ApplicationController
      skip_before_action :require_authentication
      skip_before_action :verify_authenticity_token
      before_action :authenticate_api_user!

      private

      def authenticate_api_user!
        token = request.headers["Authorization"]&.split(" ")&.last
        return render_unauthorized unless token

        @current_user = User.find_by(api_token: token)
        render_unauthorized unless @current_user
      end

      def render_unauthorized
        render json: { error: "No autorizado" }, status: :unauthorized
      end

      def current_user
        @current_user
      end
    end
  end
end
