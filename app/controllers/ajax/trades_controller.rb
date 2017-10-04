module Ajax
  class TradesController < ActionController::Base

    def get_ico_list
      ico_list = IcoInfo.all

      render json: ico_list.to_json(
        include: [:polo_orders]
      )
    end

    def update_ico_info
      ico = IcoInfo.find(params[:ico][:id])
      ico.update(ico_info_params)

      render json: {
        status: 'OK'
      }
    end

    def get_trading_list
      trade_list = BotTradeInfo.where(is_trading: 1)

      render json: trade_list
    end

    def create_ico
      ico = IcoInfo.create(ico_info_params)

      render json: ico
    end

    def get_orders
      order_list = []

      unless params[:ico_info_id].nil?
        order_list = PoloOrder.where("ico_info_id = ? AND trading_type <> 'DONE'", params[:ico_info_id])
      end

      render json: order_list
    end

    def create_order
      order = PoloOrder.create(ico_order_params)

      render json: order
    end

    def update_order
      order = PoloOrder.find(params[:order][:id])
      order.update(ico_order_params)

      render json: order
    end

    def get_chart_data
      pair_name = params[:pair_name]
      start_time = (Time.now - 15.days).to_i

      list = ChartData30m.where("pair_name = ? AND time_at > ?", pair_name, start_time)

      data = create_data(list)

      btc_list = ChartData30m.where("pair_name = ? AND time_at > ?", 'USDT_BTC', start_time)
      data['btc_value'] = create_btc_data(btc_list)

      render json: data
    end    

    def get_trading_history_list
      list = BotTradeHistory.where("status >= 1 AND status <= 4").order(buy_at: 'ASC')

      render json: list
    end

    def get_traing_history_logs
      if params[:bot_trade_history_id].present?
        list = BotTradeLog.where("bot_trade_history_id = ?", params[:bot_trade_history_id]).order(created_at: 'DESC')
      else
        list = BotTradeLog.where("").order(created_at: 'DESC').take(50)
      end
      render json: list
    end

    def cancel_trade
      obj = BotTradeHistory.find(params[:bot_trade_history_id])
      obj.status = -1
      obj.save!

      render json: {
        status: 1
      }
    end

    def force_buy
      obj = BotTradeHistory.find(params[:bot_trade_history_id])
      obj.status = 3
      obj.save!

      render json: {
        status: 1
      }
    end

    def force_sell
      obj = BotTradeHistory.find(params[:bot_trade_history_id])
      obj.status = 4
      obj.save!

      render json: {
        status: 1
      }
    end

    private
    def polo_params
      params.require(:polo).permit(:note)
    end

    def ico_info_params
      params.require(:ico).permit(:pair_name, :resistance_price, :support_price, :is_auto, :support_profit, :resistance_profit)
    end

    def ico_order_params
      params.require(:order).permit(:pair_name, :trading_type, :amount_usd, :buy_price, :sell_price, :ico_info_id, :limit_sell_percent)
    end

    def create_data(list)
      candle_data = []
      # volume_data = []

      list.each do |item|
        time_at = item.time_at * 1000
        candle_data.push([time_at, item.open.to_f, item.high.to_f, item.low.to_f, item.close.to_f])
        # volume_data.push([time_at, item.volume.to_f])
      end

      {
        candle_data: candle_data
        # volume_data: volume_data,
      }
    end

    def create_btc_data(list)
      btc_data = []

      list.each do |item|
        btc_data.push([item.time_at * 1000, item.low.to_f])
      end

      btc_data
    end
  end
end