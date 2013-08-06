module LinkHelper
  def tweet_path(tweet)
    return '' unless tweet
    "/#{tweet[:screen_name]}/status/#{tweet[:tweet_id]}/"
  end
end
