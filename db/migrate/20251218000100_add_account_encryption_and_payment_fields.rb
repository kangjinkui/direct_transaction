class AddAccountEncryptionAndPaymentFields < ActiveRecord::Migration[8.0]
  def change
    add_column :farmers, :encrypted_account_info_iv, :string, null: false, default: "" unless column_exists?(:farmers, :encrypted_account_info_iv)
    add_column :payments, :verification_method, :string unless column_exists?(:payments, :verification_method)
  end
end
