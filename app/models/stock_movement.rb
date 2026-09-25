class StockMovement < ApplicationRecord
  belongs_to :batch
  belongs_to :user

  enum :movement_type, { entrada: 0, salida: 1, ajuste: 2, devaluacion_vencimiento: 3 }

  after_create :update_batch_quantity

  private

  def update_batch_quantity
    case movement_type
    when "entrada"
      batch.increment!(:quantity, quantity)
    when "salida", "devaluacion_vencimiento"
      batch.decrement!(:quantity, quantity)
    when "ajuste"
      batch.update!(quantity: quantity)
    end
  end
end
