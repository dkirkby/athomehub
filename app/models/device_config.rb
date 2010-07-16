class DeviceConfig < ActiveRecord::Base
  
  # Returns the most recent config records defined at the specified utc time
  # which defaults to now.
  named_scope :latest, lambda { |*args|
    {
      :from => 'device_configs c1',
      :conditions => args.first ?
        [ 'c1.id = (select max(id) from device_configs c2 where ' +
          'c2.serialNumber = c1.serialNumber and created_at < ?)',args.first ] :
        ( 'c1.id = (select max(id) from device_configs c2 where ' +
          'c2.serialNumber = c1.serialNumber)' ),
      :readonly => true
    }
  }
  # Returns the configs for the specified serial number at the specified utc
  # time which defaults to now. Examples:
  #
  #   # Find the config that was active 1 day ago
  #   DeviceConfig.for_serialNumber('0000012E',1.day.ago).last
  #
  #   # Find the config history in reverse chronological order
  #   DeviceConfig.for_serialNumber('0000012E').find(:all,:order=>'id DESC')
  #
  named_scope :for_serialNumber, lambda { |*args|
    {
      :conditions => (args.length > 1) ?
        [ 'serialNumber = ? and created_at < ?',args.first,args.last ] :
        [ 'serialNumber = ?',args.first ],
      :readonly => true
    }
  }

  # Returns the configs for the specified networkID at the specified utc
  # time which defaults to now. Usage is similar to for_serialNumber.
  named_scope :for_networkID, lambda { |*args|
    {
      :conditions => (args.length > 1) ?
        [ 'networkID = ? and created_at < ?',args.first,args.last ] :
        [ 'networkID = ?',args.first ],
      :readonly => true
    }
  }

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
    # a disabled config cannot conflict with existing configs
    return if not enabled
    # lookup the most recent config for each serial number
    DeviceConfig.latest.each do |config|
      # skip any existing config for the serial number we are updating since
      # we will be overwriting it
      next if config.serialNumber == serialNumber
      # check for a duplicate networkID on an enabled config for a different SN
      errors.add_to_base("Device #{config.serialNumber} is already using " +
        "network ID #{networkID}") if (config.enabled and
        config.networkID == networkID)
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