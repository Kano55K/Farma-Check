require "test_helper"

module Api
  module V1
    class ProductsTest < ActionDispatch::IntegrationTest
      setup { @headers = auth_headers(users(:employee)) }

      test "lista productos paginados con stock calculado" do
        get api_v1_products_url, headers: @headers, params: { per_page: 2 }

        assert_response :ok
        assert_equal 2, json["data"].size
        assert_equal({ "page" => 1, "per_page" => 2, "total_count" => 3, "total_pages" => 2 }, json["meta"].except("laboratories"))
        assert_includes json.dig("meta", "laboratories"), "Bagó"

        amoxicilina = json["data"].find { |p| p["name"] == "Amoxicilina 500 mg" }
        assert_equal 30, amoxicilina["total_stock"]
        assert_equal "stock_bajo", amoxicilina["stock_status"]
      end

      test "el stock total suma solo lotes activos (incluye el lote activo vencido por fecha)" do
        get api_v1_products_url, headers: @headers, params: { search: "ibupro" }
        assert_equal 1, json["data"].size
        assert_equal 115, json["data"][0]["total_stock"]
      end

      test "filtra por estado de stock, laboratorio y receta" do
        get api_v1_products_url, headers: @headers, params: { stock_status: "sin_stock" }
        assert_equal [ "Enalapril 10 mg" ], json["data"].map { |p| p["name"] }
        assert_equal 1, json.dig("meta", "total_count")

        get api_v1_products_url, headers: @headers, params: { laboratory: "Roemmers" }
        assert_equal [ "Amoxicilina 500 mg" ], json["data"].map { |p| p["name"] }

        get api_v1_products_url, headers: @headers, params: { prescription_required: "false" }
        assert_equal [ "Ibuprofeno 400 mg" ], json["data"].map { |p| p["name"] }
      end

      test "busca por droga" do
        get api_v1_products_url, headers: @headers, params: { search: "amoxi" }
        assert_equal [ "Amoxicilina 500 mg" ], json["data"].map { |p| p["name"] }
      end

      test "un filtro con valor inválido responde 422" do
        get api_v1_products_url, headers: @headers, params: { stock_status: "mucho" }
        assert_api_error :unprocessable_entity, "invalid_params"
        assert json.dig("error", "details", "stock_status").present?
      end

      test "detalle incluye los lotes con semáforo ordenados por vencimiento" do
        get api_v1_product_url(products(:one)), headers: @headers

        assert_response :ok
        lots = json.dig("data", "batches")
        assert_equal %w[L-IBU-000 L-IBU-001], lots.map { |b| b["lot_number"] }
        assert_equal %w[vencido ok], lots.map { |b| b["expiration_status"] }
        assert_match(/\A\d{4}-\d{2}-\d{2}\z/, lots[0]["expiration_date"])
      end

      test "producto inexistente responde 404" do
        get api_v1_product_url(id: 0), headers: @headers
        assert_api_error :not_found, "not_found"
      end

      test "sin token responde 401" do
        get api_v1_products_url
        assert_api_error :unauthorized, "unauthorized"
      end
    end
  end
end
