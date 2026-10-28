# Representa un medicamento del catálogo y calcula su disponibilidad real en stock.
class Product < ApplicationRecord
  STOCK_STATUSES = %w[sin_stock stock_bajo ok].freeze
  ACTIVE_STOCK_SQL = "COALESCE(SUM(CASE WHEN batches.status = 0 THEN batches.quantity ELSE 0 END), 0)".freeze

  has_many :batches, dependent: :destroy
  has_many :purchase_order_items, dependent: :destroy
  has_one_attached :image

  validates :name, presence: true
  validates :barcode, uniqueness: true, allow_blank: true

  scope :low_stock, -> {
    joins(:batches)
      .where(batches: { status: :active })
      .group("products.id")
      .having("SUM(batches.quantity) <= products.min_stock")
  }

  # Agrega la columna calculada `active_stock` (stock de lotes activos) en una sola consulta.
  scope :with_active_stock, -> {
    left_joins(:batches).group("products.id").select("products.*, #{ACTIVE_STOCK_SQL} AS active_stock")
  }

  # Requiere with_active_stock. Filtra por el mismo criterio que #stock_status.
  scope :by_stock_status, ->(status) {
    case status.to_s
    when "sin_stock"
      having("#{ACTIVE_STOCK_SQL} = 0")
    when "stock_bajo"
      having("#{ACTIVE_STOCK_SQL} > 0 AND products.min_stock IS NOT NULL AND #{ACTIVE_STOCK_SQL} <= products.min_stock")
    when "ok"
      having("#{ACTIVE_STOCK_SQL} > 0 AND (products.min_stock IS NULL OR #{ACTIVE_STOCK_SQL} > products.min_stock)")
    else
      all
    end
  }

  # Suma la cantidad disponible de los lotes activos del producto.
  # Si el registro vino de with_active_stock, usa el valor ya calculado (evita N+1).
  def total_stock
    return self[:active_stock].to_i if has_attribute?(:active_stock)

    batches.active.sum(:quantity)
  end

  # Devuelve el estado del medicamento para mostrar alertas de inventario.
  def stock_status
    stock = total_stock
    return :sin_stock if stock == 0
    return :stock_bajo if min_stock.present? && stock <= min_stock
    :ok
  end
end
