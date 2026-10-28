# Item 5: the last date a distributor delivered JeeSauce to the store, when
# rep's feed carries it (rep gets it from jeedata). Blank until then.
class AddLastDeliveredOnToStores < ActiveRecord::Migration[8.1]
  def change
    add_column :stores, :last_delivered_on, :date
  end
end
