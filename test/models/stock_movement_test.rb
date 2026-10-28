require "test_helper"

class StockMovementTest < ActiveSupport::TestCase
  setup do
    @user = users(:employee)
    @batch = batches(:one) # 100 unidades, vence en un año
  end

  def build(attrs = {})
    StockMovement.new({ batch: @batch, user: @user, movement_type: "salida", quantity: 5 }.merge(attrs))
  end

  test "una salida descuenta el stock del lote" do
    build(quantity: 30).save!
    assert_equal 70, @batch.reload.quantity
  end

  test "una entrada suma stock al lote" do
    build(movement_type: "entrada", quantity: 20).save!
    assert_equal 120, @batch.reload.quantity
  end

  test "un ajuste fija el stock del lote, incluso en cero" do
    build(movement_type: "ajuste", quantity: 0).save!
    assert_equal 0, @batch.reload.quantity
  end

  test "requiere tipo y cantidad" do
    movement = build(movement_type: nil, quantity: nil)
    assert_not movement.valid?
    assert movement.errors[:movement_type].any?
    assert movement.errors[:quantity].any?
  end

  test "la cantidad debe ser mayor que cero salvo en ajustes" do
    movement = build(quantity: 0)
    assert_not movement.valid?
    assert_includes movement.errors[:quantity], "debe ser un número entero mayor que 0"
  end

  test "rechaza un tipo de movimiento inexistente sin lanzar excepción" do
    movement = build(movement_type: "entry")
    assert_not movement.valid?
    assert movement.errors[:movement_type].first.start_with?("no es válido")
  end

  test "no permite una salida mayor al stock disponible ni modifica el lote" do
    movement = build(quantity: 101)
    assert_not movement.save
    assert_includes movement.errors[:quantity], "supera el stock disponible del lote (100)"
    assert_equal 100, @batch.reload.quantity
  end

  test "no permite salidas de un lote vencido" do
    movement = build(batch: batches(:expired), quantity: 1)
    assert_not movement.valid?
    assert movement.errors[:batch].any?
  end

  test "permite registrar la devaluación por vencimiento de un lote vencido" do
    batch = batches(:expired)
    build(batch: batch, movement_type: "devaluacion_vencimiento", quantity: batch.quantity).save!
    assert_equal 0, batch.reload.quantity
  end

  test "no permite salidas de un lote retirado" do
    @batch.update!(status: :recalled)
    assert_not build.valid?
  end
end
