# Which buy buttons get used: one row per click out to a retailer, delivery
# app, jeesauce.com or directions. Where it went, from which store page, the
# flavor chosen. No IP, nothing about the shopper.
class CreateClicks < ActiveRecord::Migration[8.1]
  def change
    create_table :clicks do |t|
      t.string :kind, null: false   # chain | delivery | dtc | directions
      t.string :target, null: false # H-E-B, Instacart, jeesauce.com, …
      t.bigint :store_rep_id
      t.string :flavor
      t.string :spot                # utm_content for jeesauce.com links
      t.datetime :created_at, null: false
    end
    add_index :clicks, :created_at
    add_index :clicks, %i[target store_rep_id]
  end
end
