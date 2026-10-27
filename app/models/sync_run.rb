class SyncRun < ApplicationRecord
  STATUSES = %w[ok not_modified failed refused].freeze
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(started_at: :desc) }

  def self.last_good = where(status: %w[ok not_modified]).recent.first
end
