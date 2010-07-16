class DeviceConfig < ActiveRecord::Base
  
  named_scope :latest_at, lambda { |at| {
    :from => 'device_configs c1',
    :conditions => [ 'c1.id = (select max(id) from device_configs c2 where ' +
      'c2.serialNumber = c1.serialNumber and created_at < ?)',at ]
  } }

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
  validates_numericality_of :powerAudioControl, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>65536
  validates_numericality_of :lightFidHiLoDelta, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>256
  validates_numericality_of :lightFidShiftHi, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>65536    
  validates_numericality_of :lightGainHi, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>256
  validates_numericality_of :lightGainHiLoRatio, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>65536
  validates_numericality_of :darkThreshold, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>65536
  validates_numericality_of :artificialThreshold, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>256
    
  validates_format_of :serialNumber, :with=>/^[0-9A-F]{8}$/,
    :message=>"is invalid (expected 8 upper-case hex digits)"
    
  validate_on_create :min_less_than_max
  validate_on_create :active_configs_are_unique
  
  def min_less_than_max
    errors.add_to_base("min temperature must be < max temperature") unless comfortTempMin < comfortTempMax
  end
  
  def active_configs_are_unique
    # lookup the most recent config for each serial number
    active = DeviceConfig.find(:all,:group=>:serialNumber,:readonly=>true)
    active.each do |config|
      # skip any existing config with the serial number we are updating
      next if config.serialNumber == serialNumber
      # check for a duplicate networkID
      errors.add_to_base("Device #{config.serialNumber} is already using network ID #{networkID}") if config.networkID == networkID
    end
  end

  def capabilities
    # packs the bits describing this device's enabled capabilities
    bits = 0
    bits |= (1<<0) if temperatureFeedback
    bits |= (1<<1) if lightingFeedback
    bits |= (1<<2) if lightingDump
    bits |= (1<<3) if powerDump
    bits |= (1<<4) if audioDiagnostics
    bits |= (1<<5) if powerEdgeAudio
    bits |= (1<<6) if powerLevelAudio
    bits |= (1<<7) if greenGlow
    bits |= (1<<8) if amberGlow
    bits |= (1<<9) if redGlow
    bits |= (1<<10) if greenFlash
    bits |= (1<<11) if amberFlash
    bits |= (1<<12) if redFlash
    bits |= (1<<13) if blueFlash
    bits |= (1<<14) if lightAudio
    return bits
  end

  def serialize_for_device
    # pack our fields in a little-endian structure:
    # uint8_t -> C, uint16_t -> v
    packed = [
      networkID,capabilities(),dumpInterval,
      comfortTempMin,comfortTempMax,selfHeatOffset,selfHeatDelay,
      fiducialHiLoDelta,fiducialShiftHi,powerGainHi,powerGainLo,nClipCut,
      powerAudioControl,lightFidHiLoDelta,lightFidShiftHi,lightGainHi,
			lightGainHiLoRatio,darkThreshold,artificialThreshold
    ].pack("CvCCCvCCvvvCvCvCvvC")
    # serialize to hex digits
    serialized = packed.unpack("C*").map! { |c| sprintf "%02x",c }.join
    # add the command header and terminating newline
    "C #{serialNumber} #{serialized}\n"
  end

  def lcd_format
    # displays the config in the same format as the device on its optional LCD
    line1 = sprintf "%8s%02X%04X%02X\n",serialNumber,networkID,capabilities(),
      dumpInterval
    line2 = sprintf "%04X%04X%02X%02X%04X\n",powerGainLo,powerGainHi,
      comfortTempMin,comfortTempMax,selfHeatOffset
    line3 = sprintf "%04X%02X%02X%02X%04X%02X\n",fiducialShiftHi,
      fiducialHiLoDelta,nClipCut,selfHeatDelay,powerAudioControl,lightFidHiLoDelta
    line4 = sprintf "%04X%02X%04X%04X%02X\n",lightFidShiftHi,lightGainHi,
      lightGainHiLoRatio,darkThreshold,artificialThreshold
    line1 + line2 + line3 + line4
  end

end