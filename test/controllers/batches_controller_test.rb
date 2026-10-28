require "test_helper"

class BatchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @batch = batches(:one)
    sign_in_as(users(:admin))
  end

  test "should get index" do
    get batches_url
    assert_response :success
  end

  test "should get new" do
    get new_batch_url
    assert_response :success
  end

  test "should create batch" do
    assert_difference("Batch.count") do
      post batches_url, params: { batch: { expiration_date: @batch.expiration_date, lot_number: "L-NUEVO", product_id: @batch.product_id, quantity: @batch.quantity, status: @batch.status } }
    end

    assert_redirected_to product_url(@batch.product)
  end

  test "should show batch" do
    get batch_url(@batch)
    assert_response :success
  end

  test "should get edit" do
    get edit_batch_url(@batch)
    assert_response :success
  end

  test "should update batch" do
    patch batch_url(@batch), params: { batch: { expiration_date: @batch.expiration_date, lot_number: @batch.lot_number, product_id: @batch.product_id, quantity: @batch.quantity, status: @batch.status } }
    assert_redirected_to product_url(@batch.product)
  end

  test "should destroy batch" do
    assert_difference("Batch.count", -1) do
      delete batch_url(@batch)
    end

    assert_redirected_to product_url(@batch.product)
  end
end
