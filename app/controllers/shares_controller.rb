# POST /stores/:store_id/shares: someone pressed a share button. Answers with
# the new totals for the counter. No session or form here (it's a counter
# bumped from plain pages and the jeesauce.com frame), so no CSRF token; the
# rate limit keeps one person from running the number up.
class SharesController < ApplicationController
  skip_forgery_protection
  rate_limit to: 20, within: 1.hour, by: -> { request.remote_ip },
             with: -> { render json: { count: Share.count }, status: :too_many_requests }

  def create
    store = Store.find_by_param!(params[:store_id])
    share = Share.new(store_rep_id: store.rep_id, channel: params[:channel])
    return head(:unprocessable_content) unless share.save

    render json: { count: Share.count, store_count: Share.for_store(store).count }
  end
end
