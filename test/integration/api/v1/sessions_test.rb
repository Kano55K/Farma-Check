require "test_helper"

module Api
  module V1
    class SessionsTest < ActionDispatch::IntegrationTest
      test "login correcto devuelve token con vencimiento y usuario" do
        post api_v1_login_url, params: { email_address: "employee@example.com", password: "password" }, as: :json

        assert_response :ok
        assert json["token"].present?
        assert_equal "Bearer", json["token_type"]
        assert_equal "employee", json.dig("user", "role")
        assert_in_delta User.api_token_ttl.from_now, Time.zone.parse(json["expires_at"]), 5.seconds
      end

      test "login también acepta las credenciales anidadas en session" do
        post api_v1_login_url, params: { session: { email_address: "admin@example.com", password: "password" } }, as: :json
        assert_response :ok
        assert_equal "admin", json.dig("user", "role")
      end

      test "login con credenciales incorrectas responde 401" do
        post api_v1_login_url, params: { email_address: "employee@example.com", password: "mala" }, as: :json
        assert_api_error :unauthorized, "invalid_credentials"
      end

      test "login sin datos responde 422 con detalle por campo" do
        post api_v1_login_url, params: {}, as: :json
        assert_api_error :unprocessable_entity, "validation_failed"
        assert json.dig("error", "details", "email_address").present?
      end

      test "login con JSON mal formado responde 400" do
        post api_v1_login_url, params: "{malo", headers: { "CONTENT_TYPE" => "application/json" }
        assert_api_error :bad_request, "bad_request"
      end

      test "responde a clientes que no son navegadores (sin 406 por allow_browser)" do
        post api_v1_login_url, params: { email_address: "employee@example.com", password: "password" }, as: :json,
                               headers: { "User-Agent" => "curl/8.0" }
        assert_response :ok
      end

      test "logout invalida el token" do
        headers = auth_headers(users(:employee))
        delete api_v1_logout_url, headers: headers
        assert_response :ok

        get api_v1_profile_url, headers: headers
        assert_api_error :unauthorized, "unauthorized"
      end

      test "logout sin token responde 401" do
        delete api_v1_logout_url
        assert_api_error :unauthorized, "unauthorized"
      end

      test "profile devuelve el usuario autenticado" do
        get api_v1_profile_url, headers: auth_headers(users(:admin))
        assert_response :ok
        assert_equal "admin@example.com", json["email"]
        assert_equal "admin", json["role"]
      end

      test "un token vencido responde 401 token_expired" do
        headers = auth_headers(users(:employee))
        travel User.api_token_ttl + 1.minute do
          get api_v1_profile_url, headers: headers
          assert_api_error :unauthorized, "token_expired"
        end
      end

      test "un token sin fecha de vencimiento se considera vencido" do
        user = users(:employee)
        user.update!(api_token: "token-viejo", api_token_expires_at: nil)
        get api_v1_profile_url, headers: { "Authorization" => "Bearer token-viejo" }
        assert_api_error :unauthorized, "token_expired"
      end

      test "CORS permite el origen del front-end" do
        process :options, api_v1_products_url, headers: {
          "Origin" => "http://localhost:5173",
          "Access-Control-Request-Method" => "GET",
          "Access-Control-Request-Headers" => "authorization"
        }
        assert_equal "http://localhost:5173", response.headers["Access-Control-Allow-Origin"]
      end
    end
  end
end
