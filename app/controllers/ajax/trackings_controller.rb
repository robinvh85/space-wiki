module Ajax
  class TrackingsController < ActionController::Base
    
    def get_tracking_price_list
      list = TrackingPrice.where("").sort(created_at: 'DESC').take(50)

      render json: list
    end

  end
end