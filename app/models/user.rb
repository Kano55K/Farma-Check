# Usuario del sistema con permisos de empleado o administrador.
class User < ApplicationRecord
  has_secure_password
  has_secure_token :api_token
  has_many :sessions, dependent: :destroy
  has_many :stock_movements, dependent: :restrict_with_error

  enum :role, { employee: 0, admin: 1 }

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: true

  # Duración del token de la API (configurable con API_TOKEN_TTL_HOURS, 12 h por defecto).
  def self.api_token_ttl
    ENV.fetch("API_TOKEN_TTL_HOURS", 12).to_i.hours
  end

  # Busca al dueño de un token, sin importar si está vencido (eso lo decide quien llama).
  def self.find_by_api_token(token)
    return if token.blank?

    find_by(api_token: token)
  end

  # Genera un token nuevo con vencimiento y lo devuelve. Invalida el anterior.
  def issue_api_token!
    update!(api_token: self.class.generate_unique_secure_token, api_token_expires_at: self.class.api_token_ttl.from_now)
    api_token
  end

  # Un token sin fecha de vencimiento (emitido antes de agregar la expiración) se considera vencido.
  def api_token_expired?
    api_token_expires_at.nil? || api_token_expires_at <= Time.current
  end

  def revoke_api_token!
    update!(api_token: nil, api_token_expires_at: nil)
  end
end
