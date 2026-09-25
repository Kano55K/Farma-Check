class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy]
  before_action :require_admin!, only: %i[destroy]

  def index
    @products = Product.all

    @products = @products.where("products.name ILIKE ? OR products.active_ingredient ILIKE ? OR products.barcode ILIKE ?",
                                "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    @products = @products.where(laboratory: params[:laboratory]) if params[:laboratory].present?
    @products = @products.where(therapeutic_action: params[:therapeutic_action]) if params[:therapeutic_action].present?

    @products = case params[:filter]
    when "low_stock"
                  @products.joins(:batches).where(batches: { status: 0 })
                           .group("products.id")
                           .having("SUM(batches.quantity) <= products.min_stock AND products.min_stock IS NOT NULL")
    when "expiring"
                  @products.joins(:batches)
                           .where(batches: { status: 0, expiration_date: ..30.days.from_now })
                           .group("products.id")
    when "out_of_stock"
                  @products.left_joins(:batches)
                           .group("products.id")
                           .having("COALESCE(SUM(CASE WHEN batches.status = 0 THEN batches.quantity ELSE 0 END), 0) = 0")
    else
                  @products
    end

    @laboratories = Product.distinct.pluck(:laboratory).compact.sort
    @therapeutic_actions = Product.distinct.pluck(:therapeutic_action).compact.sort
  end

  def show
    @batches = @product.batches.order(expiration_date: :asc)
  end

  def new
    @product = Product.new
  end

  def edit
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to @product, notice: "Medicamento creado correctamente."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Medicamento actualizado correctamente."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @product.destroy!
    redirect_to products_path, notice: "Medicamento eliminado.", status: :see_other
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def require_admin!
    unless Current.session.user.admin?
      redirect_to products_path, alert: "No tenés permisos para realizar esta acción."
    end
  end

  def product_params
    params.require(:product).permit(
      :name, :active_ingredient, :code, :barcode,
      :laboratory, :presentation, :therapeutic_action,
      :gondola_location, :min_stock, :safety_stock,
      :prescription_required, :image
    )
  end
end
