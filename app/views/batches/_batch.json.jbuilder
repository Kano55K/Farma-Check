json.extract! batch, :id, :product_id, :lot_number, :expiration_date, :quantity, :status, :created_at, :updated_at
json.url batch_url(batch, format: :json)
