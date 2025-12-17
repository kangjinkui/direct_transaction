class CreateFarmers < ActiveRecord::Migration[8.0]
  def change
    create_table :farmers do |t|
      t.string :business_name, null: false
      t.string :owner_name, null: false
      t.string :phone, null: false
      t.text :account_info_enc, null: false, default: ""
      t.string :farmer_type, null: false, default: "a"
      t.string :notification_method, null: false, default: "kakao"
      t.string :pin_digest

      t.timestamps
    end

    add_index :farmers, :phone, unique: true
    add_index :farmers, :farmer_type
  end
end
