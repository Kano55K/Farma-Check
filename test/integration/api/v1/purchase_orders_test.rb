require "test_helper"

module Api
  module V1
    class PurchaseOrdersTest < ActionDispatch::IntegrationTest
      setup do
        @employee = users(:employee)
        @employee_headers = auth_headers(@employee)
        @admin_headers = auth_headers(users(:admin))
      end

      test "lista órdenes filtradas por estado y proveedor" do
        get api_v1_purchase_orders_url, headers: @employee_headers
        assert_response :ok
        assert_equal 4, json.dig("meta", "total_count")

        get api_v1_purchase_orders_url, headers: @employee_headers, params: { status: "pending" }
        assert_equal [ "pending" ], json["data"].map { |o| o["status"] }

        get api_v1_purchase_orders_url, headers: @employee_headers, params: { supplier_id: suppliers(:two).id }
        assert_equal 2, json["data"].size
      end

      test "estado inválido en el filtro responde 422" do
        get api_v1_purchase_orders_url, headers: @employee_headers, params: { status: "perdida" }
        assert_api_error :unprocessable_entity, "invalid_params"
      end

      test "detalle con ítems y subtotales" do
        get api_v1_purchase_order_url(purchase_orders(:pending)), headers: @employee_headers
        assert_response :ok
        assert_equal 2, json.dig("data", "items").size
        assert_equal [ 1500.0, 1000.0 ], json.dig("data", "items").map { |i| i["subtotal"] }.sort.reverse
      end

      test "orden inexistente responde 404" do
        get api_v1_purchase_order_url(id: 0), headers: @employee_headers
        assert_api_error :not_found, "not_found"
      end

      test "crea una orden con ítems y calcula el total en el servidor" do
        assert_difference [ "PurchaseOrder.count" ], 1 do
          post api_v1_purchase_orders_url, headers: @employee_headers, as: :json, params: {
            purchase_order: {
              supplier_id: suppliers(:one).id, notes: "Urgente", total_amount: 1,
              items: [ { product_id: products(:one).id, quantity: 10, unit_price: 25.5 },
                       { product_id: products(:two).id, quantity: 4, unit_price: 100 } ]
            }
          }
        end

        assert_response :created
        assert_equal "pending", json.dig("data", "status")
        assert_equal 655.0, json.dig("data", "total_amount")
        assert_equal 2, json.dig("data", "items").size
      end

      test "crear sin ítems o con cantidad inválida responde 422" do
        post api_v1_purchase_orders_url, headers: @employee_headers, as: :json,
             params: { purchase_order: { supplier_id: suppliers(:one).id, items: [] } }
        assert_api_error :unprocessable_entity, "validation_failed"
        assert json.dig("error", "details", "purchase_order_items").present?

        post api_v1_purchase_orders_url, headers: @employee_headers, as: :json,
             params: { purchase_order: { supplier_id: suppliers(:one).id, items: [ { product_id: products(:one).id, quantity: 0 } ] } }
        assert_api_error :unprocessable_entity, "validation_failed"
      end

      test "crear sin proveedor responde 422" do
        post api_v1_purchase_orders_url, headers: @employee_headers, as: :json,
             params: { purchase_order: { items: [ { product_id: products(:one).id, quantity: 1 } ] } }
        assert_api_error :unprocessable_entity, "validation_failed"
      end

      test "envía una orden pendiente y rechaza reenviarla" do
        order = purchase_orders(:pending)
        patch send_api_v1_purchase_order_url(order), headers: @employee_headers
        assert_response :ok
        assert_equal "sent", json.dig("data", "status")

        patch send_api_v1_purchase_order_url(order), headers: @employee_headers
        assert_api_error :unprocessable_entity, "invalid_transition"
      end

      test "solo admin cancela" do
        order = purchase_orders(:pending)
        patch cancel_api_v1_purchase_order_url(order), headers: @employee_headers
        assert_api_error :forbidden, "forbidden"

        patch cancel_api_v1_purchase_order_url(order), headers: @admin_headers
        assert_response :ok
        assert_equal "cancelled", json.dig("data", "status")
      end

      test "cancelar una orden recibida responde 422" do
        patch cancel_api_v1_purchase_order_url(purchase_orders(:received)), headers: @admin_headers
        assert_api_error :unprocessable_entity, "invalid_transition"
      end

      test "recibir crea lotes y movimientos de entrada y pasa la orden a recibida" do
        order = purchase_orders(:sent)
        item = purchase_order_items(:sent_ibu)
        stock_before = products(:one).total_stock

        assert_difference [ "Batch.count", "StockMovement.count" ], 1 do
          post receive_api_v1_purchase_order_url(order), headers: @employee_headers, as: :json, params: {
            purchase_order: { items: [ { id: item.id, lot_number: "L-NUEVO-9", expiration_date: 2.years.from_now.to_date.iso8601, location: "Depósito 1" } ] }
          }
        end

        assert_response :ok
        assert_equal "received", json.dig("data", "status")
        batch = Batch.find_by!(lot_number: "L-NUEVO-9")
        assert_equal 40, batch.quantity
        assert_equal "Depósito 1", batch.location
        assert_equal stock_before + 40, products(:one).reload.total_stock
        movement = batch.stock_movements.last
        assert_equal "entrada", movement.movement_type
        assert_equal @employee, movement.user
      end

      test "recibir con vencimiento pasado responde 422 con detalle por ítem" do
        order = purchase_orders(:sent)
        item = purchase_order_items(:sent_ibu)

        assert_no_difference [ "Batch.count", "StockMovement.count" ] do
          post receive_api_v1_purchase_order_url(order), headers: @employee_headers, as: :json, params: {
            purchase_order: { items: [ { id: item.id, lot_number: "L-X", expiration_date: "2020-01-01" } ] }
          }
        end

        assert_api_error :unprocessable_entity, "validation_failed"
        assert_equal [ "debe ser posterior a hoy" ], json.dig("error", "details", "items[0].expiration_date")
        assert order.reload.sent?
      end

      test "recibir una orden pendiente responde 422 invalid_transition" do
        post receive_api_v1_purchase_order_url(purchase_orders(:pending)), headers: @employee_headers, as: :json,
             params: { purchase_order: { items: [] } }
        assert_api_error :unprocessable_entity, "invalid_transition"
      end

      test "sin token responde 401" do
        get api_v1_purchase_orders_url
        assert_api_error :unauthorized, "unauthorized"
      end
    end
  end
end
