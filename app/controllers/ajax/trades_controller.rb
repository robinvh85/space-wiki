module Ajax
  class TradesController < ActionController::Base
    
    def get_trading_list
      trade_list = BotTradeInfo.where(status: 1)

      render json: trade_list
    end

    def get_trading_history_list
      list = BotTradeHistory.where("status = 1 OR status = 2")

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

    private
    def polo_params
      params.require(:polo).permit(:note)
    end
  end
end