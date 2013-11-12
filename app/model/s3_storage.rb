module S3Storage
  module ClassMethods
    def s3_bucket
      # TODO: Validate these values
      key    = ENV['AWS_ACCESS_KEY']
      secret = ENV['AWS_SECRET_ACCESS_KEY']
      region = ENV['AWS_REGION'] || 'us-east-1'
      b      = ENV['AWS_BUCKET']
    
      AWS::S3.new(
        :access_key_id => key, 
        :secret_access_key => secret, 
        :region => region
      ).buckets[b]
    end
  end
  
  def self.included(host_class)
    host_class.extend(ClassMethods)
  end
  
  def s3_bucket
    self.class.s3_bucket
  end

  def save
    puts "  Writing #{filename} to S3..."
    s3_bucket.objects[filename].write(to_json)
  end
  
  def already_exists?
    s3_bucket.objects[filename].exists?
  end
end
