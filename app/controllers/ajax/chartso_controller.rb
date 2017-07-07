module Ajax
  class ChartsoController < ActionController::Base
    def get_5m
      pair_id = params[:pair_id]
      pair_id = CurrencyPair.first.id if pair_id.nil? || pair_id.empty?

      start_time = (Time.now - 3.days).to_i
      end_time = Time.now.to_i
      
      list = ChartData5m.where("currency_pair_id = ? AND time_at > ? AND time_at < ?", pair_id, start_time, end_time)
      data = create_data_5m(list)

      btc_list = ChartData5m.where("currency_pair_id = 4 AND time_at > ? AND time_at < ?", start_time, end_time)
      data['btc_value'] = create_btc_data(btc_list)

      render json: data
    end

    def get_15m
      pair_id = params[:pair_id]
      pair_id = CurrencyPair.first.id if pair_id.nil? || pair_id.empty?

      start_time = (Time.now - 9.days).to_i
      end_time = Time.now.to_i
      
      list = ChartData15m.where("currency_pair_id = ? AND time_at > ? AND time_at < ?", pair_id, start_time, end_time)
      data = create_data(list)

      render json: data
    end

    def get_30m
      pair_id = params[:pair_id]
      pair_id = CurrencyPair.first.id if pair_id.nil? || pair_id.empty?

      start_time = (Time.now - 18.days).to_i
      end_time = Time.now.to_i
      
      list = ChartData30m.where("currency_pair_id = ? AND time_at > ? AND time_at < ?", pair_id, start_time, end_time)
      data = create_data(list)

      render json: data
    end

    def get_2h
      pair_id = params[:pair_id]
      pair_id = CurrencyPair.first.id if pair_id.nil? || pair_id.empty?

      start_time = (Time.now - 36.days).to_i
      end_time = Time.now.to_i
      
      list = ChartData2h.where("currency_pair_id = ? AND time_at > ? AND time_at < ?", pair_id, start_time, end_time)
      data = create_data(list)

      render json: data
    end

    def get_4h
      pair_id = params[:pair_id]
      pair_id = CurrencyPair.first.id if pair_id.nil? || pair_id.empty?

      start_time = (Time.now - 70.days).to_i
      end_time = Time.now.to_i
      
      list = ChartData4h.where("currency_pair_id = ? AND time_at > ? AND time_at < ?", pair_id, start_time, end_time)
      data = create_data(list)

      render json: data
    end

    def get_1d
      pair_id = params[:pair_id]
      pair_id = CurrencyPair.first.id if pair_id.nil? || pair_id.empty?

      start_time = (Time.now - 9.months).to_i
      end_time = Time.now.to_i
      
      list = ChartData1d.where("currency_pair_id = ? AND time_at > ? AND time_at < ?", pair_id, start_time, end_time)
      data = create_data(list)

      render json: data
    end

    private
    def create_data_5m(list)
      candle_data = []
      volume_data = []
      min_value = []

      list.each do |item|
        time_at = item.time_at * 1000
        candle_data.push([time_at, item.open.to_f, item.high.to_f, item.low.to_f, item.close.to_f])
        volume_data.push([time_at, item.volume.to_f])
        min_value.push([time_at, item.min_value.to_f])
      end

      {
        candle_data: candle_data,
        volume_data: volume_data,
        min_value: min_value,
      }
    end

    def create_data(list)
      candle_data = []
      volume_data = []
      min_value = []

      list.each do |item|
        time_at = item.time_at * 1000
        candle_data.push([time_at, item.open.to_f, item.high.to_f, item.low.to_f, item.close.to_f])
        volume_data.push([time_at, item.volume.to_f])
        min_value.push([time_at, item.min_value.to_f])
      end

      {
        candle_data: candle_data,
        volume_data: volume_data,
        min_value: min_value
      }
    end    

    def create_btc_data(list)
      btc_data = []

      list.each do |item|
        btc_data.push([item.time_at * 1000, item.min_value.to_f])
      end

      btc_data
    end
  end
end