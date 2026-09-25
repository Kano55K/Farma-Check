module Api
  module V1
    class ProductsController < BaseController
      def index
        products = Product.all
        products = products.where("name LIKE ? OR active_ingredient LIKE ?",
                                  "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
        products = products.where(laboratory: params[:laboratory]) if params[:laboratory].present?

        render json: products.map { |p|
          {
            id: p.id,
            name: p.name,
            active_ingredient: p.active_ingredient,
            laboratory: p.laboratory,
            presentation: p.presentation,
            barcode: p.barcode,
            therapeutic_action: p.therapeutic_action,
            gondola_location: p.gondola_location,
            min_stock: p.min_stock,
            safety_stock: p.safety_stock,
            prescription_required: p.prescription_required,
            total_stock: p.batches.active.sum(:quantity),
            stock_status: p.stock_status
          }
        }
      end

      def show
        product = Product.find(params[:id])
        render json: {
          id: product.id,
          name: product.name,
          active_ingredient: product.active_ingredient,
          laboratory: product.laboratory,
          presentation: product.presentation,
          barcode: product.barcode,
          therapeutic_action: product.therapeutic_action,
          gondola_location: product.gondola_location,
          min_stock: product.min_stock,
          safety_stock: product.safety_stock,
          prescription_required: product.prescription_required,
          total_stock: product.batches.active.sum(:quantity),
          stock_status: product.stock_status,
          batches: product.batches.map { |b|
            {
              id: b.id,
              lot_number: b.lot_number,
              expiration_date: b.expiration_date,
              quantity: b.quantity,
              status: b.status,
              location: b.location,
              expiration_status: b.expiration_status
            }
          }
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Producto no encontrado" }, status: :not_found
      end
    end
  end
end
