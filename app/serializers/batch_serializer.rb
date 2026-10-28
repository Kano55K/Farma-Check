# Opciones: include_product (agrega un resumen del producto).
class BatchSerializer < BaseSerializer
  def as_json
    data = {
      id: object.id,
      product_id: object.product_id,
      lot_number: object.lot_number,
      expiration_date: date(object.expiration_date),
      quantity: object.quantity,
      location: object.location,
      status: object.status,
      expiration_status: object.expiration_status.to_s,
      days_to_expiration: object.expiration_date && (object.expiration_date - Date.current).to_i
    }
    data[:product] = ProductSerializer.new(object.product, summary: true).as_json if options[:include_product]
    data
  end
end
