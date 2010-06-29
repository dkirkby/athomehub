class DeviceConfig < ActiveRecord::Base

  validates_uniqueness_of :serialNumber
  validates_uniqueness_of :networkID
  validates_uniqueness_of :location

  validates_numericality_of :networkID, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>256
  validates_numericality_of :dumpInterval, :only_integer=>true,
    :greater_than_or_equal_to=>2, :less_than=>256
  validates_numericality_of :comfortTempMin, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>256
  validates_numericality_of :comfortTempMax, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>256
  validates_numericality_of :selfHeatOffset, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>65536
  validates_numericality_of :selfHeatDelay, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>256
  validates_numericality_of :fiducialHiLoDelta, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>256
  validates_numericality_of :fiducialShiftHi, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>65536
  validates_numericality_of :powerGainHi, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>65536
  validates_numericality_of :powerGainLo, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>65536
  validates_numericality_of :nClipCut, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>256
    
  validates_format_of :serialNumber, :with=>/^[0-9a-fA-F]{8}$/,
    :message=>"is invalid (expected 8 hex digits)"
    
  validate :min_less_than_max
  
  def min_less_than_max
    errors.add_to_base("min temperature must be < max temperature") unless comfortTempMin < comfortTempMax
  end

  def serialize_for_device
    # pack the bits describing this device's enabled capabilities
    capabilities = 0
    capabilities |= (1<<0) if temperatureFeedback
    capabilities |= (1<<1) if lightingFeedback
    capabilities |= (1<<2) if lightingDump
    capabilities |= (1<<3) if powerDump
    # pack our fields in a little-endian structure:
    # uint8_t -> C, uint16_t -> v
    packed = [
      networkID,capabilities,dumpInterval,
      comfortTempMin,comfortTempMax,selfHeatOffset,selfHeatDelay,
      fiducialHiLoDelta,fiducialShiftHi,powerGainHi,powerGainLo,nclipCut
    ].pack("CCCCCvCCvvvC")
    # serialize to hex digits
    serialized = packed.unpack("C*").map! { |c| sprintf "%02x",c }.join
    # add the command header and terminating newline
    "C #{serialNumber} #{serialized}\n"
  end

  def lcd_format
    # displays the config in the same format as the device on its optional LCD
    line1 = sprintf "%8s%02x%02x%02x%02x\n",serialNumber,networkID,capabilities,
      dumpInterval,selfHeatDelay
    line2 = sprintf "%04x%04x%02x%02x%04x\n",powerGainLo,powerGainHi,
      comfortTempMin,comfortTempMax,selfHeatOffset
    line3 = sprintf "%04x%04x\n",fiducialShiftHi,fiducialHiLoDelta
    line4 = "................\n"
    line1 + line2 + line3 + line4
  end

end