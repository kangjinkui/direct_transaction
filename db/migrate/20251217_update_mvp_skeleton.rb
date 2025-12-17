class UpdateMvpSkeleton < ActiveRecord::Migration[8.0]
  def change
    change_table :farmers, bulk: true do |t|
      t.string :approval_mode, null: false, default: "manual"
      t.integer :stock_quantity, null: false, default: 0
      t.text :encrypted_account_info, null: false, default: ""
    end
    add_index :farmers, :approval_mode

    change_table :products, bulk: true do |t|
      t.boolean :is_available, null: false, default: true
    end

    json_type = ActiveRecord::Base.connection.adapter_name.downcase.include?("sqlite") ? :json : :jsonb
    change_table :orders, bulk: true do |t|
      t.public_send(json_type, :status_history, null: false, default: [])
      t.datetime :timeout_at
    end
    add_index :orders, :timeout_at

    if column_exists?(:payments, :state)
      rename_column :payments, :state, :status
      rename_index :payments, "index_payments_on_state", "index_payments_on_status" if index_name_exists?(:payments, "index_payments_on_state")
    end
    add_column :payments, :admin_note, :text unless column_exists?(:payments, :admin_note)

    create_table :notifications do |t|
      t.references :order, null: false, foreign_key: true
      t.references :farmer, null: false, foreign_key: true
      t.string :notification_type, null: false
      t.string :channel, null: false, default: "kakao"
      t.string :status, null: false, default: "pending"
      t.string :token_jti
      t.datetime :used_at
      t.datetime :expires_at
      t.datetime :sent_at
      t.timestamps
    end
    add_index :notifications, :channel
    add_index :notifications, :status
    add_index :notifications, :token_jti, unique: true
  end
end
