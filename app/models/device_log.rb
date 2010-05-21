class DeviceLog < ActiveRecord::Base
  
  @@messages = {
    0=> [:info,"Hub started normally"],
  	1=> [:fatal,"Hub is unable to initialize wireless link"],
  	2=> [:error,"Unexpected hub data received in pipeline P%d"],
  	3=> [:error,"Nordic reports invalid RX_P_NO %d"],
  	4=> [:info,"Hub accepted config command for device %d"],
  	5=> [:error,"Hub received an invalid config command (error code %d)"],
  	6=> [:error,"Hub serial input buffer overflowed (max %d bytes)"]
  }

  def message
    if @@messages.has_key? code then
      severity,template = @@messages[code]
      sprintf template,value
    else
      "Unrecognized log message #{code} with value #{value}"
    end
  end

end
