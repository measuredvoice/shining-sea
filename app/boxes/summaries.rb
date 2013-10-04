Boxer.box(:daily_summary) do |box, summary|
  box.view(:base) do
    {
      :date => summary.iso_date,
      :accounts_count => summary.account_summaries.count,
      :accounts => summary.account_summaries.map do |as| 
        Boxer.ship(:account_summary, as)
      end,
      :tweet_count => summary.tweet_summaries.count,
      :tweets => summary.tweet_summaries.map do |ts| 
        Boxer.ship(:tweet_summary, ts, :view => :metrics)
      end,
    }
  end
end

Boxer.box(:account_summary) do |box, as|
  box.view(:base) do
    {
      :date          => as.iso_date,
      :screen_name   => as.screen_name,
      :name          => as.name,
      :agency_id     => as.agency_id,
      :agency_name   => as.agency_name,
      :followers     => as.followers,
    }
  end
  
  box.view(:with_tweets, :extends => :base) do
    {
      :tweets =>  as.tweet_summaries.map do |ts| 
        Boxer.ship(:tweet_summary, ts, :view => :metrics)
      end,
    }
  end
end

Boxer.box(:tweet_summary) do |box, ts|
  box.view(:base) do
    {
      :date         => ts.iso_date,
      :tweet_id     => ts.tweet_id,
      :screen_name  => ts.screen_name,
      :account_name => ts.account_name,
      :link         => ts.link,
      :daily_rank   => ts.daily_rank,
    }
  end
  
  box.view(:metrics, :extends => :base) do 
    {
      :audience     => ts.audience,
      :reach        => ts.reach,
      :kudos        => ts.kudos,
      :engagement   => ts.engagement,
      :mv_score     => ts.mv_score,
      :daily_next   => ts.daily_next ? Boxer.ship(:tweet_summary, ts.daily_next) : nil,
      :daily_prev   => ts.daily_prev ? Boxer.ship(:tweet_summary, ts.daily_prev) : nil,
      :embed_html   => ts.embed_html,
    }
  end
end

Boxer.box(:daily_ranking) do |box, ranking|
  box.view(:base) do
    {
      :date        => ranking.iso_date,
      :tweet_count => ranking.ranked_tweets.count,
      :tweets      => ranking.ranked_tweets.map do |ts| 
        Boxer.ship(:tweet_summary, ts, :view => :metrics)
      end,
    }
  end
end

Boxer.box(:weekly_summary) do |box, summary|
  box.view(:base) do
    {
      :end_date => summary.iso_date,
      :accounts_count => summary.account_summaries.count,
      :accounts => summary.account_summaries.map do |as| 
        Boxer.ship(:account_summary, as)
      end,
      :tweet_count => summary.tweet_summaries.count,
      :tweets => summary.tweet_summaries.map do |ts| 
        Boxer.ship(:tweet_summary, ts, :view => :metrics)
      end,
    }
  end
end

Boxer.box(:monthly_summary) do |box, summary|
  box.view(:base) do
    {
      :month => summary.iso_date,
      :accounts_count => summary.account_summaries.count,
      :accounts => summary.account_summaries.map do |as| 
        Boxer.ship(:account_summary, as)
      end,
      :total_tweet_count => summary.tweet_summaries.count,
      :tweets => summary.tweet_summaries.map do |ts| 
        Boxer.ship(:tweet_summary, ts, :view => :metrics)
      end,
      :tweet_counts => summary.tweet_counts.map do |tc| 
        Boxer.ship(:tweet_count, tc)
      end,
    }
  end
end

Boxer.box(:tweet_count) do |box, tc|
  box.view(:base) do
    {
      :date        => tc[:date].strftime('%Y-%m-%d'),
      :count       => tc[:count],
    }
  end
end

