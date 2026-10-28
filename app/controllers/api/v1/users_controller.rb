module Api
  module V1
    class UsersController < BaseController
      # GET /api/v1/profile
      def profile
        render json: UserSerializer.render(current_user).merge(token_expires_at: current_user.api_token_expires_at.utc.iso8601)
      end
    end
  end
end
