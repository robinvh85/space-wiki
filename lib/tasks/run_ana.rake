namespace :run_ana do
  task :analysis_value, [] => :environment do |_cmd, args|
    puts "Run rake run_ana:analysis_value"
    
    list = IcoPriceLog.where("pair_name = 'BCHUSD' AND analysis_value IS NULL")

    list.each do |item|
      puts "RUN id #{item.id}"
      records = IcoPriceLog.where("pair_name = 'BCHUSD' AND id <= ?", item.id).order(id: 'desc').limit(5)
      analysis_value = 0
      
      records.each do |record|
      analysis_value += record.change_buy_percent
      end
      
      item.analysis_value = analysis_value
      item.save
    end

  end
end
