class AddAdminOtpSupport < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_otp_verified_at, :datetime

    create_table :admin_otp_challenges do |t|
      t.references :user, null: false, foreign_key: true
      t.string :code, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.string :purpose, null: false, default: "admin_login"

      t.timestamps
    end

    add_index :admin_otp_challenges, [:user_id, :code]
    add_index :admin_otp_challenges, :expires_at
  end
end
