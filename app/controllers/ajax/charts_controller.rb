module Ajax
  class ChartsController < ActionController::Base
    def index
      pair_id = params[:pair_id]
      pair_id = CurrencyPair.first.id if pair_id.nil? || pair_id.empty?

      start_time = (Time.now - 3.days).to_i
      end_time = Time.now.to_i
      
      list = ChartData5m.where("currency_pair_id = ? AND time_at > ? AND time_at < ?", pair_id, start_time, end_time)

      data = []
      list.each do |item|
        data.push([item.time_at * 1000, item.open.to_f, item.high.to_f, item.low.to_f, item.close.to_f])
      end

      render json: data
    end
  end
end