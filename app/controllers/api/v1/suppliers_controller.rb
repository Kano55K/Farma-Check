module Api
  module V1
    class SuppliersController < BaseController
      before_action :require_admin!, only: %i[create update]

      # GET /api/v1/suppliers — búsqueda por razón social o CUIT.
      def index
        suppliers = Supplier.order(:company_name, :id)
        if params[:search].present?
          term = "%#{Supplier.sanitize_sql_like(params[:search].to_s.strip)}%"
          suppliers = suppliers.where("company_name LIKE :term OR cuit LIKE :term", term: term)
        end

        records, meta = paginate(suppliers)
        render json: { data: SupplierSerializer.render(records), meta: meta }
      end

      # GET /api/v1/suppliers/:id — incluye las últimas órdenes de compra.
      def show
        supplier = Supplier.find(params[:id])
        orders = supplier.purchase_orders.includes(:supplier, :purchase_order_items).order(created_at: :desc).limit(10)
        render json: { data: SupplierSerializer.render(supplier).merge(recent_purchase_orders: PurchaseOrderSerializer.render(orders)) }
      end

      # POST /api/v1/suppliers (solo admin)
      def create
        supplier = Supplier.create!(supplier_params)
        render json: { message: "Proveedor creado", data: SupplierSerializer.render(supplier) }, status: :created
      end

      # PATCH /api/v1/suppliers/:id (solo admin)
      def update
        supplier = Supplier.find(params[:id])
        supplier.update!(supplier_params)
        render json: { message: "Proveedor actualizado", data: SupplierSerializer.render(supplier) }
      end

      private

      def supplier_params
        params.require(:supplier).permit(:company_name, :cuit, :email, :phone, :contact_name)
      end
    end
  end
end
