# Revisa diariamente los lotes vencidos y actualiza su estado para activar alertas.
class CheckExpiredBatchesJob < ApplicationJob
  queue_as :default

  def perform
    Batch.where("expiration_date < ?", Date.today).active.find_each do |batch|
      batch.update!(status: :expired)
    end
  end
end
