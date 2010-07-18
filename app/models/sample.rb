class Sample < ActiveRecord::Base

  # We do not implement a :latest named_scope similar to the DeviceConfig and
  # DeviceProfile models because the correlated subquery used there is too
  # slow for a table with many records.

  # Returns samples recorded for the specified networkID up to the specified
  # utc time which defaults to now.
  named_scope :for_networkID, lambda { |*args|
    {
      :order => 'id ASC',
      :conditions => (args.length > 1) ?
        [ 'networkID = ? and created_at <= ?',args.first,args.last ] :
        [ 'networkID = ?',args.first ],
      :readonly => true
    }
  }

  # Returns the temperature with self-heating corrections applied.
  # Uses the temperature units specified in ATHOME.
  def theTemperature
    # raw measurement is in hundredths of a degree Farenheit
    result = 1e-2*temperature
    # lookup this sample's config if necessary (lazy cache)
    @config = DeviceConfig.for_networkID(networkID,created_at).last unless @config
    # adjust for self-heating
    result -= 1e-2*@config.selfHeatOffset if @config
    # convert to Celsius if requested
    result = (result - 32.0)/1.8 if ATHOME['temperature_units'] == 'C'
    return result
  end
  
  def displayTemperature
    # truncate to one decimal place
    display = sprintf "%.1f",theTemperature
    # append the appropriate unit
    display += "&deg;" + ATHOME['temperature_units']
    return display
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

  def displayPower
    # select a precision based on the value and append "W" for Watts
    case power
    when 0..0.03
      display = sprintf "%.3fW",power
    when 0.03..0.3
      display = sprintf "%.2fW",power
    when 0.3..3
      display = sprintf "%.1fW",power
    else
      display = sprintf "%.0fW",power
    end
    return {:content=>display,:hsb=>colorPower}
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
  
  def displayCost
    case cost = theCost
    when 0..1
      display = "&lt;1&cent;/day"
    when 1..99
      display = sprintf "%d&cent;/day",cost.round
    else
      display = sprintf "$%.2f/day",1e-2*cost
    end
    return {:content=>display,:hsb=>colorPower}
  end

end