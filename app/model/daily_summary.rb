class DailySummary < Model
  include S3Storage
  attr_accessor :account_summaries, :date, :tweet_summaries
  
  def self.from_metrics(target_date)
    summary = self.new(
      :date => target_date,
    )
    
    files = MetricsFile.where(:date => target_date)
    
    summary.account_summaries = files.map do |mf|
      AccountSummary.from_account(mf.account, target_date)
    end
    summary.tweet_summaries = files.map do |mf|
      mf.tweets.map do |tm|
        TweetSummary.from_tweet_metric(mf.account, tm, target_date)
      end
    end.flatten
    
    summary.assign_account_buckets!
    summary.assign_tweet_buckets!
    summary.rank_all_tweets!
    
    summary
  end
  
  def self.from_json(text)
    puts "Loading daily summary file from JSON..."
    data = MultiJson.load(text, :symbolize_keys => true)
    self.new(
      :date => Time.zone.parse(data[:date]),
      :tweet_summaries => data[:tweets].map { |ts| TweetSummary.new(ts) },
      :account_summaries => data[:accounts].map { |as| AccountSummary.new(as) },      
    )
  end
  
  def self.from_summary_file(target_date)
    s3_obj = s3_bucket.objects[filename(target_date)]
    if s3_obj.exists?
      self.from_json(s3_obj.read)
    else
      nil
    end
  end
  
  def summary_for(screen_name)
    account_summaries.find {|as| as.screen_name = screen_name}
  end
  
  def rank_all_tweets!
    AccountSummary.buckets.each do |bucket|
      # Assign a distinct rank (1st, 2nd, 3rd) to each tweet in the bucket,
      # using audience as a tiebreaker
      bucket_tweets = tweets_in_bucket(bucket)
      bucket_tweets.sort do |a,b|
        if a.mv_score == b.mv_score
          a.audience <=> b.audience
        else
          b.mv_score <=> a.mv_score
        end
      end.each_with_index do |ts, index|
        ts.daily_rank = index + 1
        ts.daily_pct = ts.determine_pct(bucket_tweets)
      end
    end
  end
  
  def assign_account_buckets!
    account_summaries.each do |as|
      as.daily_bucket = as.determine_bucket(account_summaries)
    end
  end
  
  def accounts_in_bucket(bucket)
    account_summaries.find_all do |as|
      as.daily_bucket == bucket
    end.sort {|a,b| b.followers <=> a.followers}
  end
  
  def assign_tweet_buckets!
    AccountSummary.buckets.each do |bucket|
      accounts_in_bucket(bucket).each do |as|
        tweet_summaries_for_account(as.screen_name).each do |tweet|
          tweet.daily_bucket = bucket
        end
      end
    end
  end
  
  def tweets_in_bucket(bucket)
    tweet_summaries.find_all do |tweet|
      tweet.daily_bucket == bucket
    end
  end
  
  def ranked_tweets(bucket)
    tweets_in_bucket(bucket).sort {|a,b| a.daily_rank <=> b.daily_rank}
  end
  
  def rankings
    AccountSummary.buckets.map do |bucket|
      DailyRanking.from_summary(self, bucket)
    end    
  end
  
  def tweet_summaries_for_account(screen_name)
    tweet_summaries.find_all {|t| t.screen_name == screen_name}
  end

  def to_json
    JSON.pretty_generate(Boxer.ship(:daily_summary, self))
  end

  def iso_date
    date.strftime('%Y-%m-%d')
  end
  
  def filename
    self.class.filename(date)
  end
  
  def self.filename(date)
    "#{date_path(date)}/daily_summary.json"
  end
  
  def self.date_path(date)
    # NOTE: remove the tmp/ after testing
    "tmp/summaries/#{date.strftime('%Y/%m/%d')}"
  end
  
end
