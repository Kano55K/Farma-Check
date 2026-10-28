# Opciones: summary (solo datos básicos), include_batches (agrega los lotes ordenados por vencimiento).
class ProductSerializer < BaseSerializer
  def as_json
    return summary if options[:summary]

    data = summary.merge(
      barcode: object.barcode,
      code: object.code,
      therapeutic_action: object.therapeutic_action,
      gondola_location: object.gondola_location,
      min_stock: object.min_stock,
      safety_stock: object.safety_stock,
      prescription_required: object.prescription_required == true,
      total_stock: object.total_stock,
      stock_status: object.stock_status.to_s
    )
    if options[:include_batches]
      data[:batches] = BatchSerializer.render(object.batches.sort_by { |b| [ b.expiration_date || Date::Infinity.new, b.id ] })
    end
    data
  end

  private

  def summary
    {
      id: object.id,
      name: object.name,
      active_ingredient: object.active_ingredient,
      laboratory: object.laboratory,
      presentation: object.presentation
    }
  end
end
