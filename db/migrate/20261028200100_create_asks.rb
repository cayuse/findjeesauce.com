# Item 3, "Ask your store": one row each time a shopper with no store nearby
# opens a chain's product-request page (or copies the request). Same coarse
# place as searches; no text, no IP.
class CreateAsks < ActiveRecord::Migration[8.1]
  def change
    create_table :asks do |t|
      t.string :chain, null: false # a Retailer key, or "other"
      t.string :zip
      t.decimal :lat, precision: 4, scale: 1
      t.decimal :lng, precision: 4, scale: 1
      t.string :flavor
      t.datetime :created_at, null: false
    end
    add_index :asks, :created_at
  end
end
