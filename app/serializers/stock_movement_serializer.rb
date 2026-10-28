class StockMovementSerializer < BaseSerializer
  def as_json
    batch = object.batch
    {
      id: object.id,
      movement_type: object.movement_type,
      quantity: object.quantity,
      reason: object.reason,
      created_at: timestamp(object.created_at),
      batch: {
        id: batch.id,
        lot_number: batch.lot_number,
        quantity: batch.quantity,
        expiration_date: date(batch.expiration_date)
      },
      product: { id: batch.product.id, name: batch.product.name },
      user: { id: object.user.id, email: object.user.email_address }
    }
  end
end
