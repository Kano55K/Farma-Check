module Api
  module V1
    class PurchaseOrdersController < BaseController
      before_action :require_admin!, only: :cancel
      before_action :set_purchase_order, only: %i[show send_order cancel receive]

      # GET /api/v1/purchase_orders — filtros por estado y proveedor.
      def index
        validate_filter!(:status, PurchaseOrder.statuses.keys)

        orders = PurchaseOrder.includes(:supplier, :purchase_order_items).order(created_at: :desc, id: :desc)
        orders = orders.where(status: params[:status]) if params[:status].present?
        orders = orders.where(supplier_id: params[:supplier_id]) if params[:supplier_id].present?

        records, meta = paginate(orders)
        render json: { data: PurchaseOrderSerializer.render(records), meta: meta }
      end

      # GET /api/v1/purchase_orders/:id — incluye los ítems.
      def show
        render_order(@purchase_order)
      end

      # POST /api/v1/purchase_orders — el total se calcula en el servidor.
      def create
        attrs = params.require(:purchase_order).permit(:supplier_id, :notes, items: %i[product_id quantity unit_price])
        order = PurchaseOrder.new(supplier_id: attrs[:supplier_id], notes: attrs[:notes], status: :pending)
        Array(attrs[:items]).each { |item| order.purchase_order_items.build(item) }
        order.save!

        render_order(order, status: :created, message: "Orden de compra creada")
      end

      # PATCH /api/v1/purchase_orders/:id/send — pending → sent.
      def send_order
        @purchase_order.send_order!
        render_order(@purchase_order, message: "Orden enviada al proveedor")
      end

      # PATCH /api/v1/purchase_orders/:id/cancel — pending/sent → cancelled (solo admin).
      def cancel
        @purchase_order.cancel!
        render_order(@purchase_order, message: "Orden cancelada")
      end

      # POST /api/v1/purchase_orders/:id/receive — crea lotes y entradas de stock; sent → received.
      def receive
        items = params.require(:purchase_order).permit(items: %i[id lot_number expiration_date location])[:items]
        @purchase_order.receive!(Array(items).map { |item| item.to_h.symbolize_keys }, current_user)

        render_order(@purchase_order.reload, message: "Orden recibida: se cargaron los lotes y el stock")
      end

      private

      def set_purchase_order
        @purchase_order = PurchaseOrder.includes(:supplier, purchase_order_items: :product).find(params[:id])
      end

      def render_order(order, status: :ok, message: nil)
        body = { data: PurchaseOrderSerializer.render(order, include_items: true) }
        body = { message: message }.merge(body) if message
        render json: body, status: status
      end
    end
  end
end
