module TextHelper
  def ordinalize(number)
    number.ordinalize
  end
  
  def pretty_number(number)
    number.to_s.reverse.gsub(%r{([[:digit:]]{3})(?=[[:digit:]])(?![[:digit:]]*\.)}, "\\1,").reverse
  end
  
  def pretty_date(date_str)
    Time.zone.parse(date_str).strftime('%B %-d, %Y')
  end
  
  # Turn '2013-09-28' into '2013/09/28'
  def linky_date(date_str)
    date_str.gsub(/-/,'/')
  end
  
  def pluralize(number, singular, plural)
    if number == 1
      singular
    else
      plural
    end
  end

end
