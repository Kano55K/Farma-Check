module Api
  module V1
    class StockMovementsController < BaseController
      def index
        movements = StockMovement.includes(batch: :product, user: [])
                                 .order(created_at: :desc)
                                 .limit(50)
        render json: movements.map { |m|
          {
            id: m.id,
            product: m.batch.product.name,
            lot_number: m.batch.lot_number,
            movement_type: m.movement_type,
            quantity: m.quantity,
            reason: m.reason,
            user: m.user.email_address,
            created_at: m.created_at
          }
        }
      end

      def create
        batch = Batch.find(params[:batch_id])
        movement = StockMovement.new(
          batch: batch,
          user: current_user,
          movement_type: params[:movement_type],
          quantity: params[:quantity],
          reason: params[:reason]
        )

        if movement.save
          render json: { message: "Movimiento registrado", id: movement.id }, status: :created
        else
          render json: { errors: movement.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
