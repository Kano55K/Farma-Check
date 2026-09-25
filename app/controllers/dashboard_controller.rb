class DashboardController < ApplicationController
  def index
    @total_products = Product.count
    @total_stock_value = Batch.active.sum(:quantity)
    @low_stock_products = Product.joins(:batches)
                                 .where(batches: { status: 0 })
                                 .group("products.id")
                                 .having("SUM(batches.quantity) <= products.min_stock AND products.min_stock IS NOT NULL")
    @out_of_stock = Product.left_joins(:batches)
                           .group("products.id")
                           .having("COALESCE(SUM(CASE WHEN batches.status = 0 THEN batches.quantity ELSE 0 END), 0) = 0")
    @expiring_critical = Batch.active.where(expiration_date: ..30.days.from_now).includes(:product)
    @expiring_warning  = Batch.active.where(expiration_date: 30.days.from_now..90.days.from_now).includes(:product)
    @recent_movements  = StockMovement.includes(batch: :product, user: []).order(created_at: :desc).limit(5)
  end
end
