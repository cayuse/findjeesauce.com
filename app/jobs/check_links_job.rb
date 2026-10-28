# Nightly: check every outside link the finder shows (LinkCheck).
class CheckLinksJob < ApplicationJob
  queue_as :default

  def perform = LinkCheck.run!
end
