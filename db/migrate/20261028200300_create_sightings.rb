# Item 7, "I found it!": a shopper says JeeSauce is on this store's shelf,
# optionally with a photo. Photos are JPEG only, shrunk in the browser and
# stripped of metadata (GPS included) on the way in, kept here (not on disk:
# no volume to back up), and never shown until someone approves them.
class CreateSightings < ActiveRecord::Migration[8.1]
  def change
    create_table :sightings do |t|
      t.bigint :store_rep_id, null: false
      t.string :flavor
      t.binary :photo
      t.string :photo_status, null: false, default: "none" # none | pending | approved | rejected
      t.datetime :reviewed_at
      t.datetime :created_at, null: false
    end
    add_index :sightings, %i[store_rep_id created_at]
    add_index :sightings, :photo_status
  end
end
