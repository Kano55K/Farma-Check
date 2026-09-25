require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "es válido con atributos correctos" do
    user = User.new(email_address: "test@farma.com", password: "password123", role: :employee)
    assert user.valid?
  end

  test "no es válido sin email" do
    user = User.new(password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "no permite emails duplicados" do
    User.create!(email_address: "test@farma.com", password: "password123")
    user = User.new(email_address: "test@farma.com", password: "otropassword")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "normaliza el email a minúsculas" do
    user = User.create!(email_address: "ADMIN@FARMA.COM", password: "password123")
    assert_equal "admin@farma.com", user.email_address
  end

  test "admin? retorna true para rol admin" do
    user = User.new(email_address: "admin@farma.com", password: "password123", role: :admin)
    assert user.admin?
  end

  test "admin? retorna false para rol employee" do
    user = User.new(email_address: "emp@farma.com", password: "password123", role: :employee)
    assert_not user.admin?
  end
end
