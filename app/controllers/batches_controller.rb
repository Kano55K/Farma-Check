class BatchesController < ApplicationController
  before_action :set_batch, only: %i[show edit update destroy]

def index
  @batches = Batch.includes(:product).order(expiration_date: :asc)

  @batches = case params[:status]
  when "critical"
               @batches.active.where(expiration_date: ..30.days.from_now)
  when "warning"
               @batches.active.where(expiration_date: 30.days.from_now..90.days.from_now)
  when "expired"
               @batches.where(status: :expired)
                 .or(@batches.active.where("expiration_date < ?", Date.today))
  else
               @batches
  end
end

  def show
  end

  def new
    @batch = Batch.new
    @batch.product_id = params[:product_id] if params[:product_id]
    @products = Product.order(:name)
  end

  def edit
    @products = Product.order(:name)
  end

  def create
    @batch = Batch.new(batch_params)
    @products = Product.order(:name)
    if @batch.save
      redirect_to @batch.product, notice: "Lote ingresado correctamente."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @products = Product.order(:name)
    if @batch.update(batch_params)
      redirect_to @batch.product, notice: "Lote actualizado correctamente."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    product = @batch.product
    @batch.destroy!
    redirect_to product, notice: "Lote eliminado.", status: :see_other
  end

  private

  def set_batch
    @batch = Batch.find(params[:id])
  end

  def batch_params
    params.require(:batch).permit(:product_id, :lot_number, :expiration_date, :quantity, :status, :location)
  end
end
