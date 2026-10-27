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

ActiveRecord::Schema[8.1].define(version: 2026_10_27_220000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
