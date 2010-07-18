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
  
  def hsb_to_rgb(hsb)
    # Converts a hue (0-360), saturation (0-1), brightness (0-1) triplet
    # to an RGB (0-1) triplet. Does not do any range checks on the input
    # H,S,B values.
    hue,saturation,brightness = hsb
    # see http://en.wikipedia.org/wiki/HSL_color_space#From_HSV
    chroma = brightness*saturation
    hprime = hue/60.0
    x = chroma*(1-(hprime.modulo(2)-1).abs)
    case hprime
    when 0..1
      r,g,b = chroma,x,0
    when 1..2
      r,g,b = x,chroma,0
    when 2..3
      r,g,b = 0,chroma,x
    when 3..4
      r,g,b = 0,x,chroma
    when 4..5
      r,g,b = x,0,chroma
    when 5..6
      r,g,b = chroma,0,x
    else
      r,g,b = 0,0,0
    end
    m = brightness - chroma
    #logger.info sprintf("HSB %.1f,%.3f,%.3f RGB %d,%d,%d %s",
    #  hue,saturation,brightness,(255*(r+m)).round,(255*(g+m)).round,(255*(b+m)).round,
    #  rgb_to_hex([r+m,g+m,b+m]))
    # return an RGB triplet
    [r+m,g+m,b+m]
  end
  
  def rgb_to_hex(rgb)
    # Converts an RGB (0-1) triplet to a hex string #rrggbb. Does not
    # do any range checks on the input R,G,B values.
    r,g,b = rgb
    sprintf '#%02x%02x%02x',(255*r).round,(255*g).round,(255*b).round
  end
  
  def colorize(what)
    # pass through unless we can find the content to colorize
    return what unless what.instance_of? Hash and what.has_key? :content
    # apply color if requested
    if what.has_key? :rgb then
      color = rgb_to_hex what[:rgb]
    elsif what.has_key? :hsb then
      color = rgb_to_hex hsb_to_rgb what[:hsb]
    end
    if color then
      "<span style='color:#{color}'>#{what[:content]}</span>"
    else
      what[:content]
    end
  end

end
