class AddStatusChangeTrackingToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :last_status_changed_at, :datetime
    add_column :orders, :last_status_changed_by_id, :bigint
    add_column :orders, :last_status_changed_by_type, :string
    add_index :orders, %i[last_status_changed_by_type last_status_changed_by_id], name: "index_orders_on_last_status_changed_by"
  end
end
