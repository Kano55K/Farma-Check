module Api
  module V1
    # Base para todos los endpoints de la API.
    #
    # Hereda de ActionController::API (sin allow_browser, cookies ni CSRF del back-office),
    # valida el token Bearer, centraliza el formato único de error y ofrece paginación.
    #
    # Formato de error: { "error": { "code": "...", "message": "...", "details": { ... } | null } }
    class BaseController < ActionController::API
      # Se lanza cuando el usuario autenticado no tiene el rol necesario.
      class Forbidden < StandardError; end

      # Se lanza cuando un parámetro de consulta tiene un valor o formato inválido.
      class InvalidParams < StandardError
        attr_reader :details

        def initialize(details)
          @details = details
          super("Parámetros inválidos")
        end
      end

      DEFAULT_PER_PAGE = 20
      MAX_PER_PAGE = 100
      NOT_FOUND_MESSAGES = {
        "Product" => "Producto no encontrado", "Batch" => "Lote no encontrado",
        "StockMovement" => "Movimiento no encontrado", "Supplier" => "Proveedor no encontrado",
        "PurchaseOrder" => "Orden de compra no encontrada", "User" => "Usuario no encontrado"
      }.freeze

      before_action :authenticate_api_user!

      # rescue_from busca de abajo hacia arriba: ArgumentError queda como último recurso.
      rescue_from ArgumentError, with: :render_argument_error
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
      rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_parse_error
      rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
      rescue_from InvalidParams, with: :render_invalid_params
      rescue_from Forbidden, with: :render_forbidden
      rescue_from PurchaseOrder::InvalidTransition, with: :render_invalid_transition

      private

      attr_reader :current_user

      # Busca al usuario por el token del header Authorization y verifica que no esté vencido.
      def authenticate_api_user!
        user = User.find_by_api_token(bearer_token)
        return render_error("unauthorized", "Falta el token o no es válido. Iniciá sesión.", :unauthorized) unless user
        return render_error("token_expired", "La sesión expiró. Iniciá sesión nuevamente.", :unauthorized) if user.api_token_expired?

        @current_user = user
      end

      def bearer_token
        header = request.headers["Authorization"].to_s
        header[/\ABearer\s+(.+)\z/i, 1]&.strip
      end

      def require_admin!
        raise Forbidden unless current_user&.admin?
      end

      def render_error(code, message, status, details = nil)
        render json: { error: { code: code, message: message, details: details } }, status: status
      end

      # Pagina un scope. Devuelve [registros, meta].
      def paginate(scope)
        per_page = params[:per_page].to_i
        per_page = DEFAULT_PER_PAGE if per_page <= 0
        per_page = [ per_page, MAX_PER_PAGE ].min
        page = [ params[:page].to_i, 1 ].max
        total_count = scope.unscope(:select, :order).count
        total_count = total_count.size if total_count.is_a?(Hash) # count con group devuelve un Hash
        total_pages = (total_count.to_f / per_page).ceil
        records = scope.limit(per_page).offset((page - 1) * per_page).to_a
        [ records, { page: page, per_page: per_page, total_count: total_count, total_pages: total_pages } ]
      end

      # Valida que un filtro tenga uno de los valores admitidos; si no, responde 422.
      def validate_filter!(name, allowed)
        value = params[name]
        return if value.blank? || allowed.include?(value.to_s)

        raise InvalidParams.new(name => [ "debe ser uno de: #{allowed.join(', ')}" ])
      end

      # Parsea una fecha AAAA-MM-DD de los parámetros (422 si el formato es incorrecto).
      def date_param(name)
        return if params[name].blank?

        Date.iso8601(params[name].to_s)
      rescue Date::Error
        raise InvalidParams.new(name => [ "debe tener formato AAAA-MM-DD" ])
      end

      def render_not_found(exception)
        render_error("not_found", NOT_FOUND_MESSAGES.fetch(exception.model.to_s, "Recurso no encontrado"), :not_found)
      end

      def render_parameter_missing(exception)
        render_error("bad_request", "Falta el parámetro obligatorio \"#{exception.param}\"", :bad_request,
                     { exception.param => [ "es obligatorio" ] })
      end

      def render_parse_error(_exception)
        render_error("bad_request", "El cuerpo de la petición no es un JSON válido", :bad_request)
      end

      def render_record_invalid(exception)
        record = exception.record
        render_error("validation_failed", "Los datos enviados no son válidos: #{record.errors.full_messages.to_sentence}",
                     :unprocessable_entity, record.errors.to_hash)
      end

      def render_invalid_params(exception)
        render_error("invalid_params", "Hay parámetros con valores no válidos", :unprocessable_entity, exception.details)
      end

      # Los enums de Rails lanzan ArgumentError ("'x' is not a valid status"); el resto se relanza.
      def render_argument_error(exception)
        match = exception.message.match(/\A'(.*)' is not a valid (\w+)\z/)
        raise exception unless match

        render_error("invalid_value", "El valor \"#{match[1]}\" no es válido para #{match[2]}", :unprocessable_entity,
                     { match[2] => [ "no es un valor admitido" ] })
      end

      def render_forbidden(_exception = nil)
        render_error("forbidden", "No tenés permisos para realizar esta acción", :forbidden)
      end

      def render_invalid_transition(exception)
        render_error("invalid_transition", exception.message, :unprocessable_entity)
      end
    end
  end
end
