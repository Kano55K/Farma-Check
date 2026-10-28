require "test_helper"

class SuppliersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:admin)) }

  test "should get index" do
    get suppliers_url
    assert_response :success
  end

  test "should not destroy supplier with purchase orders" do
    assert_no_difference("Supplier.count") do
      delete supplier_url(suppliers(:one))
    end

    assert_redirected_to supplier_url(suppliers(:one))
  end
end
