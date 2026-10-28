# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  def welcome
    UserMailer.welcome(User.first || User.new(email_address: "demo@farma-check.com", role: :employee))
  end
end
