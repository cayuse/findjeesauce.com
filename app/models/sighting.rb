# "I found it!": a shopper saw JeeSauce on this store's shelf (item 7). An
# optional photo waits for approval before anyone sees it. See the migration.
class Sighting < ApplicationRecord
  MAX_PHOTO_BYTES = 3.megabytes
  SHOW_DAYS = 90 # older sightings say nothing about the shelf today

  validates :store_rep_id, presence: true
  validates :photo_status, inclusion: { in: %w[none pending approved rejected] }
  validate :flavor_known
  validate { errors.add(:photo, @photo_error) if @photo_error }

  scope :for_store, ->(store) { where(store_rep_id: store.rep_id) }
  scope :fresh, -> { where(created_at: SHOW_DAYS.days.ago..) }
  scope :pending, -> { where(photo_status: "pending").order(:created_at) }
  scope :approved, -> { where(photo_status: "approved").order(created_at: :desc) }

  # Attach an uploaded photo: JPEG only (the page converts phone photos to
  # JPEG first), metadata removed. Anything else fails validation.
  def photo_upload=(upload)
    return if upload.blank?

    bytes = upload.read(MAX_PHOTO_BYTES + 1)
    if bytes.bytesize > MAX_PHOTO_BYTES
      @photo_error = "is too big"
    elsif !(clean = Jpeg.strip(bytes))
      @photo_error = "must be a JPEG"
    else
      self.photo = clean
      self.photo_status = "pending"
    end
  end

  def approve! = update!(photo_status: "approved", reviewed_at: Time.current)
  def reject! = update!(photo_status: "rejected", photo: nil, reviewed_at: Time.current)

  # { rep_id => newest sighting time } for a page of stores, in one query.
  def self.latest_for(stores)
    fresh.where(store_rep_id: stores.map(&:rep_id)).group(:store_rep_id).maximum(:created_at)
  end

  private

  def flavor_known
    errors.add(:flavor, "isn't one of ours") if flavor.present? && !Flavor.named(flavor)
  end
end
