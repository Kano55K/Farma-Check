class StockMovementsController < ApplicationController
  before_action :set_batch, only: [ :new, :create ]

  def index
    @stock_movements = StockMovement.includes(batch: :product, user: [])
                                    .order(created_at: :desc)
  end

  def new
    @stock_movement = @batch.stock_movements.new
  end

  def create
    @stock_movement = @batch.stock_movements.new(stock_movement_params)
    # Temporalmente asignamos el primer usuario hasta conectar la autenticación completa
    @stock_movement.user = User.first || User.create!(email_address: "admin@farmacia.com", password: "password123", role: :admin)

    if @stock_movement.save
      redirect_to root_path, notice: "Movimiento de stock registrado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_batch
    @batch = Batch.find(params[:batch_id])
  end

  def stock_movement_params
    params.require(:stock_movement).permit(:movement_type, :quantity, :reason)
  end
end
