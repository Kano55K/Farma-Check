require "test_helper"

class PurchaseOrdersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:admin)) }

  test "should get index" do
    get purchase_orders_url
    assert_response :success
  end

  test "should show purchase order" do
    get purchase_order_url(purchase_orders(:pending))
    assert_response :success
  end

  test "should create purchase order with server-side total" do
    assert_difference("PurchaseOrder.count") do
      post purchase_orders_url, params: { purchase_order: {
        supplier_id: suppliers(:one).id, status: "pending",
        purchase_order_items_attributes: { "0" => { product_id: products(:one).id, quantity: 3, unit_price: 10 } }
      } }
    end

    assert_redirected_to purchase_order_url(PurchaseOrder.last)
    assert_equal 30, PurchaseOrder.last.total_amount
  end
end
