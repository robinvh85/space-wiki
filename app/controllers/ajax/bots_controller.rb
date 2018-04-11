module Ajax
  class BotsController < ActionController::Base
    
    def create
      bot = IcoBot.create(bot_params)

      render json: bot
    end

    def update
      bot = IcoBot.find(params[:bot][:id])
      bot.update(bot_params)

      render json: {
        status: 'OK'
      }
    end

    private
    def bot_params
      params.require(:bot).permit(:amount_usd, :limit_amount_check_price, :limit_cancel_for_lose_percent, :force_sell_percent, :default_sell_price_percent, :pair_name, :ico_name, :ico_account_id, :status)
    end
  end
end