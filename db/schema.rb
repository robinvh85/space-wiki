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

ActiveRecord::Schema.define(version: 20170712031648) do

  create_table "bot_trade_histories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "currency_pair_id"
    t.string   "currency_pair_name"
    t.string   "trade_type"
    t.decimal  "amount",                        precision: 16, scale: 8
    t.decimal  "price",                         precision: 16, scale: 8
    t.float    "profit",             limit: 24
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
  end

  create_table "bot_trade_infos", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "currency_pair_id"
    t.string   "currency_pair_name"
    t.decimal  "buy_amount",                        precision: 16, scale: 8
    t.float    "limit_invert_when_buy",  limit: 24
    t.float    "limit_invert_when_sell", limit: 24
    t.float    "limit_good_profit",      limit: 24
    t.float    "limit_losses_profit",    limit: 24
    t.integer  "interval_time"
    t.integer  "limit_verify_times"
    t.integer  "delay_time_after_sold"
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
  end

  create_table "bot_trade_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "currency_pair_id"
    t.string   "currency_pair_name"
    t.string   "trade_type"
    t.decimal  "ceil_price",                    precision: 16, scale: 8
    t.decimal  "floor_price",                   precision: 16, scale: 8
    t.decimal  "previous_price",                precision: 16, scale: 8
    t.decimal  "current_price",                 precision: 16, scale: 8
    t.float    "profit",             limit: 24
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
  end

  create_table "chart_data", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
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

  create_table "chart_data15ms", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "currency_pair_id"
    t.datetime "date_time"
    t.bigint   "time_at"
    t.decimal  "high",             precision: 16, scale: 8
    t.decimal  "low",              precision: 16, scale: 8
    t.decimal  "open",             precision: 16, scale: 8
    t.decimal  "close",            precision: 16, scale: 8
    t.decimal  "volume",           precision: 16, scale: 8
    t.decimal  "quote_volume",     precision: 18, scale: 8
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
    t.decimal  "volume",           precision: 17, scale: 8
    t.decimal  "quote_volume",     precision: 20, scale: 8
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
    t.decimal  "quote_volume",     precision: 17, scale: 8
    t.decimal  "weighted_average", precision: 16, scale: 8
    t.decimal  "min_value",        precision: 16, scale: 8
    t.decimal  "avg_12h_value",    precision: 16, scale: 8
    t.decimal  "avg_24h_value",    precision: 16, scale: 8
    t.integer  "increase"
    t.integer  "predict_1h"
    t.integer  "predict_2h"
    t.integer  "predict_4h"
    t.index ["currency_pair_id", "time_at"], name: "idx_pair_time_at", unique: true, using: :btree
  end

  create_table "chart_data5ms_bk", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
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
    t.string  "name"
    t.integer "is_init",         limit: 1
    t.integer "sort"
    t.string  "base_unit"
    t.integer "is_tracking",     limit: 1,                             default: 0, null: false
    t.decimal "percent_min_24h",               precision: 5, scale: 2
    t.text    "note",            limit: 65535
    t.integer "is_disabled",                                           default: 0
  end

  create_table "current_orders", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "currency_pair"
    t.string   "method"
    t.string   "price"
    t.string   "amount"
    t.string   "total_price"
    t.string   "accumulate_price"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "galleries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "topic_id"
    t.index ["topic_id"], name: "index_galleries_on_topic_id", using: :btree
  end

  create_table "open_orders", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "order_number"
    t.decimal  "margin",          precision: 16, scale: 8
    t.decimal  "amount",          precision: 16, scale: 8
    t.decimal  "price",           precision: 16, scale: 8
    t.decimal  "total",           precision: 16, scale: 8
    t.decimal  "starting_amount", precision: 16, scale: 8
    t.datetime "date_time"
  end

  create_table "polos", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "note"
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

  create_table "trade_histories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "category"
    t.string   "trade_id"
    t.string   "order_number"
    t.string   "trade_type"
    t.decimal  "fee",          precision: 16, scale: 8
    t.decimal  "amount",       precision: 20, scale: 8
    t.decimal  "rate",         precision: 16, scale: 8
    t.decimal  "total",        precision: 16, scale: 8
    t.datetime "date_time"
    t.integer  "is_sell"
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
