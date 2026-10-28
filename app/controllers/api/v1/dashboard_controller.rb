module Api
  module V1
    # KPIs y alertas para la pantalla de inicio del front-end.
    class DashboardController < BaseController
      ALERTS_LIMIT = 10

      # GET /api/v1/dashboard
      def show
        render json: {
          data: {
            kpis: {
              total_products: Product.count,
              low_stock_products: Product.with_active_stock.by_stock_status("stock_bajo").to_a.size,
              out_of_stock_products: Product.with_active_stock.by_stock_status("sin_stock").to_a.size,
              expired_batches: batches_with_stock("vencido").count,
              critical_batches: batches_with_stock("critico").count,
              warning_batches: batches_with_stock("alerta").count,
              pending_purchase_orders: PurchaseOrder.where(status: %i[pending sent]).count
            },
            alerts: batch_alerts + stock_alerts
          }
        }
      end

      private

      def batches_with_stock(expiration_status)
        Batch.by_expiration_status(expiration_status).where("batches.quantity > 0")
      end

      # Lotes vencidos o críticos que todavía tienen stock, del más urgente al menos urgente.
      def batch_alerts
        batches = batches_with_stock("vencido").or(batches_with_stock("critico"))
        batches.includes(:product).order(:expiration_date).limit(ALERTS_LIMIT).map do |batch|
          expired = batch.expiration_status == :vencido
          {
            type: expired ? "batch_expired" : "batch_critical",
            severity: expired ? "danger" : "warning",
            message: "#{batch.product.name}: lote #{batch.lot_number} #{expired ? 'vencido el' : 'vence el'} #{batch.expiration_date.strftime('%d/%m/%Y')}",
            product_id: batch.product_id,
            batch_id: batch.id,
            date: batch.expiration_date.iso8601
          }
        end
      end

      # Productos sin stock primero, después los de stock bajo.
      def stock_alerts
        products = %w[sin_stock stock_bajo].flat_map do |status|
          Product.with_active_stock.by_stock_status(status).order(:name).limit(ALERTS_LIMIT).to_a
        end
        products.first(ALERTS_LIMIT).map do |product|
          out = product.stock_status == :sin_stock
          {
            type: out ? "out_of_stock" : "low_stock",
            severity: out ? "danger" : "warning",
            message: out ? "#{product.name}: sin stock" : "#{product.name}: stock bajo (#{product.total_stock} u., mínimo #{product.min_stock})",
            product_id: product.id,
            batch_id: nil,
            date: nil
          }
        end
      end
    end
  end
end
