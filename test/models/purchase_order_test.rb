require "test_helper"

class PurchaseOrderTest < ActiveSupport::TestCase
  test "calcula el total a partir de los ítems" do
    order = PurchaseOrder.new(supplier: suppliers(:one))
    order.purchase_order_items.build(product: products(:one), quantity: 3, unit_price: 100)
    order.purchase_order_items.build(product: products(:two), quantity: 2, unit_price: 50.5)
    order.save!
    assert_equal 401, order.total_amount
  end

  test "requiere al menos un ítem" do
    order = PurchaseOrder.new(supplier: suppliers(:one))
    assert_not order.valid?
    assert_includes order.errors[:purchase_order_items], "debe tener al menos un ítem"
  end

  test "envía una orden pendiente" do
    order = purchase_orders(:pending)
    order.send_order!
    assert order.reload.sent?
  end

  test "no envía una orden que ya fue enviada" do
    assert_raises(PurchaseOrder::InvalidTransition) { purchase_orders(:sent).send_order! }
  end

  test "cancela órdenes pendientes o enviadas, pero no recibidas" do
    purchase_orders(:pending).cancel!
    purchase_orders(:sent).cancel!
    assert_raises(PurchaseOrder::InvalidTransition) { purchase_orders(:received).cancel! }
  end

  test "recibir crea los lotes, registra las entradas y pasa a recibida" do
    order = purchase_orders(:sent)
    item = purchase_order_items(:sent_ibu)
    expiration = 1.year.from_now.to_date

    assert_difference [ "Batch.count", "StockMovement.count" ], 1 do
      order.receive!([ { id: item.id, lot_number: "L-REC-1", expiration_date: expiration.iso8601, location: "Depósito" } ], users(:employee))
    end

    batch = Batch.find_by!(lot_number: "L-REC-1")
    assert_equal 40, batch.quantity
    assert_equal expiration, batch.expiration_date
    assert_equal "entrada", batch.stock_movements.last.movement_type
    assert order.reload.received?
  end

  test "recibir con datos incompletos no crea nada" do
    order = purchase_orders(:sent)
    item = purchase_order_items(:sent_ibu)

    assert_no_difference [ "Batch.count", "StockMovement.count" ] do
      assert_raises(ActiveRecord::RecordInvalid) do
        order.receive!([ { id: item.id, lot_number: "", expiration_date: "2020-01-01" } ], users(:employee))
      end
    end
    assert order.reload.sent?
  end

  test "no se puede recibir una orden pendiente" do
    assert_raises(PurchaseOrder::InvalidTransition) { purchase_orders(:pending).receive!([], users(:employee)) }
  end
end
