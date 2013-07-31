class Rank
  def self.percentile(item, list, &block)
    items_less_than = list.count do |i|
      if block_given?
        block.call(item) > block.call(i)
      else
        item > i
      end
    end
    
    (items_less_than * 100) / list.count
  end
end
