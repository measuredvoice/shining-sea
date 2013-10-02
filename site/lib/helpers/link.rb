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
      dir = 'top'
    when :previous_week
      link_date = start_date - 7.days
      dir = 'weekly'
    when :next
      link_date = start_date + 1.day
      dir = 'top'
    when :next_week
      link_date = start_date + 7.days
      dir = 'weekly'
    end
    
    "<a href=\"/#{dir}/#{link_date.strftime('%Y-%m-%d')}\">#{link_date.strftime('%B %-d, %Y')}</a>"
  end
end
