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
    @last_id = -1
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
    raise 'Samples must be accumulated in time order' unless sample.id > @last_id
    @last_id = sample.id
    return
    # which bin boundaries does this sample cross, if any?
    @@levels.times do |level|
      code = BinnedSample.bin(@at,level)
      break(level) if code==@codes[level]
      # save the bin at this level and fold its contents into its containing bin
      save_and_fold level
      # update this bin's code
      @codes[level] = code
    end
    # add this sample to our level-0 bin
    values = sample.values_as_array
    @@fields.times {|k| @bins[0][k] += values[k] }
    @counts[0] += 1
  end
  
  def flush
    puts "flushing accumulator for network ID #{@networkID}"
    @@levels.times do |level|
      save_and_fold(level) if @counts[level] > 0
    end
  end

  def save_and_fold(level)
    raise 'Cannot save empty bin' unless @counts[level] > 0
    save @pending[level],@codes[level],@counts[level],@bins[level]
    # add this bin to its containing bin at the next level, if there is one
    nlevel = level + 1
    if nlevel < @@levels then
      @counts[nlevel] += @counts[level]
      @@fields.times {|k| @bins[nlevel][k] += @bins[level][k] }
    end
    # reset this bin
    @counts[level] = 0
    @bins[level].map! {0}
    @pending[level]= nil
  end
  
  def save(bin,code,count,values)
    bin = BinnedSample.new(:networkID=>@networkID,:binCode=>code) unless bin
    bin.binCount = count
    bin.values_from_array! values
    bin.save
  end
  
  @@accumulators = { }

  def self.accumulate(sample)
    netID = sample.networkID
    if not @@accumulators.has_key? netID then
      accumulator = Accumulator.new(netID)
      accumulator.synch sample.created_at
      @@accumulators[netID] = accumulator
    else
      accumulator = @@accumulators[netID]
    end
    accumulator.add sample
  end

  def self.rebuild(at,batch_size=1000)
    # find the top-level bin interval containing the specified time
    top_code = BinnedSample.bin(at,@@levels-1)
    interval = BinnedSample.interval_for_code(top_code)
    puts "Rebuilding #{interval}"
    # delete any existing records in this interval
    @@levels.times do |level|
      begin_code = BinnedSample.bin(interval.begin,level)
      end_code = BinnedSample.bin(interval.end,level)
      deleted = BinnedSample.delete_all([
        'binCode >= ? and binCode < ?',begin_code,end_code])
      puts "Deleted #{deleted} bins at level #{level}"
    end
    # loop over samples in this interval in batches (to limit memory usage)
    batch_number = 0
    count = 0
    begin
      samples = Sample.find(:all,:order=>'id ASC',:readonly=>true,
        :offset=>batch_number*batch_size,:limit=>batch_size,:conditions=>[
        'created_at >= ? and created_at < ?',interval.begin,interval.end])
      samples.each { |s| Accumulator.accumulate s }
      count += samples.length
      batch_number += 1
      puts "Binned #{count} samples after batch #{batch_number}"
    end until samples.length < batch_size
  end
  
end
