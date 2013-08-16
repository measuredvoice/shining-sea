class DailyRanking < Model
  include S3Storage
  attr_accessor :date, :bucket, :ranked_tweets
  
  def self.from_summary(summary, bucket)
    self.new(
      :date          => summary.date,
      :bucket        => bucket,
      :ranked_tweets => summary.ranked_tweets(bucket).first(50),
    )
  end
  
  def self.from_json(text)
    puts "Loading daily ranking file from JSON..."
    data = MultiJson.load(text, :symbolize_keys => true)
    self.new(
      :date          => Time.zone.parse(data[:date]),
      :bucket        => data[:bucket],
      :ranked_tweets => data[:tweets].map { |ts| TweetSummary.new(ts) },
    )
  end
  
  def self.from_ranking_file(target_date, bucket)
    s3_obj = s3_bucket.objects[filename(target_date, bucket)]
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
    self.class.filename(date, bucket)
  end
  
  def bucket_path
    self.class.bucket_path(bucket)
  end
  
  def self.filename(date, bucket)
    "#{date_path(date)}/#{bucket_path(bucket)}.json"
  end
  
  def self.bucket_path(bucket)
    bucket.gsub(/\W/, '_')
  end
  
  def self.date_path(date)
    # NOTE: remove the tmp/ after testing
    "tmp/rankings/#{date.strftime('%Y/%m/%d')}"
  end  
end
  
