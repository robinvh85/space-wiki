module Ajax
  class CurrencyPairsController < ActionController::Base
    def index
      render json: CurrencyPair.all
    end

    def update
      pair = CurrencyPair.find(params[:id])
      pair.is_tracking = params[:is_tracking]
      pair.save
      render json: {
        status: 'OK'
      }
    end
    
  end
end