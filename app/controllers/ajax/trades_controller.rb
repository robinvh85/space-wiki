module Ajax
  class TradesController < ActionController::Base
    
    def get_trading_list
      trade_list = BotTradeInfo.where(status: 1)

      render json: trade_list
    end

    def get_trading_history_list
      list = BotTradeHistory.where("sell_at IS NULL")

      render json: list
    end

    def get_traing_history_logs
      list = BotTradeLog.where("bot_trade_history_id = ?", params[:bot_trade_history_id]).order(created_at: 'DESC')
      render json: list
    end

    private
    def polo_params
      params.require(:polo).permit(:note)
    end
  end
end