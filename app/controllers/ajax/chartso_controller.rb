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

    def get_5m_predict
      pair_id = params[:pair_id]
      date = params[:date]
      step_percent = params[:step_percent] || 0.04

      date_time = DateTime.strptime(date, '%Y/%m/%d')

      pair_id = CurrencyPair.find_by(name: 'USDT_BTC') unless pair_id.present?

      start_time = (date_time - 1.days).to_i
      end_time = (date_time + 1.days).to_i
      
      list = ChartData5m.where("currency_pair_id = ? AND time_at > ? AND time_at < ?", pair_id, start_time, end_time)
      data = create_data_5m(list)

      btc_list = ChartData5m.where("currency_pair_id = 4 AND time_at > ? AND time_at < ?", start_time, end_time)
      data['btc_value'] = create_btc_data(btc_list)

      # Get duong trung binh of yesterday
      start_time = (date_time - 1.days).to_i
      end_time = (date_time).to_i
      max_value = ChartData5m.where("currency_pair_id = ? AND time_at > ? AND time_at < ?", pair_id, start_time, end_time).maximum('min_value')
      min_value = ChartData5m.where("currency_pair_id = ? AND time_at > ? AND time_at < ?", pair_id, start_time, end_time).minimum('min_value')

      yesterday_avg_value = (max_value - min_value) / 2 + min_value
      low1_value = yesterday_avg_value - yesterday_avg_value * step_percent
      low2_value = yesterday_avg_value - yesterday_avg_value * step_percent * 2
      high1_value = yesterday_avg_value + yesterday_avg_value * step_percent
      high2_value = yesterday_avg_value + yesterday_avg_value * step_percent * 2

      render json: {
        pair_data: data,
        predict: {
          yesterday_avg_value: yesterday_avg_value,
          max_value: max_value,
          min_value: min_value,
          low1_value: low1_value,
          low2_value: low2_value,
          high1_value: high1_value,
          high2_value: high2_value
        }
      }
    end

    def get_30m_full
      pair_id = params[:pair_id]
      pair_id = CurrencyPair.first.id if pair_id.nil? || pair_id.empty?

      start_time = (Time.now - 3.months).to_i
      end_time = Time.now.to_i
      
      list = ChartData30m.where("currency_pair_id = ? AND time_at > ? AND time_at < ?", pair_id, start_time, end_time)
      data = create_data_30m(list)

      btc_list = ChartData30m.where("currency_pair_id = 4 AND time_at > ? AND time_at < ?", start_time, end_time)
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
        min_value: min_value
      }
    end

    def create_data_30m(list)
      min_value = []

      list.each do |item|
        time_at = item.time_at * 1000
        min_value.push([time_at, item.min_value.to_f])
      end

      {
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