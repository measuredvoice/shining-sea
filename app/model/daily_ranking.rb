class DailyRanking < Model
  include S3Storage
  attr_accessor :date, :ranked_tweets
  
  def self.from_summary(summary)
    self.new(
      :date          => summary.date,
      :ranked_tweets => summary.ranked_tweets.first(100),
    )
  end
  
  def self.from_json(text)
    puts "Loading daily ranking file from JSON..."
    data = MultiJson.load(text, :symbolize_keys => true)
    self.new(
      :date          => Time.zone.parse(data[:date]),
      :ranked_tweets => data[:tweets].map { |ts| TweetSummary.new(ts) },
    )
  end
  
  def self.from_ranking_file(target_date)
    s3_obj = s3_bucket.objects[filename(target_date)]
    if s3_obj.exists?
      self.from_json(s3_obj.read)
    else
      nil
    end
  end
  
  def to_json
    JSON.pretty_generate(Boxer.ship(:daily_ranking, self))
  end

  def to_yaml
    YAML.dump(Boxer.ship(:daily_ranking, self))
  end

  def iso_date
    date.strftime('%Y-%m-%d')
  end
  
  def filename
    self.class.filename(date)
  end
  
  def self.filename(date)
    "#{date_path(date)}/daily-top-100.json"
  end
  
  def self.date_path(date)
    "rankings/#{date.strftime('%Y/%m/%d')}"
  end  
end
  
