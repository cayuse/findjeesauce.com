# Our copy of rep's store feed (GET /api/v1/stores). Rep is the source of
# truth; this table is rebuilt from the feed by StoreFeed.sync! and nothing
# else writes it. rep_id is rep's opaque store id.
class CreateStores < ActiveRecord::Migration[8.1]
  def change
    create_table :stores do |t|
      t.bigint :rep_id, null: false
      t.string :name, null: false
      t.string :chain
      t.string :street
      t.string :street2
      t.string :city
      t.string :state
      t.string :zip
      t.decimal :lat, precision: 9, scale: 6
      t.decimal :lng, precision: 9, scale: 6
      t.string :flavors, array: true, null: false, default: []
      t.datetime :rep_updated_at
      t.timestamps
    end
    add_index :stores, :rep_id, unique: true
    add_index :stores, :zip
    add_index :stores, %i[state city]

    # One row per sync attempt: what rep said, and whether we took it.
    create_table :sync_runs do |t|
      t.string :status, null: false # ok | not_modified | failed | refused
      t.integer :stores_count
      t.string :etag
      t.datetime :feed_as_of
      t.datetime :token_expires_at
      t.text :error
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.timestamps
    end
    add_index :sync_runs, :started_at
  end
end
