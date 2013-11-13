require './shining-sea'

namespace :app do
  desc "1 - Gather metrics from the Twitter API"
  task :collect_metrics, [:target_date] do |t, params|
    start_time = Time.zone.now
    
    if params[:target_date].present?
      target_date = Time.zone.parse(params[:target_date])
    else
      default_offset = (ENV['SHINING_SEA_OFFSET'] || 2).to_i
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
      default_offset = (ENV['SHINING_SEA_OFFSET'] || 2).to_i
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
  
  desc "3a - Generate weekly metrics summary data"
  task :weekly_metrics, [:end_date] do |t, params|
    start_time = Time.zone.now
    
    if params[:end_date].present?
      end_date = Time.zone.parse(params[:end_date])
    else
      default_offset = (ENV['SHINING_SEA_OFFSET'] || 2).to_i
      end_date = default_offset.days.ago
    end
    puts "Summarizing weekly metrics ending #{end_date.strftime('%Y-%m-%d')}"
            
    summary = WeeklySummary.from_metrics(end_date)
    
    summary.save
    
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
      default_offset = (ENV['SHINING_SEA_OFFSET'] || 2).to_i
      target_date = default_offset.days.ago
    end
        
    file_date = target_date.strftime('%Y-%m-%d')
    ranking = DailyRanking.from_ranking_file(target_date)

    # Clear out old files only if this is the regular daily run
    if params[:target_date].nil?
      puts "Clearing out old content files..."
      puts %x(rm -r site/content/top/*)
      puts %x(rm -r site/content/tweets/*)
      puts %x(rm -r site/content/weekly/*)
    end
          
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
    
    top_filename = "site/content/top/#{file_date}.html"
    puts "Writing dated top rankings to #{top_filename}..."
    unless Dir.exists?("site/content/top")
      Dir.mkdir("site/content/top")
    end
    File.open(top_filename, 'wb') do |file|
      file.write(ranking.to_yaml)
      file.write("\n---\n")
    end
    
    # Write a weekly summary ending on this date
    weekly_filename = "site/content/weekly/#{file_date}.html"
    puts "Writing dated weekly rankings to #{weekly_filename}..."
    unless Dir.exists?("site/content/weekly")
      Dir.mkdir("site/content/weekly")
    end
    File.open(weekly_filename, 'wb') do |file|
      file.write("---\n")
      file.write(":date: '#{file_date}'\n")
      file.write("---\n")
    end

    # Write the index file if this is for today
    if params[:target_date].nil?
      index_filename = "site/content/index.html"
      puts "Writing top rankings to #{index_filename}..."
      File.open(index_filename, 'wb') do |file|
        file.write(ranking.to_yaml)
        file.write("\n---\n")
      end
      
      weekly_index_filename = "site/content/weekly/index.html"
      puts "Writing weekly rankings to #{weekly_index_filename}..."
      File.open(weekly_index_filename, 'wb') do |file|
        file.write("---\n")
        file.write(":date: '#{file_date}'\n")
        file.write("---\n")
      end
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
    
    # Then write the weekly lists
    files += Dir.glob("weekly/*/index.html")
    
    # Then write the iframe files
    files += Dir.glob("iframes/*/index.html")
    
    # Then write the assets
    files += Dir.glob("assets/**/*.*")
    
    # Finally, write the main index files
    files += Dir.glob("weekly/index.html")
    files += Dir.glob("index.html")

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
    
  desc "Retweet and congratulate the day's top tweets"
  task :retweet_top_tweets do
    retweeter = Twitter::Client.new(
      :oauth_token => ENV['TWITTER_RETWEETER_KEY'],
      :oauth_token_secret => ENV['TWITTER_RETWEETER_SECRET']
    )

    start_time = Time.zone.now
    
    top_n = ENV['SHINING_SEA_TOP_N'].to_i || 50
    
    default_offset = (ENV['SHINING_SEA_OFFSET'] || 2).to_i
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

  desc "Generate monthly metrics summary data. [Month in YYYY-MM]"
  task :monthly_metrics, [:month] do |t, params|
    start_time = Time.zone.now
    
    if params[:month].present?
      target_month = params[:month]
    else
      day_in_last_month = Time.zone.now.beginning_of_month - 1.day
      target_month = day_in_last_month.strftime('%Y-%m')
    end
    puts "Summarizing monthly metrics for #{target_month}"
            
    summary = MonthlySummary.from_metrics(target_month)
    
    summary.save
    
    # TEMPORARY: Spit out a CSV, too
    summary.tweet_counts.each do |tc|
      puts "#{tc[:date].strftime('%Y-%m-%d')},#{tc[:count]}"
    end
    
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Summarized #{summary.tweet_summaries.count} tweets from #{summary.account_summaries.count} accounts in #{elapsed} seconds."
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

namespace :export do
  desc "Export weekly metrics summary data as CSV"
  task :weekly_metrics_csv, [:end_date] do |t, params|
    start_time = Time.zone.now
    
    if params[:end_date].present?
      end_date = Time.zone.parse(params[:end_date])
    else
      default_offset = (ENV['SHINING_SEA_OFFSET'] || 2).to_i
      end_date = default_offset.days.ago
    end
    puts "Loading weekly metrics ending #{end_date.strftime('%Y-%m-%d')}"
            
    summary = WeeklySummary.from_summary_file(end_date)
    
    CSV.open("weekly-tweets.csv", "wb") do |csv|
      csv << ['Tweet URL', 'Retweets', 'Favorites', 'Followers', 'Date', 'MV Score', 'Daily Rank', 'Reach']
      
      summary.tweet_summaries.each do |ts|
        csv << [ts.link, ts.engagement, ts.kudos, ts.audience, ts.iso_date, ts.mv_score, ts.daily_rank, ts.reach]
      end
    end    
        
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Summarized #{summary.tweet_summaries.count} tweets from #{summary.account_summaries.count} accounts in #{elapsed} seconds."
  end
  
  desc "Count tweets and accounts by agency"
  task :count_tweets_by_agency do
    start_time = Time.zone.now
    
    # Look back 90 days for now
    dates = (1..90).map {|d| d.days.ago.strftime('%Y-%m-%d')}.reverse

    # tweets_on_date[date][agency_id] = number or
    # tweets_on_date[date]['total'] = number
    tweets_on_date = {}
    acct_tweets_on_date = {}

    # accounts_on_date[date][agency_id] = ['foof', 'bar', 'foof', 'baz']
    accounts_on_date = {}
    active_accounts_on_date = {}
    
    accounts = []
    
    # lookup for agencies
    # agency_for[account_id] = agency_id
    # name_of_agency[agency_id] = agency_name
    agency_for = {}
    name_of_agency = {}

    # First, process the summaries for these dates
    # to find a superset of accounts and agencies
    # and build counts of tweets and accounts each day
    
    dates.each do |target_date|
      puts "Collecting data from #{target_date}..."
      tweets_on_date[target_date] = {}
      tweets_on_date[target_date]['total'] = 0
      acct_tweets_on_date[target_date] = {}
      acct_tweets_on_date[target_date]['total'] = 0
      accounts_on_date[target_date] = {}
      accounts_on_date[target_date]['total'] = []
      active_accounts_on_date[target_date] = {}
      active_accounts_on_date[target_date]['total'] = []
      
      if ds = DailySummary.from_summary_file(Time.zone.parse(target_date))
        tweets_on_date[target_date]['total'] = ds.tweet_summaries.count
        acct_tweets_on_date[target_date]['total'] = ds.tweet_summaries.count
        ds.account_summaries.each do |as|
          accounts << as.screen_name
          agency_for[as.screen_name] = as.agency_id
          name_of_agency[as.agency_id] = as.agency_name
          tweets_on_date[target_date][as.agency_id] ||= 0
          acct_tweets_on_date[target_date][as.screen_name] ||= 0
          accounts_on_date[target_date][as.agency_id] ||= []
          accounts_on_date[target_date][as.agency_id] << as.screen_name
          accounts_on_date[target_date]['total'] << as.screen_name
          active_accounts_on_date[target_date][as.agency_id] ||= []
        end
        ds.tweet_summaries.each do |ts|
          agency_id = agency_for[ts.screen_name]
          
          tweets_on_date[target_date][agency_id] += 1
          acct_tweets_on_date[target_date][ts.screen_name] += 1
          active_accounts_on_date[target_date][agency_id] << ts.screen_name
          active_accounts_on_date[target_date]['total'] << ts.screen_name
        end
      else
        puts "WARNING: No summary file for #{target_date}"
      end
    end
    
    puts "TWEETS"
    puts tweets_on_date.inspect
    puts "ACCOUNT TWEETS"
    puts acct_tweets_on_date.inspect
    puts "ACCOUNTS"
    puts accounts_on_date.inspect
    puts "ACTIVE ACCOUNTS"
    puts active_accounts_on_date.inspect
    
    agencies = name_of_agency.keys.sort
    puts "AGENCIES"
    puts agencies.inspect
    puts agencies.count
    puts name_of_agency.inspect

    accounts = accounts.uniq.sort
    puts "ACCOUNTS"
    puts accounts.inspect
    puts accounts.count
          
    CSV.open("daily-tweets-per-account.csv", "wb") do |csv|
      csv << ['account'] + dates
      csv << ['total'] + dates.map {|d| acct_tweets_on_date[d]['total'] || 0}
      
      accounts.each do |acct|
        csv << [acct] + dates.map {|d| acct_tweets_on_date[d][acct] || 0 }
      end
    end
    
    CSV.open("daily-tweets-per-agency.csv", "wb") do |csv|
      csv << ['agency', 'name'] + dates
      csv << ['total', ''] + dates.map {|d| tweets_on_date[d]['total'] || 0}
      
      agencies.each do |agency_id|
        row = [agency_id, name_of_agency[agency_id]]
        row += dates.map do |d|
          tweets_on_date[d][agency_id] || 0
        end
        csv << row
      end
    end
    
    CSV.open("daily-accounts-per-agency.csv", "wb") do |csv|
      csv << ['agency', 'name'] + dates
      csv << ['total', ''] + dates.map {|d| (accounts_on_date[d]['total'] || []).uniq.count}
      
      agencies.each do |agency_id|
        row = [agency_id, name_of_agency[agency_id]]
        row += dates.map do |d|
          (accounts_on_date[d][agency_id] || []).uniq.count
        end
        csv << row
      end
    end
    
    CSV.open("daily-active-accounts-per-agency.csv", "wb") do |csv|
      csv << ['agency', 'name'] + dates
      csv << ['total', ''] + dates.map {|d| (active_accounts_on_date[d]['total'] || []).uniq.count}
      
      agencies.each do |agency_id|
        row = [agency_id, name_of_agency[agency_id]]
        row += dates.map do |d|
          (active_accounts_on_date[d][agency_id] || []).uniq.count
        end
        csv << row
      end
    end
    
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Counted tweets in #{elapsed} seconds."
  end
end

namespace :test do
  desc "Test the basic functions of the app (without altering data)"
  task :basic do
    puts "Checking S3 storage..."
    file = MetricsFile.where(:date => 3.days.ago).first
    puts "  first file: #{file.filename}"
    
    puts "Current time zone is: #{Time.zone}"
    
    puts "Looks good from here."
  end


  desc "Count tweets for a particular day"
  task :count_tweets, [:target_date] do |t, params|
    start_time = Time.zone.now
    
    if params[:target_date].present?
      target_date = Time.zone.parse(params[:target_date])
    else
      default_offset = (ENV['SHINING_SEA_OFFSET'] || 2).to_i
      target_date = default_offset.days.ago
    end
    puts "Counting tweets from #{target_date.strftime('%Y-%m-%d')}"
    
    total_count = 0
    Account.all.each do |account|
      puts "Account: #{account.screen_name}"      

      account.get_twitter_details! || next
      
      if tweets = account.tweets_on(target_date)
        puts "  count: #{tweets.count}"
        total_count += tweets.count
      else
        puts "  No tweets for #{account.screen_name}"
      end
      
      sleep 12
    end
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Counted #{total_count} tweets in #{elapsed} seconds."
  end

  desc "Check the configuration of the accounts list"
  task :accounts do
    start_time = Time.zone.now

    puts "Testing account list..."
    
    accounts_found = 0
    Account.all.each do |account|
      puts "Account: #{account.screen_name}"
      accounts_found += 1
      
      if accounts_found % 10 == 0
        # Check every 10th account for validity
        account.get_twitter_details! || next
        puts " ... found account ID #{account.user_id} (#{account.name})"
        sleep 15.seconds
      end
    end
    
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Found #{accounts_found} accounts in #{elapsed} seconds."
  end
end
