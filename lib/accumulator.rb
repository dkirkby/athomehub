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
    # which bin boundaries does this sample cross, if any?
    at = sample.created_at
    @@levels.times do |level|
      code = BinnedSample.bin(at,level)
      break if code==@codes[level]
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

  # this default save action can be replaced via save_with below
  @@default_save = Proc.new do |netID,bin,code,count,values|
    bin = BinnedSample.new(:networkID=>netID,:binCode=>code) unless bin
    bin.binCount = count
    bin.values_from_array! values
    bin.save
  end
  
  @@save = @@default_save
  
  def self.save_with(&action)
    if block_given? then
      @@save = action
    else
      @@save = @@default_save
    end
  end
  
  def save_and_fold(level)
    raise 'Cannot save empty bin' unless @counts[level] > 0
    @@save.call @networkID,@pending[level],@codes[level],@counts[level],@bins[level]
    # fold this bin into its containing bin at the next level, if there is one
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
      puts "Deleted #{sprintf '%5d',deleted} bins at level #{level} with " +
        "codes [#{sprintf '%08x',begin_code},#{sprintf '%08x',end_code})"
    end
    # use a custom save action
    row_data = [ ]
    Accumulator.save_with do |netID,bin,code,count,values|
      raise "Internal error: rebuild found existing bin for " +
        "#{bin.interval.inspect} with code #{sprintf '%08x',bin.binCode}" if bin
      row_data << "(#{netID},#{code},#{count},#{values.join(',')})"
    end
    # loop over samples in this interval in batches (to limit memory usage)
    count = 0
    batch_number = 0
    batch_sql = "INSERT INTO binned_samples (networkID,binCode,binCount," +
      BinnedSample.array_order.join(',') + ") VALUES "
    begin
      samples = Sample.find(:all,:order=>'id ASC',:readonly=>true,
        :offset=>batch_number*batch_size,:limit=>batch_size,:conditions=>[
        'created_at >= ? and created_at < ?',interval.begin.utc,interval.end.utc])
      # accumulate the samples in this batch
      samples.each do |s|
        raise "Sample outside of interval at #{s.created_at.localtime}" unless
          interval.include? s.created_at
        Accumulator.accumulate s
      end
      # write out all of the new bins finished so far
      BinnedSample.connection.execute batch_sql+row_data.join(',')
      row_data.clear
      # get ready for the next batch
      count += samples.length
      batch_number += 1
      puts "Binned #{count} samples after batch #{batch_number}"
    end until samples.length < batch_size
    # restore save action
    Accumulator.save_with
  end
  
end
