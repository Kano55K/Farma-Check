require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "es válido con atributos correctos" do
    product = Product.new(name: "Ibuprofeno 400mg")
    assert product.valid?
  end

  test "no es válido sin nombre" do
    product = Product.new(name: nil)
    assert_not product.valid?
    assert_includes product.errors[:name], "can't be blank"
  end

  test "no permite código de barras duplicado" do
    Product.create!(name: "Producto A", barcode: "1234567890")
    product = Product.new(name: "Producto B", barcode: "1234567890")
    assert_not product.valid?
    assert_includes product.errors[:barcode], "has already been taken"
  end

  test "permite código de barras vacío en múltiples productos" do
    Product.create!(name: "Producto A", barcode: nil)
    product = Product.new(name: "Producto B", barcode: nil)
    assert product.valid?
  end

  test "stock_status retorna :sin_stock cuando no hay lotes activos" do
    product = Product.create!(name: "Sin Stock")
    assert_equal :sin_stock, product.stock_status
  end

  test "stock_status retorna :stock_bajo cuando stock <= min_stock" do
    product = Product.create!(name: "Stock Bajo", min_stock: 10)
    product.batches.create!(lot_number: "L001", expiration_date: 1.year.from_now, quantity: 5, status: :active)
    assert_equal :stock_bajo, product.stock_status
  end

  test "stock_status retorna :ok cuando hay stock suficiente" do
    product = Product.create!(name: "OK", min_stock: 10)
    product.batches.create!(lot_number: "L001", expiration_date: 1.year.from_now, quantity: 50, status: :active)
    assert_equal :ok, product.stock_status
  end

  test "total_stock suma cantidad de lotes activos" do
    product = Product.create!(name: "Test")
    product.batches.create!(lot_number: "L001", expiration_date: 1.year.from_now, quantity: 30, status: :active)
    product.batches.create!(lot_number: "L002", expiration_date: 1.year.from_now, quantity: 20, status: :active)
    assert_equal 50, product.total_stock
  end
end
