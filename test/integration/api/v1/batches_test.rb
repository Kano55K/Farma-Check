require "test_helper"

module Api
  module V1
    class BatchesTest < ActionDispatch::IntegrationTest
      setup { @headers = auth_headers(users(:employee)) }

      test "lista lotes ordenados por vencimiento con el producto" do
        get api_v1_batches_url, headers: @headers

        assert_response :ok
        assert_equal %w[L-IBU-000 L-AMO-001 L-IBU-001], json["data"].map { |b| b["lot_number"] }
        assert_equal "Ibuprofeno 400 mg", json["data"][0].dig("product", "name")
        assert_equal 3, json.dig("meta", "total_count")
      end

      test "filtra por estado de vencimiento" do
        { "vencido" => %w[L-IBU-000], "critico" => %w[L-AMO-001], "alerta" => [], "ok" => %w[L-IBU-001] }.each do |status, lots|
          get api_v1_batches_url, headers: @headers, params: { expiration_status: status }
          assert_equal lots, json["data"].map { |b| b["lot_number"] }, "Filtro #{status}"
          assert(json["data"].all? { |b| b["expiration_status"] == status })
        end
      end

      test "filtra por producto y permite orden descendente" do
        get api_v1_batches_url, headers: @headers, params: { product_id: products(:one).id, sort: "-expiration_date" }
        assert_equal %w[L-IBU-001 L-IBU-000], json["data"].map { |b| b["lot_number"] }
      end

      test "estado de vencimiento inválido responde 422" do
        get api_v1_batches_url, headers: @headers, params: { expiration_status: "podrido" }
        assert_api_error :unprocessable_entity, "invalid_params"
      end

      test "detalle de un lote" do
        get api_v1_batch_url(batches(:two)), headers: @headers
        assert_response :ok
        assert_equal "critico", json.dig("data", "expiration_status")
        assert_equal 30, json.dig("data", "quantity")
      end

      test "lote inexistente responde 404" do
        get api_v1_batch_url(id: 0), headers: @headers
        assert_api_error :not_found, "not_found"
        assert_equal "Lote no encontrado", json.dig("error", "message")
      end

      test "sin token responde 401" do
        get api_v1_batches_url
        assert_api_error :unauthorized, "unauthorized"
      end
    end
  end
end
