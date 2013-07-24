class Account < Model
  attr_accessor :screen_name, :user_id, :name, :agency_id, :agency_name, :organization, :agencies, :followers
  
  def self.all
    options = {:service_id => :twitter}
    response = MultiJson.load(RestClient.get(endpoint, {:params => options}))
    accounts = response['accounts']
    if response['page_count'] > 1
      (2..response['page_count']).each do |page_number|
        accounts += MultiJson.load(RestClient.get(endpoint, {:params => options.merge(:page_number => page_number)}))['accounts']
      end
    end
    accounts.map do |a|
      Account.from_registry(a)
    end
  end
  
  # TODO: Implement self.each with a yield block
    
  def self.first
    options = {:service_id => :twitter}
    response = MultiJson.load(RestClient.get(endpoint, {:params => options}))
    Account.from_registry(response['accounts'].first)
  end
  
  def self.from_registry(a)
    agency = a['agencies'].first
    self.new(
      :screen_name  => a['account'],
      :agency_id => agency['agency_id'],
      :agency_name => agency['agency_name'],
      :agencies => a['agencies'],
      :organization => a['organization'],
    )
  end
  
  def tweets_on(metrics_date)
    day_start = metrics_date.beginning_of_day
    day_end   = metrics_date.end_of_day
    
    # puts "Tweets for #{screen_name} between #{day_start} and #{day_end}..."
    
    begin
      Twitter.user_timeline(:screen_name => screen_name, :count => 200, :exclude_replies => true, :include_rts => false).find_all do |tweet|
        tweet_date = tweet.created_at.in_time_zone(Time.zone)
        # puts " checking #{tweet_date}..."
        tweet_date >= day_start && tweet_date <= day_end
      end
    rescue Exception => error
      puts "Unknown Exception when listing timeline tweets: " + error.inspect
      return []
    end
  end
  
  def get_twitter_details!
    begin
      twitter_user = Twitter.user(screen_name)
    rescue Twitter::Error::NotFound
      puts "ERROR: Account #{screen_name} does not exist."
      return nil
    rescue Twitter::Error::TooManyRequests => error
      # This was a rate limit issue, pause to let Twitter catch up
      puts "Rate limit was exceeded. Waiting for 5 minutes..."
      sleep 5.minutes
      retry
    rescue Exception => error
      puts "Unknown Exception when getting user details: " + error.inspect
      return nil
    end
      
    self.user_id   = twitter_user.id
    self.name      = twitter_user.name
    self.followers = twitter_user.followers_count
  end
  
  def self.endpoint
    ENV['REGISTRY_API_HOST'] + '/accounts.json'
  end
end
