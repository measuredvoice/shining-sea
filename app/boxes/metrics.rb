Boxer.box(:raw_metrics) do |box, metrics|
  box.view(:base) do
    {
      :date => metrics.iso_date,
      :account => Boxer.ship(:account, metrics.account),
      :tweet_count => metrics.tweets.count,
      :tweets => metrics.tweets.map {|t| Boxer.ship(:tweet, t)},
    }
  end
end

Boxer.box(:account) do |box, account|
  box.view(:base) do
    {
      :screen_name  => account.screen_name,
      :user_id      => account.user_id,
      :name         => account.name,
      :agency_id    => account.agency_id,
      :agency_name  => account.agency_name,
      :organization => account.organization,
      :followers    => account.followers,
    }
  end
end

Boxer.box(:tweet) do |box, tweet|
  box.view(:base) do
    {
      :tweet_id => tweet.tweet_id,
      :reach => tweet.reach,
      :kudos => tweet.kudos,
      :audience => tweet.audience,
      :engagement => tweet.engagement,
    }
  end
end
