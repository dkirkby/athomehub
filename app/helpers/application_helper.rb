# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def format_serialNumber(sn)
    "#{sn[0,2]}-#{sn[2,2]}-#{sn[4,2]}-#{sn[6,2]}"
  end
  
  # Formats the provided UTC Time object and returns a sanitized date string.
  def format_date(timestamp)
    h timestamp.localtime.strftime("%A %d %B")
  end
  
  # Formats the provided UTC Time object and returns a sanitized time string.
  def format_time(timestamp)
    # convert to a DateTime since it provides some strftime goodies
    # like %l and %P that we want
    formatted = h timestamp.localtime.to_datetime.strftime("%l:%M%P")
  end
  
  def colorize(what)
    return what if what.instance_of? String
    "<span style='color:#{what[:rgb]}'>#{what[:content]}</span>"
  end

end
