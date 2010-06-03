class DeviceLog < ActiveRecord::Base
  
  before_validation :set_severity
  
  @@messages = {
    -12=>[:warn,"Device buffer dump missing initial packet at sequence number %d"],
    -11=>[:error,"Device buffer dump has illegal sequence number %d"],
    -10=>[:info,"Receiving new device buffer dump"],
    -9=>[:warn,"Discarding partial device buffer dump"],
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

  # Returns a descriptive severity string
  def severity_string
    if @@messages.has_key? code then
      severity,template = @@messages[code]
      severity.to_s.upcase
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
