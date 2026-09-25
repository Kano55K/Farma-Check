class AddLocationToBatches < ActiveRecord::Migration[8.1]
  def change
    add_column :batches, :location, :string
  end
end
