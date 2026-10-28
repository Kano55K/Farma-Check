module Api
  module V1
    class BatchesController < BaseController
      SORTS = { "expiration_date" => { expiration_date: :asc }, "-expiration_date" => { expiration_date: :desc } }.freeze

      # GET /api/v1/batches — filtros por semáforo de vencimiento y producto, orden por vencimiento.
      def index
        validate_filter!(:expiration_status, Batch::EXPIRATION_STATUSES)
        validate_filter!(:sort, SORTS.keys)

        batches = Batch.includes(:product).order(SORTS.fetch(params[:sort].presence || "expiration_date")).order(:id)
        batches = batches.by_expiration_status(params[:expiration_status]) if params[:expiration_status].present?
        batches = batches.where(product_id: params[:product_id]) if params[:product_id].present?
        batches = batches.where("batches.quantity > 0") if params[:with_stock] == "true"

        records, meta = paginate(batches)
        render json: { data: BatchSerializer.render(records, include_product: true), meta: meta }
      end

      # GET /api/v1/batches/:id
      def show
        batch = Batch.includes(:product).find(params[:id])
        render json: { data: BatchSerializer.render(batch, include_product: true) }
      end
    end
  end
end
