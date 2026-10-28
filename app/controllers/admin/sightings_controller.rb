# Photo approvals: nothing a shopper uploads shows until it's approved here.
class Admin::SightingsController < Admin::BaseController
  def index
    @sightings = Sighting.pending.select(:id, :store_rep_id, :flavor, :created_at).limit(50) # photos load one by one
    @stores = Store.where(rep_id: @sightings.map(&:store_rep_id)).index_by(&:rep_id)
  end

  # The pending photo itself, for review.
  def photo
    send_data Sighting.find(params[:id]).photo, type: "image/jpeg", disposition: "inline"
  end

  def approve
    Sighting.find(params[:id]).approve!
    redirect_to admin_sightings_path, status: :see_other
  end

  def reject
    Sighting.find(params[:id]).reject!
    redirect_to admin_sightings_path, status: :see_other
  end
end
