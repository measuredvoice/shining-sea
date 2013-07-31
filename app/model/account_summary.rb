class AccountSummary < Model
  include S3Storage
  attr_accessor :date, :screen_name, :name, :agency_id, :agency_name, :daily_bucket, :weekly_bucket, :followers, :tweet_summaries

  def self.from_account(account, target_date)
    self.new(
      :date        => target_date,
      :followers   => account.followers,
      :screen_name => account.screen_name,
      :name        => account.name,
      :agency_id   => account.agency_id,
      :agency_name => account.agency_name,
    )
  end
  
  def self.buckets
    [
      'extremely large',
      'very large',
      'large',
      'medium',
      'small',
    ]
  end
    
  def determine_bucket(accounts)
    return 'none' if followers < 10
    bucket_for_pct(Rank.percentile(self, accounts) {|a| a.followers})
  end
  
  def bucket_for_pct(percentile)
    case
    when percentile >= 98
      'extremely large'
    when percentile >= 94
      'very large'
    when percentile >= 86
      'large'
    when percentile >= 34
      'medium'
    when percentile >= 0
      'small'
    else
      'none'
    end 
  end

  def iso_date
    date.strftime('%Y-%m-%d')
  end
  
  def to_json
    JSON.pretty_generate(Boxer.ship(:account_summary, self, :view => :with_tweets))
  end

  def filename
    self.class.filename(date, screen_name)
  end
  
  def self.filename(date, screen_name)
    "#{date_path(date)}/#{screen_name}.json"
  end
  
  def self.date_path(date)
    "summaries/#{date.strftime('%Y/%m/%d')}"
  end
  
end
