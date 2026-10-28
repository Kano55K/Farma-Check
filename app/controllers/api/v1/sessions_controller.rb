module Api
  module V1
    # Login y logout de la API con token Bearer.
    class SessionsController < BaseController
      skip_before_action :authenticate_api_user!, only: :create

      # POST /api/v1/login — acepta el cuerpo plano o anidado en "session".
      def create
        credentials = login_params
        if credentials[:email_address].blank? || credentials[:password].blank?
          details = {}
          details[:email_address] = [ "es obligatorio" ] if credentials[:email_address].blank?
          details[:password] = [ "es obligatoria" ] if credentials[:password].blank?
          return render_error("validation_failed", "Ingresá email y contraseña", :unprocessable_entity, details)
        end

        user = User.authenticate_by(email_address: credentials[:email_address], password: credentials[:password])
        return render_error("invalid_credentials", "Email o contraseña incorrectos", :unauthorized) unless user

        token = user.issue_api_token!
        render json: {
          token: token,
          token_type: "Bearer",
          expires_at: user.api_token_expires_at.utc.iso8601,
          user: UserSerializer.render(user)
        }, status: :ok
      end

      # DELETE /api/v1/logout — requiere un token válido y lo invalida.
      def destroy
        current_user.revoke_api_token!
        render json: { message: "Sesión cerrada" }, status: :ok
      end

      private

      # Toma las credenciales del cuerpo plano ({ email_address, password }) o de { session: {...} }.
      def login_params
        nested = params[:session]
        source = nested.is_a?(ActionController::Parameters) && nested[:email_address].present? ? nested : params
        source.permit(:email_address, :password)
      end
    end
  end
end
