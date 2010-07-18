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
    return '#ff0000'
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
    return {:content=>display,:rgb=>colorPower}
  end

end