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
    
    puts "Writing tweet ranking file..."
    summary.rankings.save
    
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Summarized #{summary.tweet_summaries.count} tweets from #{summary.account_summaries.count} accounts in #{elapsed} seconds."
  end
  
  desc "Generate weekly metrics summary data"
  task :weekly_metrics, [:end_date] do |t, params|
    start_time = Time.zone.now
    
    if params[:end_date].present?
      end_date = Time.zone.parse(params[:end_date])
    else
      # The end date should be the most recent date with metrics
      end_date = 3.days.ago
    end
    puts "Summarizing weekly metrics ending #{end_date.strftime('%Y-%m-%d')}"
            
    summary = WeeklySummary.from_metrics(end_date)
    
    puts "screen name,audience,engagement,kudos,link"
    summary.tweet_summaries.each do |ts|
      row = [ts.screen_name, ts.audience, ts.engagement, ts.kudos, ts.link]
      puts row.join(',')
    end
    
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Summarized #{summary.tweet_summaries.count} tweets from #{summary.account_summaries.count} accounts in #{elapsed} seconds."
  end
  
  desc "Build and deploy daily HTML reports"
  task :daily_reports, [:target_date] do |t, params|
    start_time = Time.zone.now
    
    if params[:target_date].present?
      target_date = Time.zone.parse(params[:target_date])
    else
      # This process will almost always run the day after collecting metrics
      target_date = 3.days.ago
    end
    
    file_date = target_date.strftime('%Y-%m-%d')
    puts "Writing reports for #{file_date}"
    ranking = DailyRanking.from_ranking_file(target_date)
    index_file = Boxer.ship(:daily_ranking, ranking)
          
    # Write the summary for each tweet
    prev_ts = nil;
    unless Dir.exists?('site/content/tweets')
      Dir.mkdir('site/content/tweets')
    end
    ranking.ranked_tweets.each do |ts|
      if prev_ts
        ts.daily_prev = prev_ts
        prev_ts.daily_next = ts
      end
      prev_ts = ts
    end.each do |ts|
      # Get the Twitter embed HTML for this tweet
      begin
        ts.embed_html = Twitter.oembed(ts.tweet_id).html
        sleep 5.seconds
      rescue Exception => e
        # TODO: Catch common exceptions and retry
        puts "Can't get embed from Twitter: #{e}"
      end
      
      ts_filename = "site/content/tweets/#{ts.screen_name}/#{ts.tweet_id}.html"
      unless Dir.exists?(File.dirname(ts_filename))
        puts "Writing directory #{File.dirname(ts_filename)}"
        Dir.mkdir(File.dirname(ts_filename))
      end
      puts "Writing tweet to #{ts_filename}..."
      File.open(ts_filename, 'wb') do |file|
        file.write(ts.to_yaml)
        file.write("\n---\n")
        file.write(ts.embed_html) if ts.embed_html
      end
    end
    
    # Write the index file for this week
    index_filename = "site/content/index.html"
    copy_filename = "site/content/top10/#{file_date}.html"
    puts "Writing top 10 rankings to #{index_filename}..."
    File.open(index_filename, 'wb') do |file|
      file.write(YAML.dump(index_file))
      file.write("\n---\n")
    end
    File.open(copy_filename, 'wb') do |file|
      file.write(YAML.dump(index_file))
      file.write("\n---\n")
    end

    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Wrote reports in #{elapsed} seconds."
  end
  
  desc "Compile HTML for the current set of reports" 
  task :compile_html do
    start_time = Time.zone.now
    
    puts "Compiling HTML..."
    puts %x(cd site && nanoc compile)
    
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Done. Compiled in #{elapsed} seconds."
  end
  
  desc "Deploy HTML changes to the site" 
  task :deploy_html do
    start_time = Time.zone.now
    
    s3_bucket = DailySummary.s3_bucket

    Dir.chdir('site/output')
    file_count = 0
    files = []
    # Write all the tweet summaries first
    files += Dir.glob("*/status/*/index.html")
    
    # Then write the top-10 lists
    files += Dir.glob("top10/*/index.html")
    
    # Then write the assets
    files += Dir.glob("assets/**/*.*")
    
    # Finally, write the main index file
    files << "index.html"

    files.each do |filename|
      puts "writing #{filename} to AWS..."
      s3_bucket.objects[filename].write(:file => filename)
      file_count += 1
    end

    Dir.chdir('../..')
    
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Done. Wrote #{file_count} files in #{elapsed} seconds."
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
