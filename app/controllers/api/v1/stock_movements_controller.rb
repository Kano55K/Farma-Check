module Api
  module V1
    class StockMovementsController < BaseController
      # GET /api/v1/stock_movements — filtros por tipo, lote, producto y rango de fechas.
      def index
        validate_filter!(:movement_type, StockMovement.movement_types.keys)
        from = date_param(:from)
        to = date_param(:to)

        movements = StockMovement.includes(:user, batch: :product).order(created_at: :desc, id: :desc)
        movements = movements.where(movement_type: params[:movement_type]) if params[:movement_type].present?
        movements = movements.where(batch_id: params[:batch_id]) if params[:batch_id].present?
        movements = movements.joins(:batch).where(batches: { product_id: params[:product_id] }) if params[:product_id].present?
        movements = movements.where(created_at: from.beginning_of_day..) if from
        movements = movements.where(created_at: ..to.end_of_day) if to

        records, meta = paginate(movements)
        render json: { data: StockMovementSerializer.render(records), meta: meta }
      end

      # POST /api/v1/stock_movements — acepta { "stock_movement": {...} } o el cuerpo plano.
      def create
        attrs = movement_params
        batch = Batch.find(attrs.require(:batch_id))
        movement = StockMovement.new(attrs.except(:batch_id).merge(batch: batch, user: current_user))
        movement.save!

        render json: { message: "Movimiento registrado", data: StockMovementSerializer.render(movement.reload) }, status: :created
      end

      private

      def movement_params
        source = params.key?(:stock_movement) ? params.require(:stock_movement) : params
        source.permit(:batch_id, :movement_type, :quantity, :reason)
      end
    end
  end
end
