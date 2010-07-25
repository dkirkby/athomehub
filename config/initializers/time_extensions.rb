class Time
  
  @@_weekdays = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
  @@_months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
  @@_hour_aliases = ["midnight","noon"]
  
  def fields_as_strings
    hr = "#{1+(hour-1)%12}"
    if (sec == 0) and (min == 0) then
      if (hour == 0) then
        hr = @@_hour_aliases[0]
      elsif (hour == 12) then
        hr = @@_hour_aliases[1]
      end
    end
    [
      hr,
      sprintf(":%02d",min),
      sprintf(":%02d",sec),
      (hour < 12 ? 'am' : 'pm'),
      @@_weekdays[wday],
      "#{day}",
      @@_months[month-1],
      "#{year}"
    ]
  end

  def self.range_as_string(t1,t2,dash=' - ')
    raise "Empty interval" unless t2 > t1
    # create the format building blocks for each endpoint
    f1 = t1.fields_as_strings
    f2 = t2.fields_as_strings
    # strip off seconds and minutes if the are common to both endpoints and zero
    if (t1.sec == 0) and (t2.sec == 0) then
      if (t1.min == 0) and (t2.min == 0) then
        label1 = f1[0]
        label2 = f2[0]
      else
        label1 = f1[0..1].join
        label2 = f2[0..1].join
      end
    else
      label1 = f1[0..2].join
      label2 = f2[0..2].join
    end
    # split the day-month-year into common and per-endpoint labels
    if (t1.yday == t2.yday) and (t1.year == t2.year) then
      # range fits within one day
      common = f1[4..7].join ' '
      # do both endpoints have the same am/pm?
      if (f1[3] == f2[3]) then
        return "#{label1}#{dash}#{label2}#{f1[3]} on #{common}"
      else
        return "#{label1}#{f1[3]}#{dash}#{label2}#{f2[3]} on #{common}"
      end
    end
    # if we get here, the range spans a day boundary
    label1 += f1[3] unless @@_hour_aliases.include? label1
    label2 += f2[3] unless @@_hour_aliases.include? label2
    label1 += ' '
    label2 += ' '
    if (t1.month == t2.month) and (t1.year == t2.year) then
      # range fits within one month
      if (t2.yday - t1.yday > 7) then
        # omit the day of week if span is more than 7 days
        common = f1[7]
        label1 += f1[5..6].join ' '
        label2 += f2[5..6].join ' '
      else
        common = f1[6..7].join ' '
        label1 += f1[4..5].join ' '
        label2 += f2[4..5].join ' '
      end
      return "#{label1}#{dash}#{label2}, #{common}"
    elsif (t1.year == t2.year) then
      # range fits within one year
      common = f1[7]
      if (t2.yday - t1.yday > 7) then
        # omit the day of week if span is more than 7 days
        label1 += f1[5..6].join ' '
        label2 += f2[5..6].join ' '
      else
        label1 += f1[4..6].join ' '
        label2 += f2[4..6].join ' '
      end
      return "#{label1}#{dash}#{label2}, #{common}"
    else
      # range spans a year boundary
      label1 += f1[5..7].join ' '
      label2 += f2[5..7].join ' '
      return "#{label1}#{dash}#{label2}"
    end
  end
    
end
