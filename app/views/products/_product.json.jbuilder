json.extract! product, :id, :name, :active_ingredient, :code, :prescription_required, :created_at, :updated_at
json.url product_url(product, format: :json)
