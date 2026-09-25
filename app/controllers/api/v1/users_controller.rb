module Api
  module V1
    class UsersController < BaseController
      def profile
        render json: {
          id: current_user.id,
          email: current_user.email_address,
          role: current_user.role
        }
      end
    end
  end
end
