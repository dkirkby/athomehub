class DeviceLog < ActiveRecord::Base
  
  include Scoped
  
  named_scope :min_severity, lambda { |level|
    {
      :conditions=>['severity >= ?',level]
    }
  }
  
  before_validation :set_severity
  
  @@messages = {
    -21=>[:warn,"Device buffer dump with unexpected length %d"],
    -20=>[:error,"Ignoring unsolicited buffer dump from disabled network ID %d"],
    -19=>[:error,"Hub ignoring buffer from network ID %d with no config"],
    -18=>[:error,"Ignoring unsolicited sample from disabled network ID %d"],
    -17=>[:error,"Hub ignoring sample from network ID %d with no config"],
    -16=>[:warn,"Hub received samples from invalid network ID %d"],
    -15=>[:warn,"Hub receiving samples from un-configured network ID %d"],
    -14=>[:error,"Hub sensor readings have badly formatted values"],
    -13=>[:error,"Hub sensor readings with unexpected length %d"],
    -12=>[:warn,"Device buffer dump missing initial packet at sequence number %d"],
    -11=>[:error,"Device buffer dump has illegal sequence number %d"],
    -10=>[:debug,"Receiving new device buffer dump from source %d"],
    -9=>[:warn,"Saving partial device buffer dump"],
    -8=>[:error,"Device buffer dump has invalid value at position %d"],
    -7=>[:error,"Device data has invalid value at position %d"],
    -6=>[:warn,"Device received invalid config"],
    -5=>[:info,"Device received updated config"],
    -4=>[:info,"Device received initial config"],
    -3=>[:warn,"Device retransmitted %d times"],
    -2=>[:warn,"Device dropped %d packets"],
    -1=>[:error,"Device data with unexpected length %d"],
    0=> [:info,"Hub started normally"],
  	1=> [:fatal,"Hub is unable to initialize wireless link"],
  	2=> [:error,"Unexpected hub data received in pipeline P%d"],
  	3=> [:error,"Nordic reports invalid RX_P_NO %d"],
  	4=> [:info,"Hub accepted config command for device %d"],
  	5=> [:error,"Hub received an invalid config command (error code %d)"],
  	6=> [:error,"Hub serial input buffer overflowed (max %d bytes)"]
  }

  @@levels = { :debug=> 0, :info=> 1, :warn=>2, :error=>3, :fatal=>4, :unknown=>9 }

  # Returns the numeric severity level corresponding to a level name, or nil
  # if the name is not recognize
  def self.severity_level(name)
    key = name.downcase.to_sym
    @@levels[key] if @@levels.has_key? key
  end

  # Returns the severity as a symbol
  def severity_symbol
    @@messages[code][0] if @@messages.has_key? code
  end

  # Returns a descriptive severity string
  def severity_string
    s = severity_symbol
    if s then
      s.to_s.upcase
    else
      "UNKNOWN"
    end
  end
    
  # Returns a descriptive log message
  def message
    if @@messages.has_key? code then
      severity,template = @@messages[code]
      sprintf template,value
    else
      "Unrecognized log message #{code} with value #{value}"
    end
  end
  
protected

  # Sets the severity field from the code. We do this, despite the redundancy,
  # to allow efficient queries for serious errors.
  def set_severity
    if @@messages.has_key? self.code then
      level,template = @@messages[code]
      self.severity = @@levels[level]
    else
      self.severity = @@levels[:unknown]
    end
  end

end
