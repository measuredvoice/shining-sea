require './shining-sea'

namespace :app do
  desc "1 - Gather metrics from the Twitter API"
  task :collect_metrics, [:target_date] do |t, params|
    start_time = Time.zone.now
    
    if params[:target_date].present?
      target_date = Time.zone.parse(params[:target_date])
    else
      default_offset = ENV['SHINING_SEA_OFFSET'].to_i || 2
      target_date = default_offset.days.ago
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
  
  desc "2 - Generate daily metrics summary data"
  task :daily_metrics, [:target_date] do |t, params|
    start_time = Time.zone.now
    
    if params[:target_date].present?
      target_date = Time.zone.parse(params[:target_date])
    else
      default_offset = ENV['SHINING_SEA_OFFSET'].to_i || 2
      target_date = default_offset.days.ago
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
      default_offset = ENV['SHINING_SEA_OFFSET'].to_i || 2
      target_date = default_offset.days.ago
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
  
  desc "3 - Build daily HTML content files (tweets and rankings)"
  task :daily_reports, [:target_date] do |t, params|
    start_time = Time.zone.now
    
    if params[:target_date].present?
      target_date = Time.zone.parse(params[:target_date])
    else
      default_offset = ENV['SHINING_SEA_OFFSET'].to_i || 2
      target_date = default_offset.days.ago
    end
        
    file_date = target_date.strftime('%Y-%m-%d')
    ranking = DailyRanking.from_ranking_file(target_date)

    puts "Clearing out old content files..."
    puts %x(rm -r site/content/top/*)
    puts %x(rm -r site/content/tweets/*)
          
    # Write the summary for each tweet
    puts "Writing reports for #{file_date}"
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
    copy_filename = "site/content/top/#{file_date}.html"
    puts "Writing top rankings to #{index_filename}..."
    File.open(index_filename, 'wb') do |file|
      file.write(ranking.to_yaml)
      file.write("\n---\n")
    end
    puts "Writing dated top rankings to #{copy_filename}..."
    unless Dir.exists?("site/content/top")
      Dir.mkdir("site/content/top")
    end
    File.open(copy_filename, 'wb') do |file|
      file.write(ranking.to_yaml)
      file.write("\n---\n")
    end

    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Wrote reports in #{elapsed} seconds."
  end
  
  desc "4 - Compile HTML for the current set of reports" 
  task :compile_html do
    start_time = Time.zone.now
    
    puts "Clearing out old output files..."
    puts %x(rm -r site/output/*)
          
    puts "Compiling HTML..."
    puts %x(cd site && nanoc compile)
    
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Done. Compiled in #{elapsed} seconds."
  end
  
  desc "5 - Deploy HTML changes to the site" 
  task :deploy_html do
    start_time = Time.zone.now
    
    s3_bucket = DailySummary.s3_bucket

    Dir.chdir('site/output')
    file_count = 0
    files = []
    # Write all the tweet summaries first
    files += Dir.glob("*/status/*/index.html")
    
    # Then write the top-N lists
    files += Dir.glob("top/*/index.html")
    
    # Then write the iframe files
    files += Dir.glob("iframes/*/index.html")
    
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
  
  desc "Retweet and congratulate the day's top tweets"
  task :retweet_top_tweets do
    retweeter = Twitter::Client.new(
      :oauth_token => ENV['TWITTER_RETWEETER_KEY'],
      :oauth_token_secret => ENV['TWITTER_RETWEETER_SECRET']
    )

    start_time = Time.zone.now
    
    top_n = ENV['SHINING_SEA_TOP_N'].to_i || 50
    
    default_offset = ENV['SHINING_SEA_OFFSET'].to_i || 2
    ranking = DailyRanking.from_ranking_file(default_offset.days.ago)
    retweet_count = 0
    retweet_limit = top_n
    congrats_count = 0
    congrats_limit = top_n
    congratulated = {}
    ranking.ranked_tweets.first(retweet_limit).each do |ts|
      puts "Retweeting #{ts.tweet_id}..."
      begin
        rt = retweeter.retweet(ts.tweet_id)
      rescue Exception => e
        puts "  Can't retweet: #{e}"
      end
      
      if rt.nil? || rt.empty?
        puts "...no retweet."
      else
        retweet_count += 1
        puts "...done."
        sleep 5.minutes
      end
      
      if congratulated[ts.screen_name]
        puts "Already congratulated #{ts.screen_name}. Skipping..."
      elsif congrats_count >= congrats_limit
        puts "Already congratulated #{congrats_limit} accounts. Skipping..."
      else
        puts "Congratulating #{ts.screen_name}..."
        
        tweet_text = "@#{ts.screen_name} Congrats on writing a great government tweet! #{ts.our_link} (Ranked #{ts.daily_rank.ordinalize} for #{ts.date.strftime('%b %-d')}.)"
        puts "  " + tweet_text
        
        begin
          retweeter.update(tweet_text, {:in_reply_to_status_id => ts.tweet_id})
        rescue Exception => e
          puts "  Can't reply: #{e}"
        end
        
        congratulated[ts.screen_name] = true
        congrats_count += 1
        puts "...done."
        sleep 5.minutes
      end
    end    

    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Done. Retweeted #{retweet_count} and congratulated #{congrats_count} in #{elapsed} seconds."
  end
end

namespace :setup do
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
  
  desc "Calculate the key values needed for the tweet MV score"
  task :find_mv_score_values, [:end_date] do |t, params|
    start_time = Time.zone.now
    
    if params[:end_date].present?
      end_date = Time.zone.parse(params[:end_date])
    else
      # The end date should be the most recent date with metrics
      end_date = 3.days.ago
    end
    puts "Summarizing weekly metrics ending #{end_date.strftime('%Y-%m-%d')}"
            
    summary = WeeklySummary.from_metrics(end_date)
    
    puts "Finding median score and standard deviation..."
    scores = summary.tweet_summaries.map do |ts|
      unscaled_score = ts.kudos * 1.5 + ts.engagement
      scaled_score = ts.audience > 0 ? unscaled_score / ts.audience : 0
      puts "{\"screen_name\": \"#{ts.screen_name}\", \"audience\": #{ts.audience}, \"kudos\": #{ts.kudos}, \"engagement\": #{ts.engagement}, \"unscaled_score\": #{unscaled_score}, \"scaled_score\": #{ts.mv_score}},"
      scaled_score
    end
    
    median = scores.sort.reverse[(scores.count / 2).to_i]
    std_dev = (median - scores.sort.reverse[(0 - scores.count / 50).to_i]) / 2
    
    puts "Median: #{median}"
    puts "Std dev: #{std_dev}"
    
    key_alpha = median ** 2 / std_dev ** 2
    key_beta = median / std_dev ** 2 * 10 ** 5
    
    puts "ENV['SHINING_SEA_ALPHA'] = '#{key_alpha}'"
    puts "ENV['SHINING_SEA_BETA']  = '#{key_beta}'"
    
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Summarized #{summary.tweet_summaries.count} tweets from #{summary.account_summaries.count} accounts in #{elapsed} seconds."
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
