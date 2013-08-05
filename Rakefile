require './shining-sea'

namespace :app do
  desc "Gather recent metrics from the Twitter API"
  task :collect_metrics, [:target_date] do |t, params|
    start_time = Time.zone.now
    
    if params[:target_date].present?
      target_date = Time.zone.parse(params[:target_date])
    else
      target_date = 2.days.ago
    end
    puts "Collecting metrics from #{target_date.strftime('%Y-%m-%d')}"
    
    files_written = 0
    Account.all.each do |account|
      puts "Account: #{account.screen_name}"      
      metrics_file = MetricsFile.new(:account => account, :date => target_date)

      if metrics_file.already_exists?
        puts "...file already exists. Skipping."
        next
      end

      account.get_twitter_details! || next
      
      metrics_file.tweets = account.tweets_on(metrics_file.date).map do |tweet|
        puts "  extracting metrics for tweet #{tweet.id}..."
        metric = TweetMetric.from_tweet(tweet)
        metric.count_reach!
        metric
      end
            
      puts "  writing file #{metrics_file.filename}..."
      # puts metrics_file.to_json
      if metrics_file.save
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
  
  desc "Rank accounts by audience size"
  task :rank_account_audience do
    files = MetricsFile.where(:date => 2.days.ago)
    
    # Fix the followers count if needed
    files.each do |metrics_file|
      account = metrics_file.account
      unless account.followers.present?
        puts "Updating followers count for #{account.screen_name}..."
        if metrics_file.tweets.count > 0
          puts "  ...from tweet..."
          account.followers = metrics_file.tweets.first.audience
        else
          puts "  ...from the Twitter API..."
          account.get_twitter_details!
          sleep 15.seconds
        end
        puts "...new count: #{account.followers}"
      end
    end
    
    puts "screen_name,followers"
    files.sort {|a,b| b.account.followers <=> a.account.followers}.each do |f|
      puts "#{f.account.screen_name},#{f.account.followers}"
    end
    
    puts "...done."
      
  end
  
  desc "Generate daily metrics summary data"
  task :daily_metrics, [:target_date] do |t, params|
    start_time = Time.zone.now
    
    if params[:target_date].present?
      target_date = Time.zone.parse(params[:target_date])
    else
      # This process will almost always run the day after collecting metrics
      target_date = 3.days.ago
    end
    puts "Summarizing metrics from #{target_date.strftime('%Y-%m-%d')}"
            
    summary = DailySummary.from_metrics(target_date)
    
    puts "Writing daily summary file..."
    summary.save
    
    puts "Writing tweet summary files..."
    summary.tweet_summaries.each do |ts|
      ts.save
    end
    
    puts "Writing account summary files..."
    summary.account_summaries.each do |as|
      as.tweet_summaries = summary.tweet_summaries_for_account(as.screen_name).sort {|a,b| a.daily_rank <=> b.daily_rank}
      as.save
    end
    
    puts "Writing tweet ranking files..."
    summary.rankings.each do |ranking|
      ranking.save
    end
    
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Summarized #{summary.tweet_summaries.count} tweets from #{summary.account_summaries.count} accounts in #{elapsed} seconds."
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

namespace :test do
  desc "Test the basic functions of the app (without altering data)"
  task :basic do
    puts "Checking S3 storage..."
    file = MetricsFile.where(:date => 3.days.ago).first
    puts "  first file: #{file.filename}"
    
    puts "Looks good from here."
  end
end
