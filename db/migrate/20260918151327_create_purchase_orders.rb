class CreatePurchaseOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :purchase_orders do |t|
      t.integer :supplier_id
      t.integer :status
      t.text :notes
      t.decimal :total_amount

      t.timestamps
    end
  end
end
