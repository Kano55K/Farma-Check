class CheckExpiredBatchesJob < ApplicationJob
  queue_as :default

  def perform
    Batch.where("expiration_date < ?", Date.today).where.not(status: :vencido).find_each do |batch|
      batch.update!(status: :vencido)
    end
  end
end
