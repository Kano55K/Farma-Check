require "test_helper"

class BatchTest < ActiveSupport::TestCase
  def setup
    @product = Product.create!(name: "Paracetamol 500mg")
  end

  test "es válido con atributos correctos" do
    batch = Batch.new(
      product: @product,
      lot_number: "L001",
      expiration_date: 1.year.from_now,
      quantity: 100,
      status: :active
    )
    assert batch.valid?
  end

  test "no es válido sin número de lote" do
    batch = Batch.new(product: @product, expiration_date: 1.year.from_now, quantity: 10)
    assert_not batch.valid?
    assert_includes batch.errors[:lot_number], "can't be blank"
  end

  test "no es válido sin fecha de vencimiento" do
    batch = Batch.new(product: @product, lot_number: "L001", quantity: 10)
    assert_not batch.valid?
    assert_includes batch.errors[:expiration_date], "can't be blank"
  end

  test "no es válido con cantidad negativa" do
    batch = Batch.new(product: @product, lot_number: "L001", expiration_date: 1.year.from_now, quantity: -1)
    assert_not batch.valid?
  end

  test "expiration_status retorna :critico si vence en menos de 30 días" do
    batch = Batch.create!(
      product: @product,
      lot_number: "L001",
      expiration_date: 15.days.from_now,
      quantity: 10,
      status: :active
    )
    assert_equal :critico, batch.expiration_status
  end

  test "expiration_status retorna :alerta si vence entre 30 y 90 días" do
    batch = Batch.create!(
      product: @product,
      lot_number: "L002",
      expiration_date: 60.days.from_now,
      quantity: 10,
      status: :active
    )
    assert_equal :alerta, batch.expiration_status
  end

  test "expiration_status retorna :ok si vence en más de 90 días" do
    batch = Batch.create!(
      product: @product,
      lot_number: "L003",
      expiration_date: 6.months.from_now,
      quantity: 10,
      status: :active
    )
    assert_equal :ok, batch.expiration_status
  end

  test "expiration_status retorna :vencido si ya venció" do
    batch = Batch.create!(
      product: @product,
      lot_number: "L004",
      expiration_date: 31.days.ago,
      quantity: 10,
      status: :active
    )
    assert_equal :vencido, batch.expiration_status
  end

  test "scope expiring_soon retorna lotes que vencen en 30 días" do
    batch_critico = Batch.create!(product: @product, lot_number: "L001", expiration_date: 10.days.from_now, quantity: 5, status: :active)
    batch_ok = Batch.create!(product: @product, lot_number: "L002", expiration_date: 6.months.from_now, quantity: 5, status: :active)
    assert_includes Batch.expiring_soon, batch_critico
    assert_not_includes Batch.expiring_soon, batch_ok
  end
end
