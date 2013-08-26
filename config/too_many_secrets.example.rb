# Specify the registry hostname and protocol, e.g. "http://registry.usa.gov"
# The registry just needs to return JSON at /accounts.json
# See http://registry.usa.gov/accounts.json?service_id=twitter for the format
ENV['REGISTRY_API_HOST'] = "http://registry.usa.gov"

# Keys for the Shining Sea app on Twitter.
# (See https://dev.twitter.com/apps to set up an app.)
ENV['TWITTER_CLIENT_KEY'] = "your twitter oauth client key"
ENV['TWITTER_CLIENT_SECRET'] = "your twitter oauth client secret"

# If retweeting/congratulating, the keys for a user of that app.
# ENV['TWITTER_RETWEETER_KEY'] = ""
# ENV['TWITTER_RETWEETER_SECRET'] = ""

# Turn on retweeting/congratulating only in production
# ENV['THIS_IS_PRODUCTION'] = true

ENV['AWS_ACCESS_KEY'] = "your AWS S3 access key"
ENV['AWS_SECRET_ACCESS_KEY'] = "your AWS S3 access secret"
ENV['AWS_BUCKET'] = "somebucket.yourdomain.com"
