namespace :run do
  task :min_value, [] => :environment do |_cmd, args|
    puts "Run rake run:min_value"

    currency_pairs = CurrencyPair.where(id: 91)
    limit = 1000

    currency_pairs.each do |currency_pair|
      page = 0
      while true do
        puts "currency #{currency_pair.id} - page #{page}"
        list = ChartData30m.where("currency_pair_id = ? AND min_value is NULL", currency_pair.id).limit(limit)

        if list.length == 0
          break
        end

        list.each do |item|
          if item.close < item.open
            item.min_value = item.close
          else
            item.min_value = item.open
          end
          item.save
        end

        page += 1
      end
    end
  end

  task save_percent_min: :environment do
    puts "Run rake chart_data_run:save_percent_min at #{Time.now}"

    currency_pairs = CurrencyPair.where(id: 91)
    limit = 1000

    currency_pairs.each do |currency_pair|
      puts "Currency: #{currency_pair.id}"

      page = 0
      while true do
        puts "currency #{currency_pair.id} - page #{page}"
        list = ChartData5m.where("currency_pair_id = ? and percent_min_24h is null", currency_pair.id).limit(limit)
        if list.length == 0
          break
        end

        list.each do |item|
          _end = Time.at(item.time_at).to_i
          start = (_end - 24.hour).to_i

          min = ChartData5m.where("currency_pair_id = ? AND time_at > ? AND time_at <= ?", currency_pair.id, start, _end).minimum(:min_value)
          max = ChartData5m.where("currency_pair_id = ? AND time_at > ? AND time_at <= ?", currency_pair.id, start, _end).maximum(:min_value)
          
          if min == max
            item.percent_min_24h = 0.0
          else
            item.percent_min_24h = (item.min_value - min) / (max - min) * 100
          end
          item.save 
        end
      end
    end
    puts "End rake chart_data_run:save_percent_min at #{Time.now}"
  end

  task :min_value_all, [] => :environment do |_cmd, args|
    puts "Run rake run:min_value"

    currency_pairs = CurrencyPair.where(id: 14)

    currency_pairs.each do |currency_pair|
      Run.save_min_15m(currency_pair)
    end
  end
end

module Run
  class << self
    attr_accessor :start, :end

    def save_min_15m(pair)
      limit = 500
      page = 0
      while true do
        puts "currency #{pair.id} - page #{page}"
        list = ChartData15m.where("currency_pair_id = ? AND min_value is NULL", pair.id).limit(limit)

        if list.length == 0
          break
        end

        Run.save_min(list)

        page += 1
      end
    end

    def save_min(list)  
      list.each do |item|
        if item.close < item.open
          item.min_value = item.close
        else
          item.min_value = item.open
        end
        item.save
      end
    end
  end
end
