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
      bot_list = IcoBot.where('status <> -1')

      bot_list.each do |bot|
        if bot.ico_order.nil?
          bot.ico_order = IcoOrder.new
        end
      end

      render json: bot_list.to_json(
        :include => [:ico_order, :ico_info, :ico_invest]
      )
    end

    def update_bot
      bot = IcoBot.find(params[:bot][:id])
      bot.update(bot_info_params)

      # binding.pry
      bot_invest = IcoInvest.find_by(ico_info_id: params[:bot][:ico_info_id])
      bot_invest.last_order_price = (params[:bot][:sell_price]).to_f
      bot_invest.save

      render json: {
        status: 'OK'
      }
    end

    private

    def bot_info_params
      params.require(:bot).permit(:amount, :sell_price, :buy_price, :status)
    end
  end
end