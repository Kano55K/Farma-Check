require "test_helper"

class SupplierTest < ActiveSupport::TestCase
  test "es válido con atributos correctos" do
    supplier = Supplier.new(company_name: "Droguería Test", cuit: "30-12345678-9")
    assert supplier.valid?
  end

  test "no es válido sin razón social" do
    supplier = Supplier.new(cuit: "30-12345678-9")
    assert_not supplier.valid?
    assert_includes supplier.errors[:company_name], "can't be blank"
  end

  test "no es válido sin CUIT" do
    supplier = Supplier.new(company_name: "Droguería Test")
    assert_not supplier.valid?
    assert_includes supplier.errors[:cuit], "can't be blank"
  end

  test "no permite CUITs duplicados" do
    Supplier.create!(company_name: "Droguería A", cuit: "30-12345678-9")
    supplier = Supplier.new(company_name: "Droguería B", cuit: "30-12345678-9")
    assert_not supplier.valid?
    assert_includes supplier.errors[:cuit], "has already been taken"
  end

  test "no es válido con email mal formado" do
    supplier = Supplier.new(company_name: "Test", cuit: "30-99999999-9", email: "no-es-un-email")
    assert_not supplier.valid?
    assert_includes supplier.errors[:email], "is invalid"
  end
end
