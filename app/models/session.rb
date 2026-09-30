# Sesión autenticada del usuario para mantener la sesión web y la API.
class Session < ApplicationRecord
  belongs_to :user
end
