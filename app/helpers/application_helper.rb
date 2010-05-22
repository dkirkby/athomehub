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
    formatted = h timestamp.localtime.strftime("%I:%M%p")
    # drop a leading zero on the hour
    formatted.slice! /^0/
    # replace AM/PM with am/pm
    formatted.downcase
  end

end
