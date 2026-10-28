# Item 4, the demand map: one row per finder search, to show buyers where
# people look for JeeSauce and come up empty. Kept coarse on purpose: a ZIP
# if one was typed and the point rounded to 0.1° (about 7 miles). No search
# text, no IP, nothing to identify a shopper.
class CreateSearches < ActiveRecord::Migration[8.1]
  def change
    create_table :searches do |t|
      t.string :zip
      t.decimal :lat, precision: 4, scale: 1
      t.decimal :lng, precision: 4, scale: 1
      t.string :state
      t.string :flavor
      t.integer :nearby_count, null: false  # stores within Store::DEFAULT_RADIUS_MILES
      t.integer :carrier_count               # of those, ones listing the flavor (flavor searches)
      t.integer :nearest_miles
      t.datetime :created_at, null: false
    end
    add_index :searches, :created_at
    add_index :searches, %i[lat lng]
  end
end
