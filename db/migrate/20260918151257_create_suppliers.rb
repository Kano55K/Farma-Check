class CreateSuppliers < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.string :company_name
      t.string :cuit
      t.string :phone
      t.string :email
      t.string :contact_name

      t.timestamps
    end
  end
end
