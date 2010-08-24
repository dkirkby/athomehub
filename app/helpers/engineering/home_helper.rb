module Engineering::HomeHelper

  def time_ago(tval,alt)
    if tval then
      time_ago_in_words tval
    else
      alt
    end
  end
  
end
