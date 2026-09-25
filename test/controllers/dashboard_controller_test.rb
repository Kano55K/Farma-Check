require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should redirect unauthenticated user to login" do
    get dashboard_index_url

    assert_redirected_to new_session_path
  end

  test "should get index for authenticated user" do
    sign_in_as(User.take)

    get dashboard_index_url

    assert_response :success
  end
end
