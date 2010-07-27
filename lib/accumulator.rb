class Accumulator
  
  @@fields = Sample.new.values_as_array.length
  @@levels = BinnedSample.zoom_levels

  def initialize(networkID)
    @networkID = networkID
    @codes = Array.new(@@levels)
    @counts = Array.new(@@levels) {0}
    @bins = Array.new(@@levels) do |level|
      Array.new(@@fields) {0}
    end
    @pending = Array.new(@@levels)
    at_exit { self.flush }
  end
  
  # Pre-loads any bins already in the database at the specified time.
  def synch(at)
    @@levels.times do |level|
      @codes[level] = BinnedSample.bin(at,level)
      bin = BinnedSample.find(:first,
        :conditions=>['networkID=? and binCode=?',@networkID,@codes[level]])
      next unless bin
      @counts[level] = bin.binCount
      @bins[level] = bin.values_as_array
      @pending[level] = bin
    end
  end
  
  # Adds one sample with no check on its networkID
  def add(sample)
    if defined? @at
      raise 'Samples must be accumulated in time order' unless
        sample.created_at > @at
    else
      synch sample.created_at
    end
    @at = sample.created_at
    # at how many consecutive levels have we crossed a bin boundary?
    crossing_depth = @@levels.times do |level|
      code = BinnedSample.bin(@at,level)
      break(level) if code==@codes[level]
      # save the bin at this level now
      save level
      # add this bin to its containing bin at the next level, if there is one
      nlevel = level + 1
      if nlevel < @@levels then
        @counts[nlevel] += @counts[level]
        @@fields.times {|k| @bins[nlevel][k] += @bins[level][k] }
      end
      # reset this level
      @codes[level] = code
      @counts[level] = 0
      @bins[level].map! {0}
      @pending[level]= nil
    end
    # add this sample to our level-0 bin
    values = sample.values_as_array
    @@fields.times {|k| @bins[0][k] += values[k] }
    @counts[0] += 1
  end
  
  def flush
    puts "flushing accumulator for network ID #{@networkID}"
  end

  def save(level)
    puts "saving sample for network ID #{@networkID} at level #{level}"
  end
  
end
