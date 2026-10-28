module Api
  module V1
    class ProductsController < BaseController
      # GET /api/v1/products — búsqueda, filtros y paginación.
      # El stock se calcula en la misma consulta (with_active_stock) para evitar N+1.
      def index
        validate_filter!(:stock_status, Product::STOCK_STATUSES)
        validate_filter!(:prescription_required, %w[true false])

        products = Product.with_active_stock.order(:name, :id)
        if params[:search].present?
          term = "%#{Product.sanitize_sql_like(params[:search].to_s.strip)}%"
          products = products.where("products.name LIKE :term OR products.active_ingredient LIKE :term OR products.barcode LIKE :term", term: term)
        end
        products = products.where(laboratory: params[:laboratory]) if params[:laboratory].present?
        products = products.where(prescription_required: params[:prescription_required] == "true") if params[:prescription_required].present?
        products = products.by_stock_status(params[:stock_status]) if params[:stock_status].present?

        records, meta = paginate(products)
        render json: {
          data: ProductSerializer.render(records),
          meta: meta.merge(laboratories: Product.where.not(laboratory: [ nil, "" ]).distinct.order(:laboratory).pluck(:laboratory))
        }
      end

      # GET /api/v1/products/:id — incluye los lotes ordenados por vencimiento.
      def show
        product = Product.includes(:batches).find(params[:id])
        render json: { data: ProductSerializer.render(product, include_batches: true) }
      end
    end
  end
end
