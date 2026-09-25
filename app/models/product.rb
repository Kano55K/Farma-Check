class Product < ApplicationRecord
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

  def total_stock
    batches.active.sum(:quantity)
  end

  def stock_status
    stock = total_stock
    return :sin_stock if stock == 0
    return :stock_bajo if min_stock.present? && stock <= min_stock
    :ok
  end
end
