module LinkHelper
  def tweet_path(tweet)
    return '' unless tweet
    "/#{tweet[:screen_name]}/status/#{tweet[:tweet_id]}/"
  end
  
  def date_link(date_str, direction)
    start_date = Time.zone.parse(date_str)
    case direction
    when :previous, :prev
      link_date = start_date - 1.day
    when :next
      link_date = start_date + 1.day
    end
    
    "<a href=\"/top50/#{link_date.strftime('%Y-%m-%d')}\">#{link_date.strftime('%B %-d, %Y')}</a>"
  end
end
