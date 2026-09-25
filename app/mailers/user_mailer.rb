class UserMailer < ApplicationMailer
  def welcome(user)
    @user = user
    mail(to: @user.email_address, subject: "Bienvenido a Farma-Check")
  end
end
