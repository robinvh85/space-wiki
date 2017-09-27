module Ajax
  class TradesController < ActionController::Base

    def get_ico_list
      ico_list = IcoInfo.all

      render json: ico_list
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

    def get_order
      order = {}

      unless params[:polo_order_id].nil?
        order = PoloOrder.find(params[:polo_order_id])
      end

      render json: order
    end

    def create_order
      order = PoloOrder.create(ico_order_params)

      ico = IcoInfo.find_by(pair_name: order.pair_name)
      ico.polo_order_id = order.id
      ico.save

      render json: order
    end

    def update_order
      order = PoloOrder.find(params[:order][:id])
      order.update(ico_order_params)

      render json: order
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
      params.require(:order).permit(:pair_name, :trading_type, :amount_usd, :buy_price, :sell_price)
    end
  end
end