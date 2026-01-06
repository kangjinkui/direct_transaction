class AddAdminNoteToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :admin_note, :text
    add_column :orders, :admin_note_history, :json, default: [], null: false
    add_column :orders, :admin_note_updated_at, :datetime
  end
end
