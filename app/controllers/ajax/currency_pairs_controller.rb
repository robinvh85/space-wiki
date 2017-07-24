module Ajax
  class CurrencyPairsController < ActionController::Base
    def index

      @base_unit = params[:base_unit]
		  @base_unit = 'BTC' if @base_unit.nil? || @base_unit.empty?

      if params['all'] == 1
        @all_currency_pairs = CurrencyPair.where(base_unit: @base_unit).order(percent_min_24h: 'asc')
      else
        @all_currency_pairs = CurrencyPair.where(base_unit: @base_unit, is_disabled: 0).order(percent_min_24h: 'asc')
      end

      # render json: CurrencyPair.where(is_tracking: 1).order(sort: 'asc')
      render json: @all_currency_pairs
    end

    def update
      pair = CurrencyPair.find(params[:id])
      pair.is_tracking = params[:is_tracking]
      pair.save
      render json: {
        status: 'OK'
      }
    end
    
    def update_note
      pair = CurrencyPair.find(params[:id])
      pair.note = params[:note]
      pair.save
      render json: {
        status: 'OK'
      }
    end  

    def get_current_price      
      obj = IcoInfo.find_by(currency_pair_name: "USDT_BTC")

      render json: {
        current_buy: obj.current_buy_price,
        current_sell: obj.current_sell_price
      }
    end

  end
end