module Ajax
  class CurrencyPairsController < ActionController::Base
    def index
      render json: CurrencyPair.all
    end
  end
end