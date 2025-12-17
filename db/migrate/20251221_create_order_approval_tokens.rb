class CreateOrderApprovalTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :order_approval_tokens do |t|
      t.references :order, null: false, foreign_key: true
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.string :purpose, null: false, default: "farmer_approval"

      t.timestamps
    end

    add_index :order_approval_tokens, :token, unique: true
    add_index :order_approval_tokens, :expires_at
  end
end
