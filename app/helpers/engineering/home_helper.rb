module Engineering::HomeHelper

  def time_ago(tval,alt)
    if tval then
      return time_ago_in_words(tval)
    else
      begin
        return '> ' + time_ago_in_words(alt)
      rescue
        return alt
      end
    end
  end
  
end
