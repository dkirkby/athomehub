class Accumulator
  
  @@levels = BinnedSample.zoom_levels

  class Level

    @@fields = Sample.new.values_as_array.length

    attr_reader :code,:count,:bins

    def initialize(netID,level)
      @netID = netID
      @bins = Array.new(@@fields)
      reset
    end
    
    def reset(code=nil)
      @code = code
      @count = 0
      @bins.map! {0}
      @pending= nil    
    end

    def synch(code,bin=nil)
      @code = code
      return unless bin
      @count = bin.binCount
      @bins = bin.values_as_array
      @pending = bin
    end
    
    def add(count,bins)
      @count += count
      @@fields.times {|k| @bins[k] += bins[k] }
    end
    
    def save(partial=false)
      # create a new bin unless we have an existing one to update
      @pending = BinnedSample.new(:networkID=>@netID,:binCode=>@code) unless @pending
      # transfer our accumulated data to the bin
      @pending.binCount = @count
      @pending.values_from_array! @bins
      # save the bin now
      @pending.save
      # remember this bin if this was a partial update
      @pending = nil unless partial
    end
    
    def debug_save(partial=false)
     puts "Saving #{sprintf '%08x',@code} with #{sprintf '%6d',@count} entries " +
      " (#{partial})"
    end

  end

  def initialize(networkID)
    @networkID = networkID
    @level_acc = Array.new(@@levels) { |level| Level.new(networkID,level) }
    @last_id = -1
    @bin_boundary = nil
    at_exit { self.flush }
  end
  
  # Pre-loads any bins already in the database at the specified time.
  def synch(at)
    @@levels.times do |level|
      code = BinnedSample.bin(at,level)
      bin = BinnedSample.find(:first,
        :conditions=>['networkID=? and binCode=?',@networkID,code])      
      @level_acc[level].synch code,bin
    end
    # initialize the level-0 bin boundary
    @bin_boundary = BinnedSample.interval_for_code(@level_acc[0].code).end.to_i
  end
  
  def fold(from_level)
    return if from_level > @@auto_save_threshold or from_level == @@levels-1
    if from_level < @@auto_save_threshold then
      # only fold one level up
      to_level = from_level+1
    else
      # fold into all enclosing bins so that auto-saved bins are up to date
      to_level = @@levels - 1
    end
    count = @level_acc[from_level].count
    bins = @level_acc[from_level].bins
    (from_level+1).upto(to_level) do |level|
      ##puts "folding #{count} from level #{from_level} to #{level}"
      @level_acc[level].add(count,bins)
    end
  end
  
  # periodically auto-save levels above this threshold
  @@auto_save_threshold = 1
  
  # Adds one sample with no check on its networkID.
  def add(sample)
    raise 'Samples must be accumulated in time order' unless sample.id > @last_id
    @last_id = sample.id
    # do first-time synchronization if necessary
    at = sample.created_at
    synch(at) unless @bin_boundary
    # are we still in the same bins?
    if at.to_i >= @bin_boundary then
      # which bin boundaries does this sample cross?
      crossing_depth = @@levels.times do |level|
        code = BinnedSample.bin(at,level)
        break(level) if code==@level_acc[level].code
        # save this bin now
        @level_acc[level].save
        # fold this bin's contents into its enclosing bins
        fold level
        # reset this bin to track a new interval
        @level_acc[level].reset code
      end
      # auto-save bins at levels >= crossing_depth when ever a bin
      # at level >= @@auto_save_threshold rolls over
      if crossing_depth > @@auto_save_threshold and crossing_depth < @@levels-1 then
        crossing_depth.upto(@@levels-1) do |level|
          @level_acc[level].save true
        end
      end
      # update the level-0 bin boundary
      @bin_boundary = BinnedSample.interval_for_code(@level_acc[0].code).end.to_i
    end
    # add this sample to our level-0 bin
    values = sample.values_as_array
    @level_acc[0].add(1,values)
  end
  
  def flush
    puts "flushing accumulator for network ID #{@networkID}"
    @@levels.times do |level|
      if @level_acc[level].count > 0 then
        @level_acc[level].save
        fold level
        @level_acc[level].reset
      end
    end
    @last_id = -1
    @bin_boundary = nil
  end

  # this default save action can be replaced via save_with below
  @@default_save = Proc.new do |netID,partial,bin,code,count,values|
    ##if partial then
    ##  puts "Old count for partial #{sprintf '%08x',code} is #{bin.binCount}" if bin
    ##  puts "New count for partial #{sprintf '%08x',code} is #{count}"
    ##end
    bin = BinnedSample.new(:networkID=>netID,:binCode=>code) unless bin
    bin.binCount = count
    bin.values_from_array! values
    bin.save
    bin
  end

  @@accumulators = { }

  # This is the main entry point for using an accumulator.
  def self.accumulate(sample)
    netID = sample.networkID
    if not @@accumulators.has_key? netID then
      accumulator = Accumulator.new(netID)
      @@accumulators[netID] = accumulator
    else
      accumulator = @@accumulators[netID]
    end
    accumulator.add sample
  end
  
  def self.flush_all
    @@accumulators.each { |netID,a| a.flush }
    return
  end

  def self.rebuild(at,batch_size=1000)
    # reset any existing accumulators
    Accumulator.flush_all
    # find the top-level bin interval containing the specified time
    top_code = BinnedSample.bin(at,@@levels-1)
    interval = BinnedSample.interval_for_code(top_code)
    puts "Rebuilding #{interval}"
    # delete any existing records in this interval
    total = 0
    @@levels.times do |level|
      begin_code = BinnedSample.bin(interval.begin,level)
      end_code = BinnedSample.bin(interval.end,level)
      deleted = BinnedSample.delete_all([
        'binCode >= ? and binCode < ?',begin_code,end_code])
      puts "Deleted #{sprintf '%5d',deleted} bins at level #{level} with " +
        "codes [#{sprintf '%08x',begin_code},#{sprintf '%08x',end_code})"
      total += deleted
    end
    puts "Deleted a total of #{total} BinnedSample records"
    # modify the Level class to use a custom save action
    ::Accumulator::Level.class_eval do
      @@rebuild_total = 0
      @@rebuild_row_data = [ ]
      alias original_save save
      def save(partial=false)
        raise "Internal Error: found existing bin " +
          "#{sprintf '%08x',@pending.binCode}" if @pending
        return if partial
        @@rebuild_row_data << "(#{@netID},#{@code},#{@count},#{@bins.join(',')})"
        @@rebuild_total += 1
      end
      def self.rebuild_total
        @@rebuild_total
      end
      def self.rebuild_row_data
        data_string = @@rebuild_row_data.join(',')
        @@rebuild_row_data.clear
        return data_string
      end
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
        ##raise "Sample outside of interval at #{s.created_at.localtime}" unless
        ##  interval.include? s.created_at
        Accumulator.accumulate s
      end
      # flush the bins in memory if this is the last batch
      Accumulator.flush_all if samples.length < batch_size
      # write out all of the new bins finished so far
      BinnedSample.connection.execute batch_sql+Level.rebuild_row_data
      # get ready for the next batch
      count += samples.length
      batch_number += 1
      puts "Binned #{count} samples after batch #{batch_number}"
    end until samples.length < batch_size
    puts "Created a total of #{Level.rebuild_total} BinnedSample records"
    # restore the Level class
    ::Accumulator::Level.class_eval do
      alias save original_save
    end
  end
  
  def self.validate(at)
    # find the top-level bin interval containing the specified time
    top_code = BinnedSample.bin(at,@@levels-1)
    interval = BinnedSample.interval_for_code(top_code)
    puts "Validating #{interval}"
    counts = { }
    @@levels.times do |level|
      begin_code = BinnedSample.bin(interval.begin,level)
      end_code = BinnedSample.bin(interval.end,level)
      BinnedSample.find(:all,:readonly=>true,:conditions=>[
        'binCode >= ? and binCode < ?',begin_code,end_code]).each do |bin|
        netID = bin.networkID
        counts[netID] = Array.new(@@levels) {0} unless counts.has_key? netID
        counts[netID][level] += bin.binCount
      end
    end
    counts.each do |netID,level_counts|
      1.upto(@@levels-1) do |level|
        next if level_counts[level] == level_counts[0]
        puts "Found invalid counts for netID #{netID}: #{level_counts.join ','}"
        break
      end
    end
    nil
  end
  
end
