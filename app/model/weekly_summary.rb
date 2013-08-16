class WeeklySummary < Model
  include S3Storage
  attr_accessor :account_summaries, :end_date, :tweet_summaries
  
  def self.from_metrics(end_date)
    summary = self.new(
      :end_date => end_date,
      :tweet_summaries => [],
      :account_summaries => [],
    )
    
    (0..6).each do |n|
      target_date = end_date - n.days
      
      puts "Getting daily summary from #{target_date.strftime('%Y-%m-%d')}..."
      ds = DailySummary.from_summary_file(target_date)
    
      summary.tweet_summaries += ds.tweet_summaries
    end
    
    summary
  end
  
  
end
