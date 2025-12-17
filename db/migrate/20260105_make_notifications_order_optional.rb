class MakeNotificationsOrderOptional < ActiveRecord::Migration[7.1]
  def change
    change_column_null :notifications, :order_id, true
  end
end
