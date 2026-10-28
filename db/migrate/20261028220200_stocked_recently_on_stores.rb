# The public shelf signal replaces the delivery date [Joel, 2026-10-28: show
# "In stock: November", never "delivered 8/28", which reads as old product].
# Rep decides from its evidence (jeedata: HEB scans in the last 4 weeks, or a
# KeHE / UNFI order in the last 6) and sends only true / false.
class StockedRecentlyOnStores < ActiveRecord::Migration[8.1]
  def change
    remove_column :stores, :last_delivered_on, :date
    add_column :stores, :stocked_recently, :boolean, null: false, default: false
  end
end
