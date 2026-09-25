class SuppliersController < ApplicationController
  before_action :set_supplier, only: %i[show edit update destroy]
  before_action :require_admin!, only: %i[destroy]

  def index
    @suppliers = Supplier.order(:company_name)
  end

  def show
    @purchase_orders = @supplier.purchase_orders.order(created_at: :desc)
  end

  def new
    @supplier = Supplier.new
  end

  def edit
  end

  def create
    @supplier = Supplier.new(supplier_params)
    if @supplier.save
      redirect_to @supplier, notice: "Proveedor creado correctamente."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @supplier.update(supplier_params)
      redirect_to @supplier, notice: "Proveedor actualizado correctamente."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @supplier.destroy!
    redirect_to suppliers_path, notice: "Proveedor eliminado.", status: :see_other
  end

  private

  def set_supplier
    @supplier = Supplier.find(params[:id])
  end

  def require_admin!
    unless Current.session.user.admin?
      redirect_to suppliers_path, alert: "No tenés permisos para realizar esta acción."
    end
  end

  def supplier_params
    params.require(:supplier).permit(:company_name, :cuit, :phone, :email, :contact_name)
  end
end
