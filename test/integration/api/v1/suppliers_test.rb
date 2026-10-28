require "test_helper"

module Api
  module V1
    class SuppliersTest < ActionDispatch::IntegrationTest
      setup do
        @employee_headers = auth_headers(users(:employee))
        @admin_headers = auth_headers(users(:admin))
        @valid = { company_name: "Droguería Norte S.A.", cuit: "30-70111222-5", email: "info@norte.com.ar" }
      end

      test "lista y busca proveedores" do
        get api_v1_suppliers_url, headers: @employee_headers
        assert_response :ok
        assert_equal 2, json.dig("meta", "total_count")

        get api_v1_suppliers_url, headers: @employee_headers, params: { search: "pampa" }
        assert_equal [ "Distribuidora Pampa S.R.L." ], json["data"].map { |s| s["company_name"] }
      end

      test "detalle con órdenes recientes" do
        get api_v1_supplier_url(suppliers(:one)), headers: @employee_headers
        assert_response :ok
        assert_equal "30-71234567-1", json.dig("data", "cuit")
        assert_equal 2, json.dig("data", "recent_purchase_orders").size
      end

      test "proveedor inexistente responde 404" do
        get api_v1_supplier_url(id: 0), headers: @employee_headers
        assert_api_error :not_found, "not_found"
      end

      test "admin crea un proveedor" do
        assert_difference "Supplier.count", 1 do
          post api_v1_suppliers_url, headers: @admin_headers, as: :json, params: { supplier: @valid }
        end
        assert_response :created
        assert_equal "30-70111222-5", json.dig("data", "cuit")
      end

      test "empleado no puede crear proveedores (403)" do
        assert_no_difference "Supplier.count" do
          post api_v1_suppliers_url, headers: @employee_headers, as: :json, params: { supplier: @valid }
        end
        assert_api_error :forbidden, "forbidden"
      end

      test "CUIT inválido responde 422 con detalle" do
        post api_v1_suppliers_url, headers: @admin_headers, as: :json, params: { supplier: @valid.merge(cuit: "30-70111222-9") }
        assert_api_error :unprocessable_entity, "validation_failed"
        assert_equal [ "tiene un dígito verificador inválido" ], json.dig("error", "details", "cuit")
      end

      test "admin actualiza y empleado recibe 403" do
        patch api_v1_supplier_url(suppliers(:two)), headers: @admin_headers, as: :json, params: { supplier: { phone: "011 4000-0000" } }
        assert_response :ok
        assert_equal "011 4000-0000", suppliers(:two).reload.phone

        patch api_v1_supplier_url(suppliers(:two)), headers: @employee_headers, as: :json, params: { supplier: { phone: "1" } }
        assert_api_error :forbidden, "forbidden"
      end

      test "sin token responde 401" do
        get api_v1_suppliers_url
        assert_api_error :unauthorized, "unauthorized"
      end
    end
  end
end
