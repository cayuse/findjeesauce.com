class SyncStoresJob < ApplicationJob
  queue_as :default

  def perform = StoreFeed.sync!
end
