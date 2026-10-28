# Helpers para los tests de integración de la API: login por token y lectura del JSON.
module ApiTestHelper
  def api_token_for(user)
    user.issue_api_token!
  end

  def auth_headers(user)
    { "Authorization" => "Bearer #{api_token_for(user)}" }
  end

  def json
    JSON.parse(response.body)
  end

  def assert_api_error(status, code)
    assert_response status
    assert_equal code, json.dig("error", "code"), "Respuesta: #{response.body}"
    assert json.dig("error", "message").present?
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include ApiTestHelper
end
