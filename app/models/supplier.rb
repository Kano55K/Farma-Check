# Proveedor externo que abastece a la farmacia con medicamentos o insumos.
class Supplier < ApplicationRecord
  CUIT_FORMAT = /\A\d{2}-\d{8}-\d\z/
  CUIT_WEIGHTS = [ 5, 4, 3, 2, 7, 6, 5, 4, 3, 2 ].freeze

  has_many :purchase_orders, dependent: :restrict_with_error

  validates :company_name, presence: true
  validates :cuit, presence: true, uniqueness: true
  validates :cuit, format: { with: CUIT_FORMAT, message: "debe tener el formato XX-XXXXXXXX-X" }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validate :cuit_check_digit

  # Calcula el dígito verificador de un CUIT a partir de sus 10 primeros dígitos (nil si no existe).
  def self.cuit_check_digit(first_ten_digits)
    sum = first_ten_digits.chars.map(&:to_i).zip(CUIT_WEIGHTS).sum { |digit, weight| digit * weight }
    result = 11 - (sum % 11)
    return 0 if result == 11

    result == 10 ? nil : result
  end

  private

  def cuit_check_digit
    return unless cuit.to_s.match?(CUIT_FORMAT)

    digits = cuit.delete("-")
    return if self.class.cuit_check_digit(digits[0, 10]) == digits[10].to_i

    errors.add(:cuit, "tiene un dígito verificador inválido")
  end
end
