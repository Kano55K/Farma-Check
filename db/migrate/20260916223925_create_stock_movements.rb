class CreateStockMovements < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_movements do |t|
      t.references :batch, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :movement_type
      t.integer :quantity
      t.string :reason

      t.timestamps
    end
  end
end
