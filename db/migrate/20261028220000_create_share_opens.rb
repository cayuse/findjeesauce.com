# "Love landed": a friend opened a shared store link. One row per open of a
# ?shared=1 link: store, the channel it was sent by (?via=), time. No IP, no
# visitor id; robots skipped.
class CreateShareOpens < ActiveRecord::Migration[8.1]
  def change
    create_table :share_opens do |t|
      t.bigint :store_rep_id, null: false
      t.string :channel, null: false # text | email | whatsapp | link | sheet | unknown
      t.datetime :created_at, null: false
    end
    add_index :share_opens, :created_at
  end
end
