# Base de los serializers de la API: un objeto (o colección) → Hash listo para JSON.
# Fechas en ISO 8601: AAAA-MM-DD para fechas y AAAA-MM-DDTHH:MM:SSZ (UTC) para timestamps.
class BaseSerializer
  def self.render(object, **options)
    return object.map { |item| new(item, **options).as_json } if object.respond_to?(:to_ary)

    new(object, **options).as_json
  end

  attr_reader :object, :options

  def initialize(object, **options)
    @object = object
    @options = options
  end

  private

  def date(value)
    value&.to_date&.iso8601
  end

  def timestamp(value)
    value&.utc&.iso8601
  end

  def money(value)
    value.nil? ? nil : value.to_d.round(2).to_f
  end
end
