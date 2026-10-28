require "test_helper"

module Api
  module V1
    class StockMovementsTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:employee)
        @headers = auth_headers(@user)
        @batch = batches(:one)
      end

      test "registra una salida y actualiza el stock del lote" do
        assert_difference "StockMovement.count", 1 do
          post api_v1_stock_movements_url, headers: @headers, as: :json,
               params: { stock_movement: { batch_id: @batch.id, movement_type: "salida", quantity: 10, reason: "Venta" } }
        end

        assert_response :created
        assert_equal "salida", json.dig("data", "movement_type")
        assert_equal 90, json.dig("data", "batch", "quantity")
        assert_equal @user.email_address, json.dig("data", "user", "email")
        assert_equal 90, @batch.reload.quantity
      end

      test "acepta el cuerpo plano (compatibilidad con la colección de Postman)" do
        post api_v1_stock_movements_url, headers: @headers, as: :json,
             params: { batch_id: @batch.id, movement_type: "entrada", quantity: 5, reason: "Compra" }
        assert_response :created
        assert_equal 105, @batch.reload.quantity
      end

      test "una salida mayor al stock responde 422 y no modifica nada" do
        assert_no_difference "StockMovement.count" do
          post api_v1_stock_movements_url, headers: @headers, as: :json,
               params: { stock_movement: { batch_id: @batch.id, movement_type: "salida", quantity: 500 } }
        end

        assert_api_error :unprocessable_entity, "validation_failed"
        assert_equal [ "supera el stock disponible del lote (100)" ], json.dig("error", "details", "quantity")
        assert_equal 100, @batch.reload.quantity
      end

      test "un tipo de movimiento inválido responde 422 (no 500)" do
        post api_v1_stock_movements_url, headers: @headers, as: :json,
             params: { stock_movement: { batch_id: @batch.id, movement_type: "entry", quantity: 5 } }
        assert_api_error :unprocessable_entity, "validation_failed"
        assert json.dig("error", "details", "movement_type").present?
      end

      test "cantidad cero o negativa responde 422" do
        post api_v1_stock_movements_url, headers: @headers, as: :json,
             params: { stock_movement: { batch_id: @batch.id, movement_type: "salida", quantity: -3 } }
        assert_api_error :unprocessable_entity, "validation_failed"
      end

      test "salida sobre un lote vencido responde 422" do
        post api_v1_stock_movements_url, headers: @headers, as: :json,
             params: { stock_movement: { batch_id: batches(:expired).id, movement_type: "salida", quantity: 1 } }
        assert_api_error :unprocessable_entity, "validation_failed"
        assert json.dig("error", "details", "batch").present?
      end

      test "sin batch_id responde 400" do
        post api_v1_stock_movements_url, headers: @headers, as: :json,
             params: { stock_movement: { movement_type: "salida", quantity: 1 } }
        assert_api_error :bad_request, "bad_request"
      end

      test "lote inexistente responde 404" do
        post api_v1_stock_movements_url, headers: @headers, as: :json,
             params: { stock_movement: { batch_id: 0, movement_type: "salida", quantity: 1 } }
        assert_api_error :not_found, "not_found"
      end

      test "lista movimientos con filtros por tipo, producto y fechas" do
        get api_v1_stock_movements_url, headers: @headers
        assert_response :ok
        assert_equal 2, json.dig("meta", "total_count")

        get api_v1_stock_movements_url, headers: @headers, params: { movement_type: "entrada" }
        assert_equal [ "entrada" ], json["data"].map { |m| m["movement_type"] }

        get api_v1_stock_movements_url, headers: @headers, params: { product_id: products(:one).id }
        assert_equal [ "L-IBU-001" ], json["data"].map { |m| m.dig("batch", "lot_number") }

        get api_v1_stock_movements_url, headers: @headers, params: { from: 1.day.from_now.to_date.iso8601 }
        assert_equal 0, json.dig("meta", "total_count")

        get api_v1_stock_movements_url, headers: @headers, params: { to: Date.current.iso8601 }
        assert_equal 2, json.dig("meta", "total_count")
      end

      test "fecha con formato inválido o tipo inexistente en los filtros responde 422" do
        get api_v1_stock_movements_url, headers: @headers, params: { from: "28/10/2026" }
        assert_api_error :unprocessable_entity, "invalid_params"

        get api_v1_stock_movements_url, headers: @headers, params: { movement_type: "robo" }
        assert_api_error :unprocessable_entity, "invalid_params"
      end

      test "sin token responde 401" do
        post api_v1_stock_movements_url, as: :json, params: { batch_id: @batch.id, movement_type: "salida", quantity: 1 }
        assert_api_error :unauthorized, "unauthorized"
      end
    end
  end
end
