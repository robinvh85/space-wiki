module Ajax
  class IcoOrdersController < ActionController::Base
    def cancel_sell
      order = IcoOrder.find_by(sell_order_id: params['sell_order_id'])
      bot = IcoBot.find_by(ico_order_id: order.id)
      bot.trading_type = 'CANCEL_SELL'
      bot.save

      render json: {
        success: 'OK'
      }
    end

    def cancel_buy
      order = IcoOrder.find_by(buy_order_id: params['buy_order_id'])
      bot = IcoBot.find_by(ico_order_id: order.id)
      bot.trading_type = 'CANCEL_BUY'
      bot.save

      render json: {
        success: 'OK'
      }
    end

    def get_bot_list
      if params[:is_all] == "true"
        bot_list = IcoBot.where('')
      else
        bot_list = IcoBot.where('status <> -1')
      end

      bot_list.each do |bot|
        if bot.ico_order.nil?
          bot.ico_order = IcoOrder.new
        end
      end

      render json: bot_list.to_json(
        :include => [:ico_order]
      )
    end

    def update_bot
      bot = IcoBot.find(params[:bot][:id])
      bot.update(bot_info_params)

      render json: {
        status: 'OK'
      }
    end

    private

    def bot_info_params
      params.require(:bot).permit(:amount, :sell_price, :buy_price, :status, :trading_type, :limit_price_for_buy)
    end
  end
end