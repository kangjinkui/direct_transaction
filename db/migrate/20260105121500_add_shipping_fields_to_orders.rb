class AddShippingFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :shipping_name, :string, null: false, default: "" unless column_exists?(:orders, :shipping_name)
    add_column :orders, :shipping_phone, :string, null: false, default: "" unless column_exists?(:orders, :shipping_phone)
    add_column :orders, :shipping_address, :string, null: false, default: "" unless column_exists?(:orders, :shipping_address)
    add_column :orders, :shipping_zip_code, :string unless column_exists?(:orders, :shipping_zip_code)
    add_column :orders, :delivery_memo, :text unless column_exists?(:orders, :delivery_memo)
  end
end
