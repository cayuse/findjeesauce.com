# Item 6: the nightly check of every chain and delivery link we show. A link
# is hidden only after two definite misses in a row (404 / 410); a bot wall
# (403, 429) or an outage proves nothing and is "unsure".
class CreateLinkChecks < ActiveRecord::Migration[8.1]
  def change
    create_table :link_checks do |t|
      t.string :url, null: false
      t.integer :status_code
      t.string :result, null: false # ok | broken | unsure
      t.integer :misses, null: false, default: 0
      t.string :error
      t.datetime :checked_at, null: false
      t.datetime :last_ok_at
      t.timestamps
    end
    add_index :link_checks, :url, unique: true
  end
end
