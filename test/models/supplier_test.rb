require "test_helper"

class SupplierTest < ActiveSupport::TestCase
  test "es válido con atributos correctos" do
    supplier = Supplier.new(company_name: "Droguería Test", cuit: "30-12345678-1")
    assert supplier.valid?
  end

  test "no es válido sin razón social" do
    supplier = Supplier.new(cuit: "30-12345678-1")
    assert_not supplier.valid?
    assert_includes supplier.errors[:company_name], "no puede estar en blanco"
  end

  test "no es válido sin CUIT" do
    supplier = Supplier.new(company_name: "Droguería Test")
    assert_not supplier.valid?
    assert_includes supplier.errors[:cuit], "no puede estar en blanco"
  end

  test "no permite CUITs duplicados" do
    Supplier.create!(company_name: "Droguería A", cuit: "30-12345678-1")
    supplier = Supplier.new(company_name: "Droguería B", cuit: "30-12345678-1")
    assert_not supplier.valid?
    assert_includes supplier.errors[:cuit], "ya está en uso"
  end

  test "no es válido con email mal formado" do
    supplier = Supplier.new(company_name: "Test", cuit: "30-99999999-9", email: "no-es-un-email")
    assert_not supplier.valid?
    assert_includes supplier.errors[:email], "no es válido"
  end
end

class SupplierCuitTest < ActiveSupport::TestCase
  test "rechaza un CUIT con formato inválido" do
    supplier = Supplier.new(company_name: "Test", cuit: "30123456781")
    assert_not supplier.valid?
    assert_includes supplier.errors[:cuit], "debe tener el formato XX-XXXXXXXX-X"
  end

  test "rechaza un CUIT con dígito verificador incorrecto" do
    supplier = Supplier.new(company_name: "Test", cuit: "30-12345678-9")
    assert_not supplier.valid?
    assert_includes supplier.errors[:cuit], "tiene un dígito verificador inválido"
  end

  test "no permite eliminar un proveedor con órdenes de compra" do
    supplier = suppliers(:one)
    assert_not supplier.destroy
    assert Supplier.exists?(supplier.id)
  end
end
