class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.string :active_ingredient
      t.string :code
      t.boolean :prescription_required

      t.timestamps
    end
  end
end
