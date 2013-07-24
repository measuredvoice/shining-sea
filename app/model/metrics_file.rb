class MetricsFile < Model
  attr_accessor :account, :date, :tweets
  
  def self.from_json(text)
    puts "Loading metrics file from JSON..."
    data = MultiJson.load(text, :symbolize_keys => true)
    self.new(
      :account => Account.new(data[:account]), 
      :date => Time.zone.parse(data[:date]),
      :tweets => data[:tweets].map { |t| TweetMetric.new(t) }
    )
  end
  
  def self.find(options={})
    # FIXME: This is a mess.
    if options[:account] && options[:date]
      mf = self.new(:account => options[:account], :date => options[:date])
      if mf.s3_obj = bucket.objects[mf.filename]
        self.from_json(s3_obj.read)
      else
        nil
      end
    else
      nil
    end
  end
  
  def self.where(options={})
    if options[:date]
      bucket.objects.with_prefix(date_path(options[:date])).map do |s3_obj|
        puts "Loading file from #{s3_obj.key}..."
        self.from_json(s3_obj.read)
      end
    else
      []
    end
  end
  
  def to_json
    JSON.pretty_generate(Boxer.ship(:raw_metrics, self))
  end
  
  def filename
    self.class.filename(date, account)
  end
  
  def self.filename(date, account)
    "#{date_path(date)}/#{account.screen_name}.json"
  end
  
  def self.date_path(date)
    "raw_metrics/#{date.strftime('%Y/%m/%d')}"
  end
  
  def iso_date
    date.strftime('%Y-%m-%d')
  end
  
  def save
    puts "  Writing #{filename} to S3..."
    bucket.objects[filename].write(to_json)
  end
  
  def already_exists?
    bucket.objects[filename].exists?
  end
  
  private
  
  def self.bucket
    # TODO: Validate these values
    key    = ENV['AWS_ACCESS_KEY']
    secret = ENV['AWS_SECRET_ACCESS_KEY']
    b      = ENV['AWS_BUCKET']
    
    AWS::S3.new(:access_key_id => key, :secret_access_key => secret).buckets[b]
  end
  
  def bucket
    self.class.bucket
  end
end