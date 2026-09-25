class Batch < ApplicationRecord
  belongs_to :product
  has_many :stock_movements, dependent: :destroy

  enum :status, { active: 0, expired: 1, recalled: 2 }

  validates :lot_number, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :expiration_date, presence: true

  scope :expiring_soon, -> { active.where(expiration_date: ..30.days.from_now) }
  scope :expiring_warning, -> { active.where(expiration_date: 30.days.from_now..90.days.from_now) }
  scope :not_expired, -> { active.where("expiration_date > ?", Date.today) }

  def expiration_status
    return :vencido if expired? || expiration_date < Date.today
    return :critico if expiration_date <= 30.days.from_now
    return :alerta if expiration_date <= 90.days.from_now
    :ok
  end
end
