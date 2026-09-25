class PurchaseOrdersController < ApplicationController
  before_action :set_purchase_order, only: %i[show edit update destroy]

  def index
    @purchase_orders = PurchaseOrder.includes(:supplier, :purchase_order_items)
                                    .order(created_at: :desc)
  end

  def show
    @items = @purchase_order.purchase_order_items.includes(:product)
  end

  def new
    @purchase_order = PurchaseOrder.new
    @purchase_order.purchase_order_items.build
    @suppliers = Supplier.order(:company_name)
    @products = Product.order(:name)
  end

  def edit
    @suppliers = Supplier.order(:company_name)
    @products = Product.order(:name)
  end

  def create
    @purchase_order = PurchaseOrder.new(purchase_order_params)
    @suppliers = Supplier.order(:company_name)
    @products = Product.order(:name)
    if @purchase_order.save
      redirect_to @purchase_order, notice: "Orden de compra creada correctamente."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @suppliers = Supplier.order(:company_name)
    @products = Product.order(:name)
    if @purchase_order.update(purchase_order_params)
      redirect_to @purchase_order, notice: "Orden actualizada correctamente."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @purchase_order.destroy!
    redirect_to purchase_orders_path, notice: "Orden eliminada.", status: :see_other
  end

  private

  def set_purchase_order
    @purchase_order = PurchaseOrder.find(params[:id])
  end

  def purchase_order_params
    params.require(:purchase_order).permit(
      :supplier_id, :status, :notes,
      purchase_order_items_attributes: [ :id, :product_id, :quantity, :unit_price, :_destroy ]
    )
  end
end
