# Maneja la autenticación web: valida la sesión, protege rutas y gestiona login/logout.
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

    # Devuelve true si existe una sesión válida para el usuario actual.
    def authenticated?
      resume_session
    end

    # Requiere una sesión activa; de lo contrario, redirige al login.
    def require_authentication
      resume_session || request_authentication
    end

    # Recupera la sesión del usuario desde la cookie firmada del navegador.
    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    # Guarda la URL original para volver luego de autenticarse.
    def request_authentication
      cookies[:return_to_after_authenticating] = {
        value: request.original_url,
        httponly: true,
        same_site: :lax
      }
      redirect_to new_session_path
    end

    # Retorna la ruta que se intentó visitar antes del login.
    def after_authentication_url
      cookies.delete(:return_to_after_authenticating) || root_url
    end

    # Crea una nueva sesión persistente para el usuario autenticado.
    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    # Elimina la sesión actual y la cookie del navegador.
    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
