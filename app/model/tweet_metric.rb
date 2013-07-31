class TweetMetric < Model
  attr_accessor :tweet_id, :audience, :reach, :kudos, :engagement, :raw_tweet
    
  def self.from_tweet(tweet)
    self.new(
      :raw_tweet  => tweet,
      :tweet_id   => tweet.id,
      :audience   => tweet.user.followers_count,
      :kudos      => tweet.favorite_count,
      :engagement => tweet.retweet_count,
    )
  end
  
  def id=(value)
    self.tweet_id ||= value
  end
  
  def count_reach!
    # Only use expensive API calls if there are retweets to be counted
    if raw_tweet.retweet_count == 0
      self.reach = audience
    else
      begin
        rts = Twitter.retweeters_of(tweet_id, :count => 100)
        sleep 15
      rescue Twitter::Error::TooManyRequests => error
        # This was a rate limit issue, so move on
        puts "Rate limit was exceeded."
        return nil
      rescue Exception => error
        puts "Unknown Exception when getting retweets: " + error.inspect
        return nil
      end
        
      self.reach = rts.inject(audience) do |total_reach, retweeter|
        total_reach + retweeter.followers_count
      end
    end
  end
end
