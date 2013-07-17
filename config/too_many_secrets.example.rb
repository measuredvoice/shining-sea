# Specify the registry hostname and protocol, e.g. "http://registry.usa.gov"
# The registry just needs to return JSON at /accounts.json
# See http://registry.usa.gov/accounts.json?service_id=twitter for the format
ENV['REGISTRY_API_HOST'] = "http://registry.usa.gov"

# Keys for my Shining Sea development app
ENV['TWITTER_CLIENT_KEY'] = "your twitter oauth client key"
ENV['TWITTER_CLIENT_SECRET'] = "your twitter oauth client secret"

ENV['AWS_ACCESS_KEY'] = "your AWS S3 access key"
ENV['AWS_SECRET_ACCESS_KEY'] = "your AWS S3 access secret"
ENV['AWS_BUCKET'] = "somebucket.yourdomain.com"
