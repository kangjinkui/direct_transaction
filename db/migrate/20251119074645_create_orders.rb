class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :farmer, null: false, foreign_key: true
      t.integer :total_amount, null: false, default: 0
      t.string :status, null: false, default: "pending"
      t.string :order_number, null: false
      t.datetime :confirmed_at
      t.datetime :paid_at
      t.datetime :completed_at
      t.datetime :cancelled_at
      t.string :rejection_reason
      t.json :policy_snapshot, default: {}

      t.timestamps
    end

    add_index :orders, :order_number, unique: true
    add_index :orders, :status
    add_index :orders, %i[user_id status]
  end
end
