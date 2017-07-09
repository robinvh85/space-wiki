namespace :run do
  task :min_value, [] => :environment do |_cmd, args|
    puts "Run rake run:min_value"

    currency_pairs = CurrencyPair.all
    limit = 1000

    currency_pairs.each do |currency_pair|
      page = 0
      while true do
        puts "currency #{currency_pair.id} - page #{page}"
        list = ChartData30m.where("currency_pair_id = ? AND date_time > '2017-07-07'", currency_pair.id).offset(page * limit).limit(limit)

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
end
