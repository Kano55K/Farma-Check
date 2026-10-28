# Línea de una orden de compra; vincula un producto con cantidad y precio unitario.
class PurchaseOrderItem < ApplicationRecord
  belongs_to :purchase_order
  belongs_to :product

  validates :quantity, numericality: { only_integer: true, greater_than: 0, message: "debe ser un número entero mayor que 0" }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0, message: "debe ser mayor o igual a 0" }, allow_nil: true

  def subtotal
    quantity.to_i * unit_price.to_d
  end
end
