# chart_increase_percent
namespace :chart_increase_percent do
  task get: :environment do
    puts "Run rake chart_increase_percent:get at #{Time.now}"

    CurrencyPair.where(is_init: 1).each do |current_pair|
      date_start = DateTime.strptime("2017/07/01", '%Y/%m/%d')
      # current_pair = CurrencyPair.find_by(name: "BTC_NXT")

      1.times do |index|
        date = date_start + 24.days
        puts "#{current_pair.name} - Get start_percent_min for #{date} at #{Time.now}"

        start_time = date
        end_time = start_time + 1.days
        sample_data = nil

        data_5m_list = ChartData5m.where("currency_pair_id = ? AND date_time >= ? AND date_time < ?", current_pair.id, start_time, end_time)
        data_5m_list.each do |item|
          if sample_data.nil?
            sample_data = item
            sample_data.increase_percent = 0
            sample_data.save!
          else
            item.increase_percent = ((item.min_value - sample_data.min_value) / sample_data.min_value * 100).round(4)
            item.save!
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
