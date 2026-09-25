require "test_helper"

class PurchaseOrdersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get purchase_orders_index_url
    assert_response :success
  end
end
