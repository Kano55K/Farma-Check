# Proveedor externo que abastece a la farmacia con medicamentos o insumos.
class Supplier < ApplicationRecord
  has_many :purchase_orders, dependent: :destroy

  validates :company_name, presence: true
  validates :cuit, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end
