require "test_helper"

module Api
  module V1
    class DashboardTest < ActionDispatch::IntegrationTest
      test "devuelve KPIs y alertas" do
        get api_v1_dashboard_url, headers: auth_headers(users(:employee))

        assert_response :ok
        kpis = json.dig("data", "kpis")
        assert_equal 3, kpis["total_products"]
        assert_equal 1, kpis["low_stock_products"]
        assert_equal 1, kpis["out_of_stock_products"]
        assert_equal 1, kpis["expired_batches"]
        assert_equal 1, kpis["critical_batches"]
        assert_equal 0, kpis["warning_batches"]
        assert_equal 2, kpis["pending_purchase_orders"]

        types = json.dig("data", "alerts").map { |a| a["type"] }
        assert_equal %w[batch_expired batch_critical out_of_stock low_stock], types
      end

      test "sin token responde 401" do
        get api_v1_dashboard_url
        assert_api_error :unauthorized, "unauthorized"
      end
    end
  end
end
