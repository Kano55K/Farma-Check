class CreateBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :batches do |t|
      t.references :product, null: false, foreign_key: true
      t.string :lot_number
      t.date :expiration_date
      t.integer :quantity
      t.integer :status

      t.timestamps
    end
  end
end
