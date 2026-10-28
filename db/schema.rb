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

ActiveRecord::Schema[8.1].define(version: 2026_10_28_200400) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "asks", force: :cascade do |t|
    t.string "chain", null: false
    t.string "zip"
    t.decimal "lat", precision: 4, scale: 1
    t.decimal "lng", precision: 4, scale: 1
    t.string "flavor"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_asks_on_created_at"
  end

  create_table "link_checks", force: :cascade do |t|
    t.string "url", null: false
    t.integer "status_code"
    t.string "result", null: false
    t.integer "misses", default: 0, null: false
    t.string "error"
    t.datetime "checked_at", null: false
    t.datetime "last_ok_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["url"], name: "index_link_checks_on_url", unique: true
  end

  create_table "searches", force: :cascade do |t|
    t.string "zip"
    t.decimal "lat", precision: 4, scale: 1
    t.decimal "lng", precision: 4, scale: 1
    t.string "state"
    t.string "flavor"
    t.integer "nearby_count", null: false
    t.integer "carrier_count"
    t.integer "nearest_miles"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_searches_on_created_at"
    t.index ["lat", "lng"], name: "index_searches_on_lat_and_lng"
  end

  create_table "shares", force: :cascade do |t|
    t.bigint "store_rep_id", null: false
    t.string "channel", null: false
    t.datetime "created_at", null: false
    t.index ["store_rep_id"], name: "index_shares_on_store_rep_id"
  end

  create_table "sightings", force: :cascade do |t|
    t.bigint "store_rep_id", null: false
    t.string "flavor"
    t.binary "photo"
    t.string "photo_status", default: "none", null: false
    t.datetime "reviewed_at"
    t.datetime "created_at", null: false
    t.index ["photo_status"], name: "index_sightings_on_photo_status"
    t.index ["store_rep_id", "created_at"], name: "index_sightings_on_store_rep_id_and_created_at"
  end

  create_table "stores", force: :cascade do |t|
    t.bigint "rep_id", null: false
    t.string "name", null: false
    t.string "chain"
    t.string "street"
    t.string "street2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.decimal "lat", precision: 9, scale: 6
    t.decimal "lng", precision: 9, scale: 6
    t.string "flavors", default: [], null: false, array: true
    t.datetime "rep_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "last_delivered_on"
    t.index ["rep_id"], name: "index_stores_on_rep_id", unique: true
    t.index ["state", "city"], name: "index_stores_on_state_and_city"
    t.index ["zip"], name: "index_stores_on_zip"
  end

  create_table "sync_runs", force: :cascade do |t|
    t.string "status", null: false
    t.integer "stores_count"
    t.string "etag"
    t.datetime "feed_as_of"
    t.datetime "token_expires_at"
    t.text "error"
    t.datetime "started_at", null: false
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["started_at"], name: "index_sync_runs_on_started_at"
  end
end
