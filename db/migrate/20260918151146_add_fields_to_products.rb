class AddFieldsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :laboratory, :string
    add_column :products, :presentation, :string
    add_column :products, :barcode, :string
    add_column :products, :therapeutic_action, :string
    add_column :products, :gondola_location, :string
    add_column :products, :min_stock, :integer
    add_column :products, :safety_stock, :integer
  end
end
