class UsersController < ApplicationController
  before_action :require_admin!

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      UserMailer.welcome(@user).deliver_later
      redirect_to dashboard_path, notice: "Usuario creado. Se envió email de bienvenida."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def require_admin!
    unless Current.session.user.admin?
      redirect_to dashboard_path, alert: "No tenés permisos."
    end
  end

  def user_params
    permitted = params.require(:user).permit(:email_address, :password, :password_confirmation)
    # Solo admin puede asignar rol
    permitted[:role] = params[:user][:role] if Current.session.user.admin?
    permitted
  end
end
