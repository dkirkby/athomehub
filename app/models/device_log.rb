class DeviceLog < ActiveRecord::Base
  
  before_validation :set_severity
  
  @@messages = {
    0=> [:info,"Hub started normally"],
  	1=> [:fatal,"Hub is unable to initialize wireless link"],
  	2=> [:error,"Unexpected hub data received in pipeline P%d"],
  	3=> [:error,"Nordic reports invalid RX_P_NO %d"],
  	4=> [:info,"Hub accepted config command for device %d"],
  	5=> [:error,"Hub received an invalid config command (error code %d)"],
  	6=> [:error,"Hub serial input buffer overflowed (max %d bytes)"]
  }

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

  @@levels = { :debug=> 0, :info=> 1, :warn=>2, :error=>3, :fatal=>4, :unknown=>9 }

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
