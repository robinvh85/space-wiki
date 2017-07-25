# chart_increase_percent
namespace :chart_increase_percent do
  task get: :environment do
    puts "Run rake chart_increase_percent:get at #{Time.now}"

    CurrencyPair.where(is_init: 1).each do |current_pair|
      date_start = DateTime.strptime("2017/07/01", '%Y/%m/%d')
      # current_pair = CurrencyPair.find_by(name: "BTC_NXT")

      26.times do |index|
        date = date_start + index.days
        puts "#{current_pair.name} - Get start_percent_min for #{date} at #{Time.now}"

        start_time = date
        end_time = start_time + 1.days
        previous = nil

        data_5m_list = ChartData5m.where("currency_pair_id = ? AND date_time >= ? AND date_time < ?", current_pair.id, start_time, end_time)
        data_5m_list.each do |item|
          if previous.nil?
            previous = item
            previous.increase_percent = 0
            previous.save!
          else
            item.increase_percent = ((item.min_value - previous.min_value) / previous.min_value * 100).round(4)
            item.save!
            previous = item
          end
        end
      end
    end

    puts "End rake chart_increase_percent:get at #{Time.now}"
  end
end

module ChartIncreasePercent
  class << self
    attr_accessor :start, :end
  end
end
