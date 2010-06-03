class DeviceConfig < ActiveRecord::Base

  validates_uniqueness_of :serialNumber
  validates_uniqueness_of :networkID
  validates_uniqueness_of :location

  validates_numericality_of :minTemperature,
    :greater_than_or_equal_to=>0, :less_than=>200
  validates_numericality_of :maxTemperature,
    :greater_than_or_equal_to=>0, :less_than=>200
  validates_numericality_of :networkID, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>255
    
  validates_format_of :serialNumber, :with=>/^[0-9a-fA-F]{8}$/,
    :message=>"is invalid (expected 8 hex digits)"
    
  validate :min_less_than_max
  
  def min_less_than_max
    errors.add_to_base("min temperature must be < max temperature") unless minTemperature < maxTemperature
  end

  def serialize_for_device
    # pack the bits describing this device's enabled capabilities
    capabilities = 0
    capabilities |= (1<<0) if temperatureFeedback
    capabilities |= (1<<1) if lightingFeedback
    capabilities |= (1<<2) if lightingDump
    capabilities |= (1<<3) if powerDump
    # convert our decimal temperatures to 100xdegF
    minTempFixed = (100*minTemperature).round
    maxTempFixed = (100*maxTemperature).round
    # pack our fields in a little-endian structure
    packed = [networkID,capabilities,minTempFixed,maxTempFixed].pack("CCvv")
    # serialize to hex digits
    serialized = packed.unpack("C*").map! { |c| sprintf "%02x",c }.join
    # add the command header and terminating newline
    "C #{serialNumber} #{serialized}\n"
  end

end