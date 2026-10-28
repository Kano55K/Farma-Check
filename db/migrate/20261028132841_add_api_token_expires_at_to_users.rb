class AddApiTokenExpiresAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :api_token_expires_at, :datetime
  end
end
