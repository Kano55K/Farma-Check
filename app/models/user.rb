# Usuario del sistema con permisos de empleado o administrador.
class User < ApplicationRecord
  has_secure_password
  has_secure_token :api_token
  has_many :sessions, dependent: :destroy

  enum :role, { employee: 0, admin: 1 }

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: true

  # Indica si el usuario tiene permisos de gestión del back-office.
  def admin?
    role == "admin"
  end
end
