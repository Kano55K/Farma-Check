require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "admin should get new" do
    sign_in_as(users(:admin))
    get new_user_url
    assert_response :success
  end

  test "admin should create user" do
    sign_in_as(users(:admin))
    assert_difference("User.count") do
      post users_url, params: { user: { email_address: "nuevo@farma.com", password: "demo1234", password_confirmation: "demo1234", role: "employee" } }
    end

    assert_redirected_to dashboard_url
  end

  test "employee cannot create users" do
    sign_in_as(users(:employee))
    get new_user_url
    assert_redirected_to dashboard_url
  end
end
