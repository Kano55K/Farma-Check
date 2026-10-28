# CORS para la API: permite que el front-end (otro origen) consuma /api/*.
# Orígenes permitidos en FRONTEND_ORIGIN, separados por coma. Por defecto, el servidor de Vite.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*ENV.fetch("FRONTEND_ORIGIN", "http://localhost:5173,http://127.0.0.1:5173").split(",").map(&:strip))

    resource "/api/*",
      headers: :any,
      methods: %i[get post patch put delete options head],
      expose: %w[Authorization],
      max_age: 600
  end
end
