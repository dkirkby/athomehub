class BufferDump < ActiveRecord::Base

  belongs_to :config,
    :class_name => "DeviceConfig",
    :foreign_key => "networkID",
    :primary_key => "networkID",
    :readonly => true
    
  before_save :save_samples
  serialize :samples, Array
  
  def save_samples
    self[:samples] = @samples if @samples
  end

  def init_samples(size,values)
    @samples = Array.new(size)
    self.add_samples 0,values
  end

  def add_samples(base,values)
    values.each_with_index do |v,k|
      @samples[base+k]= v.hex
    end
  end
  
  # Unpacks the analysis header and returns a hash of header parameters.
  # Multi-byte values from device are little-endian.
  def unpack_header
    binary = "\0\0\0\0\0\0\0\0\0\0\0"
    binary.length.times do |k|
      binary[k] = self.header[2*k,2].hex
    end
    case self.source
    when 0,1
      # powerAnalysis
      keys = [:nClipped,:currentComplexity,:currentRMS,:rawPhase,:relativePhase]
      values = binary.unpack("CCevv")
      @results = Hash[*keys.zip(values).flatten]
    when 4
      # phaseAnalysis
      keys = [:moment1,:moment0,:voltagePhase,:wrapOffset]
      values = binary.unpack("VVvC")
    else
      keys,values = [ ],[ ]
    end
    Hash[*keys.zip(values).flatten]
  end

end
