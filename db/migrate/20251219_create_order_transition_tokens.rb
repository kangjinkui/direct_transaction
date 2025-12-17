class CreateOrderTransitionTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :order_transition_tokens do |t|
      t.references :order, null: false, foreign_key: true
      t.string :token, null: false
      t.datetime :processed_at, null: false

      t.timestamps
    end

    add_index :order_transition_tokens, [:order_id, :token], unique: true
  end
end
