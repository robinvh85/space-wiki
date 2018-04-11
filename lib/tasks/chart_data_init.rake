require 'poloniex_vh'

PoloniexVh.setup do | config |
  config.key = 'KeyVVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6'
  config.secret = '0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59'
end

namespace :chart_data_init do
  task :get, [:pair_name] => :environment do |_cmd, args|
    puts "Run rake chart_data_init:get for #{args[:pair_name]} at #{Time.now}"

    ChartDataYear.start = Time.new(2017, 7, 1).to_i
    ChartDataYear.end = Time.new(2017, 9, 25).to_i

    # currency_pairs = CurrencyPair.where("name = ?", args[:pair_name])
    # currency_pairs = CurrencyPair.all if currency_pairs.count == 0

    if args[:pair_name].nil?
      currency_pairs = CurrencyPair.all
    else
      currency_pairs = CurrencyPair.where("name = ?", args[:pair_name])
    end

    currency_pairs.each do |currency_pair|
      begin
        # ChartDataYear.get_data_chart_30m(currency_pair)
        # ChartDataYear.get_data_chart_4h(currency_pair)
        ChartDataYear.get_data_chart_1d(currency_pair)
      rescue
        puts 'duplicated'
      end
    end
  end

  task :count_updown, [:pair_name] => :environment do |_cmd, args|
    if args[:pair_name].nil?
      currency_pairs = CurrencyPair.all
    else
      currency_pairs = CurrencyPair.where("name = ?", args[:pair_name])
    end

    currency_pairs.each do |currency_pair|
      begin
        pair_name = currency_pair.name
        puts "Run rake chart_data_init:count_updown for #{pair_name} at #{Time.now}"
        list = ChartData1d.where(pair_name: pair_name).order(time_at: 'asc')
    
        previous = nil
        count = 0
        list.each do |item|
          ChartDataYear.update_changed_percent(item)
          ChartDataYear.update_updown_count(item, previous)
          previous = item
        end
      rescue
        puts 'duplicated'
      end
    end
  end

  task :check_up_down, [:pair_name] => :environment do |_cmd, args|
    if args[:pair_name].nil?
      currency_pairs = CurrencyPair.all
    else
      currency_pairs = CurrencyPair.where("name = ?", args[:pair_name])
    end

    currency_pairs.each do |currency_pair|
      begin
        pair_name = currency_pair.name
        
        count1 = ChartData1d.where(pair_name: pair_name, up_down_count: 1).count
        count2 = ChartData1d.where(pair_name: pair_name, up_down_count: 2).count
    
        puts "#{pair_name}: #{count1} | #{count2} | #{ (count2 * 1.0 / count1 * 100).round(2) }"
        
      rescue
        puts 'duplicated'
      end
    end
  end
end

module ChartDataYear
  class << self
    attr_accessor :start, :end
    # 30m
    def get_data_chart_30m(currency_pair, period = 1800)
      puts "#{currency_pair.name} - period: #{period} at #{Time.now}"

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
      data = JSON.parse(response.body)

      data.each do |item|
        ChartData30m.create(build_data(currency_pair, item))
      end
    end

    def get_data_chart_4h(currency_pair, period = 14400)
      puts "#{currency_pair.name} - period: #{period} at #{Time.now}"

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
      data = JSON.parse(response.body)

      data.each do |item|
        ChartData4h.create(build_data(currency_pair, item))
      end
    end

    def get_data_chart_1d(currency_pair, period = 86400)
      puts "#{currency_pair.name} - period: #{period} at #{Time.now}"

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
      data = JSON.parse(response.body)

      data.each do |item|
        ChartData1d.create(build_data(currency_pair, item))
      end
    end

    def build_data(currency_pair, item)
      {
        pair_name: currency_pair.name,
        date_time: Time.at(item['date']),
        time_at:  item['date'],
        high:     item['high'],
        low:      item['low'],
        open:     item['open'],
        close:    item['close'],
        volume:   item['volume'],
        quote_volume:   item['quoteVolume'],
        weighted_average: item['weightedAverage']
      }
    end

    def update_changed_percent(item)
      item.changed_percent = (item.close - item.open) / item.open * 100
      item.save
    end

    def update_updown_count(item, previous)
      count = 0
      if item.close > item.open
        if previous.nil? or (!previous.nil? and previous.up_down_count < 0)
          count = 1
        else
          count = previous.up_down_count + 1
        end
      else
        if previous.nil? or (!previous.nil? and previous.up_down_count > 0)
          count = -1
        else
          count = previous.up_down_count - 1
        end
      end

      item.up_down_count = count
      item.save!
    end
  end
end