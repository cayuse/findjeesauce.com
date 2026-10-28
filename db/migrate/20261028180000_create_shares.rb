# One row each time someone shares a store (copy link, text, email, the
# phone's share sheet): the "Spread the love" counter. Counts the button
# press; we never learn or keep who it went to. Keyed by rep's store id, so
# it survives a feed rebuild of stores.
class CreateShares < ActiveRecord::Migration[8.1]
  def change
    create_table :shares do |t|
      t.bigint :store_rep_id, null: false
      t.string :channel, null: false # copy | text | email | native
      t.datetime :created_at, null: false
    end
    add_index :shares, :store_rep_id
  end
end
