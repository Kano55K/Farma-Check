# Contexto global del request actual para acceder a la sesión activa en cualquier lugar.
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true
end
