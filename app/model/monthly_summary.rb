class MonthlySummary < Model
  include S3Storage
  attr_accessor :account_summaries, :month, :tweet_summaries, :tweet_counts
  
  def self.from_metrics(month)
    summary = self.new(
      :month => month,
      :tweet_summaries => [],
      :account_summaries => [],
      :tweet_counts => [],
    )
    
    # Turn the target month (YYYY-MM) into a range of dates
    parts = month.split(/-/)
    first_day = Date.new(parts[0].to_i, parts[1].to_i).beginning_of_month
    last_day = first_day.end_of_month
    
    (first_day..last_day).each do |target_date|      
      puts "Getting daily summary from #{target_date.strftime('%Y-%m-%d')}..."
      if ds = DailySummary.from_summary_file(target_date)
        # How can we include these without creating a 20 MB file?
        # summary.tweet_summaries += ds.tweet_summaries
        
        summary.tweet_counts << {
          :date => target_date,
          :count => ds.tweet_summaries.count,
        }
      else
        puts "WARNING: No daily summary for #{target_date.strftime('%Y-%m-%d')}"
      end
    end
    
    summary
  end
  
  def to_json
    JSON.pretty_generate(Boxer.ship(:monthly_summary, self))
  end

  def iso_date
    month
  end
  
  def filename
    self.class.filename(month)
  end
  
  def self.filename(month)
    "#{date_path(month)}/monthly_summary.json"
  end
  
  def self.date_path(month)
    "summaries/#{month.gsub(/-/,'/')}"
  end
end
