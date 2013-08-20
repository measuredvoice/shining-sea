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
    # Assign a distinct rank (1st, 2nd, 3rd) to each tweet,
    # using audience as a tiebreaker
    tweet_summaries.sort do |a,b|
      if a.mv_score == b.mv_score
        a.audience <=> b.audience
      else
        b.mv_score <=> a.mv_score
      end
    end.each_with_index do |ts, index|
      ts.daily_rank = index + 1
      ts.daily_pct = ts.determine_pct(tweet_summaries)
    end
  end
    
  def ranked_tweets
    tweet_summaries.sort {|a,b| a.daily_rank <=> b.daily_rank}
  end
  
  def rankings
    DailyRanking.from_summary(self)
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
    "summaries/#{date.strftime('%Y/%m/%d')}"
  end
  
end
