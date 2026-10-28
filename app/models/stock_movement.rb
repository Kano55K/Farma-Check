# Registra cada movimiento de inventario: entrada, salida, ajuste o merma por vencimiento.
#
# La validación y la actualización del stock del lote corren dentro de la misma transacción
# que abre `save`, así que si algo falla no queda ni el movimiento ni el cambio de stock.
class StockMovement < ApplicationRecord
  OUTGOING_TYPES = %w[salida devaluacion_vencimiento].freeze

  belongs_to :batch
  belongs_to :user

  # validate: true hace que un valor fuera del enum sea un error de validación (422) y no un ArgumentError.
  enum :movement_type, { entrada: 0, salida: 1, ajuste: 2, devaluacion_vencimiento: 3 },
       validate: { message: "no es válido (valores admitidos: entrada, salida, ajuste, devaluacion_vencimiento)" }

  validates :movement_type, presence: { message: "es obligatorio" }
  validates :quantity, presence: { message: "es obligatoria" }
  validates :quantity, numericality: { only_integer: true, greater_than: 0, message: "debe ser un número entero mayor que 0" },
                       allow_nil: true, unless: :ajuste?
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0, message: "debe ser un número entero mayor o igual a 0" },
                       allow_nil: true, if: :ajuste?
  validate :batch_allows_outgoing, on: :create
  validate :enough_stock, on: :create

  before_validation :reload_batch_stock, on: :create
  after_create :update_batch_quantity

  def outgoing?
    OUTGOING_TYPES.include?(movement_type)
  end

  private

  # Relee el lote dentro de la transacción para validar contra el stock vigente.
  def reload_batch_stock
    batch.lock! if batch&.persisted?
  end

  def batch_allows_outgoing
    return unless salida? && batch

    errors.add(:batch, "está vencido o retirado: no admite salidas (usá devaluacion_vencimiento)") unless batch.dispensable?
  end

  def enough_stock
    return unless outgoing? && batch && quantity.is_a?(Integer)
    return if quantity <= batch.quantity.to_i

    errors.add(:quantity, "supera el stock disponible del lote (#{batch.quantity.to_i})")
  end

  # Actualiza el stock del lote según el tipo de movimiento registrado.
  def update_batch_quantity
    case movement_type
    when "entrada"
      batch.increment!(:quantity, quantity)
    when "salida", "devaluacion_vencimiento"
      batch.decrement!(:quantity, quantity)
    when "ajuste"
      batch.update!(quantity: quantity)
    end
  end
end
