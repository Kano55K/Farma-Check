# Orden de compra emitida a un proveedor para abastecer medicamentos o insumos.
#
# Ciclo de vida: pending → sent → received, y pending/sent → cancelled.
class PurchaseOrder < ApplicationRecord
  # Se lanza cuando se pide una transición de estado que no corresponde.
  class InvalidTransition < StandardError; end

  belongs_to :supplier
  has_many :purchase_order_items, dependent: :destroy
  has_many :products, through: :purchase_order_items

  accepts_nested_attributes_for :purchase_order_items, reject_if: :all_blank, allow_destroy: true

  enum :status, { pending: 0, sent: 1, received: 2, cancelled: 3 }

  validates :supplier, presence: true
  validate :must_have_items

  before_validation :compute_total_amount

  # El total siempre se calcula en el servidor a partir de los ítems.
  def compute_total_amount
    self.total_amount = purchase_order_items.reject(&:marked_for_destruction?).sum(&:subtotal)
  end

  def send_order!
    transition!(from: %w[pending], to: :sent)
  end

  def cancel!
    transition!(from: %w[pending sent], to: :cancelled)
  end

  # Recibe la mercadería: por cada ítem crea (o reutiliza) el lote y registra una entrada de stock.
  # `items_data` es una lista de hashes con :id (del ítem), :lot_number, :expiration_date y :location.
  def receive!(items_data, user)
    raise InvalidTransition, transition_message(:received) unless sent?

    data_by_item = Array(items_data).index_by { |d| d[:id].to_i }
    validate_reception!(data_by_item)

    transaction do
      purchase_order_items.includes(:product).find_each do |item|
        data = data_by_item.fetch(item.id)
        batch = item.product.batches.find_or_initialize_by(lot_number: data[:lot_number].to_s.strip)
        batch.assign_attributes(expiration_date: data[:expiration_date], location: data[:location].presence || batch.location)
        batch.quantity ||= 0
        batch.status ||= :active
        batch.save!
        StockMovement.create!(batch: batch, user: user, movement_type: :entrada, quantity: item.quantity,
                              reason: "Recepción de orden de compra ##{id}")
      end
      update!(status: :received)
    end
    self
  end

  private

  def must_have_items
    return if purchase_order_items.reject(&:marked_for_destruction?).any?

    errors.add(:purchase_order_items, "debe tener al menos un ítem")
  end

  def transition!(from:, to:)
    raise InvalidTransition, transition_message(to) unless from.include?(status)

    update!(status: to)
    self
  end

  def transition_message(to)
    "No se puede pasar la orden de \"#{status}\" a \"#{to}\""
  end

  # Junta todos los errores de los datos de recepción antes de tocar la base.
  def validate_reception!(data_by_item)
    purchase_order_items.each_with_index do |item, index|
      data = data_by_item[item.id]
      prefix = "items[#{index}]"
      if data.nil?
        errors.add(:"#{prefix}", "faltan los datos de recepción del ítem #{item.id}")
        next
      end
      errors.add(:"#{prefix}.lot_number", "es obligatorio") if data[:lot_number].blank?
      date = parse_date(data[:expiration_date])
      if date.nil?
        errors.add(:"#{prefix}.expiration_date", "es obligatoria y debe tener formato AAAA-MM-DD")
      elsif date <= Date.current
        errors.add(:"#{prefix}.expiration_date", "debe ser posterior a hoy")
      end
    end
    raise ActiveRecord::RecordInvalid, self if errors.any?
  end

  def parse_date(value)
    return value if value.is_a?(Date)

    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end
end
