# Un lote pertenece a un producto y concentra la cantidad, vencimiento y estado del stock.
class Batch < ApplicationRecord
  CRITICAL_DAYS = 30
  WARNING_DAYS = 90
  EXPIRATION_STATUSES = %w[vencido critico alerta ok].freeze

  belongs_to :product
  has_many :stock_movements, dependent: :destroy

  enum :status, { active: 0, expired: 1, recalled: 2 }

  validates :lot_number, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :expiration_date, presence: true

  scope :expiring_soon, -> { active.where(expiration_date: ..CRITICAL_DAYS.days.from_now) }
  scope :expiring_warning, -> { active.where(expiration_date: CRITICAL_DAYS.days.from_now..WARNING_DAYS.days.from_now) }
  scope :not_expired, -> { active.where("expiration_date > ?", Date.today) }

  # Filtra con el mismo criterio que #expiration_status, pero en SQL.
  scope :by_expiration_status, ->(status) {
    today = Date.current
    case status.to_s
    when "vencido"
      where(status: :expired).or(where(expiration_date: ...today))
    when "critico"
      where.not(status: :expired).where(expiration_date: today..(today + CRITICAL_DAYS))
    when "alerta"
      where.not(status: :expired).where(expiration_date: (today + CRITICAL_DAYS + 1)..(today + WARNING_DAYS))
    when "ok"
      where.not(status: :expired).where(expiration_date: (today + WARNING_DAYS + 1)..)
    else
      all
    end
  }

  # Evalúa si el lote está vencido, próximo a vencer o dentro de rango normal.
  def expiration_status
    today = Date.current
    return :vencido if expired? || expiration_date < today
    return :critico if expiration_date <= today + CRITICAL_DAYS
    return :alerta if expiration_date <= today + WARNING_DAYS
    :ok
  end

  # Solo se puede dispensar (registrar salidas) de un lote activo y no vencido.
  def dispensable?
    active? && expiration_date.present? && expiration_date >= Date.current
  end
end
