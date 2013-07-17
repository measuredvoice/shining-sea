require 'rubygems'
require 'bundler/setup'

require 'rest-client'
require 'twitter'
require 'aws-sdk'
require 'multi_json'
require 'boxer'
require 'active_support/all'

require_relative './config/too_many_secrets'

require_relative './app/model/model'
require_relative './app/model/account'
require_relative './app/model/tweet_metric'
require_relative './app/model/metrics_file'

require_relative './app/boxes/metrics'

Twitter.configure do |config|
  config.consumer_key    = ENV['TWITTER_CLIENT_KEY']
  config.consumer_secret = ENV['TWITTER_CLIENT_SECRET']
  config.bearer_token    = Twitter.token
end

Time.zone = "Eastern Time (US & Canada)"
