# A mix-in module for classes with the following attributes:
# networkID, temperature, lighting, artificial, lightFactor,
# power, powerFactor, complexity.

module Measured
  
  @@config_cache = { }
  
  def config
    @@config_cache[networkID] = DeviceConfig.for_networkID(networkID).last unless
      @@config_cache.has_key? networkID
    return @@config_cache[networkID]
  end

  # Returns the temperature with self-heating corrections applied.
  # Corrections are based on the most recent DeviceConfig defined for
  # this instance's network ID. Uses the temperature units specified in ATHOME.
  def theTemperature(convert=true)
    # raw measurement is in hundredths of a degree Farenheit
    result = 1e-2*temperature
    # adjust for self-heating
    result -= 1e-2*config.selfHeatOffset
    # convert to Celsius if requested
    result = (result-32.0)/1.8 if convert && (ATHOME['temperature_units'] == 'C')
    return result
  end
  
  def sigmoid(x)
    1/(1+Math.exp(-x))
  end
  
  def colorTemperature
    # Return the previously cached value if available
    return @colorTemperature if @colorTemperature
    # Returns the RGB color corresponding to this sample's temperature relative
    # to the comfort zone specified for its network ID
    temp = theTemperature(convert=false)
    return unless temp
    tmin = config.comfortTempMin
    tmax = config.comfortTempMax
    dt = 0.2*(tmax-tmin)
    blue = sigmoid((tmin-temp)/dt)
    red = sigmoid((temp-tmax)/dt)
    @colorTemperature = [red,0,blue]
  end
  
  def displayTemperature
    # truncate to one decimal place
    display = sprintf "%.1f",theTemperature
    # append the appropriate unit
    display += "&deg;" + ATHOME['temperature_units']
    return {:content=>display,:rgb=>colorTemperature}
  end

  def lightingLevel
    ratio = lighting/32767.0
    ratio = 0.3 if ratio < 0.3
    sprintf "%.3f",ratio
  end

  def colorLighting
    # Return the previously cached value if available
    return @colorLighting if @colorLighting
    # Returns the HSB color corresponding to this sample's lighting conditions
    threshold = config.artificialThreshold
    # s1 varies from 0 to 1 as lighting becomes more artificial
    s1 = sigmoid((artificial-threshold)/(0.25*threshold))
    threshold = config.darkThreshold & 0xff
    # s2 varies from 0 to 1 as lighting level increases through dark threshold
    s2 = sigmoid((lighting-threshold)/(0.25*threshold))
    hue = 120 - 60*s1 # green to yellow
    saturation = s2
    brightness = 0.87 + 0.13*s2
    @colorLighting = [hue,saturation,brightness]
  end

  def displayLighting
    if lighting == nil
      return nil
    elsif lighting < (config.darkThreshold & 0xff) then
      {:type=>:dark}
    elsif artificial > config.artificialThreshold then
      {:type=>:artificial,:level=>lightingLevel}
    else
      {:type=>:natural,:level=>lightingLevel}
    end
  end

  def colorPower
    # Return the previously cached value if available
    return @colorPower if @colorPower
    # Returns the HSB color corresponding to this sample's power factor and complexity.
    hue = 50.0 - 184.0*powerFactor/255.0
    hue += 360 if hue < 0
    cratio = complexity/255.0
    saturation = 0.4 + 0.2*cratio
    brightness = 0.5 + 0.5*cratio
    @colorPower = [hue,saturation,brightness]
  end

  def autoRange(value,units,nilDisplay='&mdash;')
    # select a precision based on the value and append the specified units
    case value
    when nil
      return nilDisplay
    when 0..0.003
      display = "0"
    when 0.003..0.03
      display = sprintf "%.3f",value
    when 0.03..0.3
      display = sprintf "%.2f",value
    when 0.3..3
      display = sprintf "%.1f",value
    else
      display = sprintf "%.0f",value
    end
    display + units
  end
  
  def displayPower
    {:content=>autoRange(power,'W'),:hsb=>colorPower}
  end

  # Returns the cost in cents corresponding to 24 hour continuous usage
  # at this sample's power level.
  def theCost
    # calculate the energy in kWh used in 24 hours at this power level
    # using (24x60x60 secs/day)/(1000x60x60 J/kWh) = 0.024 (kWh/day)/W
    kWh_per_day = 0.024*power
    # convert to an equivalent cost in cents
    return kWh_per_day*ATHOME['energy_cost']
  end
  
  def autoRangeCost(amount,period='/day',nilDisplay='&mdash;')
    # select a format based on the specified amount in cents
    case amount
    when nil
      return nilDisplay
    when 0..1
      display = "&lt;1&cent;"
    when 1..99
      display = sprintf "%d&cent;",amount.round
    else
      display = sprintf "$%.2f",1e-2*amount.round
    end
    display + period
  end

  def displayCost
    {:content=>autoRangeCost(theCost),:hsb=>colorPower}
  end

end