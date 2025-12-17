class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.references :farmer, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :price, null: false, default: 0
      t.string :category, null: false, default: "기타"
      t.integer :stock_quantity, null: false, default: 0
      t.string :stock_status, null: false, default: "available"
      t.integer :max_per_order, null: false, default: 0
      t.string :sku, null: false

      t.timestamps
    end

    add_index :products, :sku, unique: true
    add_index :products, :category
    add_index :products, :stock_status
  end
end
