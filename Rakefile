require './shining-sea'

namespace :app do
  desc "Gather recent metrics from the Twitter API"
  task :collect_metrics do
    start_time = Time.zone.now
    files_written = 0
    Account.all.each do |account|
      puts "Account: #{account.screen_name}"
      account.get_twitter_details! || next
      
      # TODO: Only generate a new file if one doesn't already exist
      
      metrics = MetricsFile.new(:account => account, :date => 2.days.ago)
      metrics.tweets = account.tweets_on(metrics.date).map do |tweet|
        puts "  extracting metrics for tweet #{tweet.id}..."
        metric = TweetMetric.from_tweet(tweet)
        metric.count_reach!
        metric
      end
      
      puts "  writing file #{metrics.filename}..."
      # puts metrics.to_json
      if metrics.save
        puts "...done."
        files_written += 1
      else
        puts "ERROR: That didn't work for some reason."
      end
    end
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Wrote #{files_written} files in #{elapsed} seconds."
  end
  
  desc "Generate daily metrics summary data"
  task :daily_metrics do
  end
  
  desc "Generate weekly metrics summary data"
  task :weekly_metrics do
  end
  
  desc "Build and deploy daily HTML reports"
  task :daily_reports do
  end
  
  desc "Build and deploy weekly HTML reports"
  task :weekly_reports do
  end
end
