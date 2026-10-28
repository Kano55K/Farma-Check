# Opciones: include_items (agrega los ítems con su producto).
class PurchaseOrderSerializer < BaseSerializer
  def as_json
    data = {
      id: object.id,
      status: object.status,
      notes: object.notes,
      total_amount: money(object.total_amount),
      items_count: object.purchase_order_items.size,
      supplier: { id: object.supplier.id, company_name: object.supplier.company_name },
      created_at: timestamp(object.created_at),
      updated_at: timestamp(object.updated_at)
    }
    data[:items] = object.purchase_order_items.map { |item| item_json(item) } if options[:include_items]
    data
  end

  private

  def item_json(item)
    {
      id: item.id,
      product: { id: item.product.id, name: item.product.name, presentation: item.product.presentation },
      quantity: item.quantity,
      unit_price: money(item.unit_price),
      subtotal: money(item.subtotal)
    }
  end
end
