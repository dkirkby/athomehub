module Engineering::ConfigHelper
  
  def capability(value)
    # returns an HTML snippet to display a true/false capability setting
    if value then
      "<span class='checked'>&#10003;</span>"
    else
      "&#10007"
    end
  end
  
end
