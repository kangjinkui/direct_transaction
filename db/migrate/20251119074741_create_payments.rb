class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.string :payment_method, null: false, default: "manual_transfer"
      t.integer :amount, null: false, default: 0
      t.string :state, null: false, default: "pending"
      t.string :reference
      t.datetime :verified_at
      t.string :evidence_url

      t.timestamps
    end

    add_index :payments, :state
    add_index :payments, :reference
  end
end
