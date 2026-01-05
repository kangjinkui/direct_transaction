# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_01_05_121500) do
  create_table "admin_otp_challenges", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "code", null: false
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.string "purpose", default: "admin_login", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_admin_otp_challenges_on_expires_at"
    t.index ["user_id", "code"], name: "index_admin_otp_challenges_on_user_id_and_code"
    t.index ["user_id"], name: "index_admin_otp_challenges_on_user_id"
  end

  create_table "cart_items", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_cart_items_on_product_id"
    t.index ["user_id", "product_id"], name: "index_cart_items_on_user_id_and_product_id", unique: true
    t.index ["user_id"], name: "index_cart_items_on_user_id"
  end

  create_table "farmers", force: :cascade do |t|
    t.string "business_name", null: false
    t.string "owner_name", null: false
    t.string "phone", null: false
    t.text "account_info_enc", default: "", null: false
    t.string "farmer_type", default: "a", null: false
    t.string "notification_method", default: "kakao", null: false
    t.string "pin_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "approval_mode", default: "manual", null: false
    t.integer "stock_quantity", default: 0, null: false
    t.text "encrypted_account_info", default: "", null: false
    t.string "encrypted_account_info_iv", default: "", null: false
    t.index ["approval_mode"], name: "index_farmers_on_approval_mode"
    t.index ["farmer_type"], name: "index_farmers_on_farmer_type"
    t.index ["phone"], name: "index_farmers_on_phone", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "order_id"
    t.integer "farmer_id", null: false
    t.string "notification_type", null: false
    t.string "channel", default: "kakao", null: false
    t.string "status", default: "pending", null: false
    t.string "token_jti"
    t.datetime "used_at"
    t.datetime "expires_at"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel"], name: "index_notifications_on_channel"
    t.index ["farmer_id"], name: "index_notifications_on_farmer_id"
    t.index ["order_id"], name: "index_notifications_on_order_id"
    t.index ["status"], name: "index_notifications_on_status"
    t.index ["token_jti"], name: "index_notifications_on_token_jti", unique: true
  end

  create_table "order_approval_tokens", force: :cascade do |t|
    t.integer "order_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.string "purpose", default: "farmer_approval", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_order_approval_tokens_on_expires_at"
    t.index ["order_id"], name: "index_order_approval_tokens_on_order_id"
    t.index ["token"], name: "index_order_approval_tokens_on_token", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "price", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "product_id"], name: "index_order_items_on_order_id_and_product_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "order_transition_tokens", force: :cascade do |t|
    t.integer "order_id", null: false
    t.string "token", null: false
    t.datetime "processed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "token"], name: "index_order_transition_tokens_on_order_id_and_token", unique: true
    t.index ["order_id"], name: "index_order_transition_tokens_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "farmer_id", null: false
    t.integer "total_amount", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.string "order_number", null: false
    t.datetime "confirmed_at"
    t.datetime "paid_at"
    t.datetime "completed_at"
    t.datetime "cancelled_at"
    t.string "rejection_reason"
    t.json "policy_snapshot", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "status_history", default: [], null: false
    t.datetime "timeout_at"
    t.datetime "last_status_changed_at"
    t.bigint "last_status_changed_by_id"
    t.string "last_status_changed_by_type"
    t.string "shipping_name", default: "", null: false
    t.string "shipping_phone", default: "", null: false
    t.string "shipping_address", default: "", null: false
    t.string "shipping_zip_code"
    t.text "delivery_memo"
    t.index ["farmer_id"], name: "index_orders_on_farmer_id"
    t.index ["last_status_changed_by_type", "last_status_changed_by_id"], name: "index_orders_on_last_status_changed_by"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["status"], name: "index_orders_on_status"
    t.index ["timeout_at"], name: "index_orders_on_timeout_at"
    t.index ["user_id", "status"], name: "index_orders_on_user_id_and_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "order_id", null: false
    t.string "payment_method", default: "manual_transfer", null: false
    t.integer "amount", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.string "reference"
    t.datetime "verified_at"
    t.string "evidence_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "admin_note"
    t.string "verification_method"
    t.index ["order_id"], name: "index_payments_on_order_id"
    t.index ["reference"], name: "index_payments_on_reference"
    t.index ["status"], name: "index_payments_on_status"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.integer "farmer_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "price", default: 0, null: false
    t.string "category", default: "기타", null: false
    t.integer "stock_quantity", default: 0, null: false
    t.string "stock_status", default: "available", null: false
    t.integer "max_per_order", default: 0, null: false
    t.string "sku", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_available", default: true, null: false
    t.index ["category"], name: "index_products_on_category"
    t.index ["farmer_id"], name: "index_products_on_farmer_id"
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["stock_status"], name: "index_products_on_stock_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "phone"
    t.string "address"
    t.string "oauth_provider"
    t.string "oauth_uid"
    t.string "role", default: "user", null: false
    t.string "mfa_secret"
    t.datetime "last_login_at"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_otp_verified_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["oauth_provider", "oauth_uid"], name: "index_users_on_oauth_provider_and_oauth_uid", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "admin_otp_challenges", "users"
  add_foreign_key "cart_items", "products"
  add_foreign_key "cart_items", "users"
  add_foreign_key "notifications", "farmers"
  add_foreign_key "notifications", "orders"
  add_foreign_key "order_approval_tokens", "orders"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_transition_tokens", "orders"
  add_foreign_key "orders", "farmers"
  add_foreign_key "orders", "users"
  add_foreign_key "payments", "orders"
  add_foreign_key "products", "farmers"
end
