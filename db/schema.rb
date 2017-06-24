# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170623094714) do

  create_table "chart_data15ms", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "currency_pair_id"
    t.datetime "date_time"
    t.bigint   "time_at"
    t.decimal  "high",             precision: 16, scale: 8
    t.decimal  "low",              precision: 16, scale: 8
    t.decimal  "open",             precision: 16, scale: 8
    t.decimal  "close",            precision: 16, scale: 8
    t.decimal  "volume",           precision: 16, scale: 8
    t.decimal  "quote_volume",     precision: 16, scale: 8
    t.decimal  "weighted_average", precision: 16, scale: 8
    t.index ["currency_pair_id", "time_at"], name: "idx_pair_time_at", unique: true, using: :btree
  end

  create_table "chart_data1ds", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "currency_pair_id"
    t.datetime "date_time"
    t.bigint   "time_at"
    t.decimal  "high",             precision: 16, scale: 8
    t.decimal  "low",              precision: 16, scale: 8
    t.decimal  "open",             precision: 16, scale: 8
    t.decimal  "close",            precision: 16, scale: 8
    t.decimal  "volume",           precision: 16, scale: 8
    t.decimal  "quote_volume",     precision: 16, scale: 8
    t.decimal  "weighted_average", precision: 16, scale: 8
    t.index ["currency_pair_id", "time_at"], name: "idx_pair_time_at", unique: true, using: :btree
  end

  create_table "chart_data2hs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "currency_pair_id"
    t.datetime "date_time"
    t.bigint   "time_at"
    t.decimal  "high",             precision: 16, scale: 8
    t.decimal  "low",              precision: 16, scale: 8
    t.decimal  "open",             precision: 16, scale: 8
    t.decimal  "close",            precision: 16, scale: 8
    t.decimal  "volume",           precision: 16, scale: 8
    t.decimal  "quote_volume",     precision: 16, scale: 8
    t.decimal  "weighted_average", precision: 16, scale: 8
    t.index ["currency_pair_id", "time_at"], name: "idx_pair_time_at", unique: true, using: :btree
  end

  create_table "chart_data30ms", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "currency_pair_id"
    t.datetime "date_time"
    t.bigint   "time_at"
    t.decimal  "high",             precision: 16, scale: 8
    t.decimal  "low",              precision: 16, scale: 8
    t.decimal  "open",             precision: 16, scale: 8
    t.decimal  "close",            precision: 16, scale: 8
    t.decimal  "volume",           precision: 16, scale: 8
    t.decimal  "quote_volume",     precision: 16, scale: 8
    t.decimal  "weighted_average", precision: 16, scale: 8
    t.index ["currency_pair_id", "time_at"], name: "idx_pair_time_at", unique: true, using: :btree
  end

  create_table "chart_data4hs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "currency_pair_id"
    t.datetime "date_time"
    t.bigint   "time_at"
    t.decimal  "high",             precision: 16, scale: 8
    t.decimal  "low",              precision: 16, scale: 8
    t.decimal  "open",             precision: 16, scale: 8
    t.decimal  "close",            precision: 16, scale: 8
    t.decimal  "volume",           precision: 16, scale: 8
    t.decimal  "quote_volume",     precision: 16, scale: 8
    t.decimal  "weighted_average", precision: 16, scale: 8
    t.index ["currency_pair_id", "time_at"], name: "idx_pair_time_at", unique: true, using: :btree
  end

  create_table "chart_data5ms", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "currency_pair_id"
    t.datetime "date_time"
    t.bigint   "time_at"
    t.decimal  "high",             precision: 16, scale: 8
    t.decimal  "low",              precision: 16, scale: 8
    t.decimal  "open",             precision: 16, scale: 8
    t.decimal  "close",            precision: 16, scale: 8
    t.decimal  "volume",           precision: 16, scale: 8
    t.decimal  "quote_volume",     precision: 16, scale: 8
    t.decimal  "weighted_average", precision: 16, scale: 8
    t.index ["currency_pair_id", "time_at"], name: "idx_pair_time_at", unique: true, using: :btree
  end

  create_table "currency_pairs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
  end

  create_table "current_orders", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "currency_pair"
    t.string   "method"
    t.string   "price",            limit: 16
    t.string   "amount",           limit: 16
    t.string   "total_price",      limit: 16
    t.string   "accumulate_price", limit: 16
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "galleries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "topic_id"
    t.index ["topic_id"], name: "index_galleries_on_topic_id", using: :btree
  end

  create_table "tags", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "topic_tags", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "topic_id"
    t.integer  "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "topics", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "title"
    t.text     "content",    limit: 65535
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "parent_id",                default: 0
    t.integer  "level",                    default: 0
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  add_foreign_key "galleries", "topics", name: "galleries_ibfk_1"
end
