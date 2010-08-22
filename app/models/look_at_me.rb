class LookAtMe < ActiveRecord::Base
  
  include Scoped

  # A hub serial number starts with $FF
  def is_hub?
    return (serialNumber.hex & 0xff000000) == 0xff000000
  end
  
end
