class BinnedSample < ActiveRecord::Base
  
  include Measured

  # bin size by zoom level: must divide evenly into half of the window size
  # and the bin size of the next zoom level.
  @@bin_size = [
    10.seconds, 30.seconds, 3.minutes, 15.minutes, 1.hour, 6.hours, 1.day, 1.week ]

  # window size by zoom level
  @@window_half_size = [
    1.minute, 5.minutes, 30.minutes, 3.hours, 12.hours, 84.hours, 2.weeks, 8.weeks ]
    
  @@endpt_format = [
    "%l:%M%P","%l:%M%P","%l:%M%P","%l%P","%a %l%P","%a %l%P","%a %l%P","%a %l%P"
  ]

  # find all binned samples at the specified zoom level in increasing time order
  named_scope :for_zoom, lambda { |zoom_level|
    base = (zoom_level<<28)
    {
      :order => 'binCode ASC',
      :conditions => [ 'binCode >= ? and binCode <= ?',base,(base|0x0fffffff) ]
    }
  }

  # find all binned samples in the specified window in increasing time order
  named_scope :for_window, lambda { |zoom_level,window_index|
    raise 'Zoom level must be 0-7' unless (0..7) === zoom_level
    bins_per_half_window = @@window_half_size[zoom_level]/@@bin_size[zoom_level]
    begin_code = (zoom_level<<28) | (window_index*bins_per_half_window)
    end_code = begin_code + 2*bins_per_half_window - 1
    {
      :order => 'binCode ASC',
      :conditions => ['binCode >= ? and binCode <= ?',begin_code-1,end_code+1]
    }
  }

  def temperature
    temperatureSum/binCount if binCount > 0
  end

  def lighting
    lightingSum/binCount if binCount > 0
  end

  def artificial
    artificialSum/binCount if binCount > 0
  end

  def lightFactor
    lightFactorSum/binCount if binCount > 0
  end

  def power
    powerSum/binCount if binCount > 0
  end

  def powerFactor
    powerFactorSum/binCount if binCount > 0
  end

  def complexity
    complexitySum/binCount if binCount > 0
  end

  def self.zoom_levels
    @@bin_size.length
  end
  
  def span?(sample)
    # Tests if the specified sample falls within this bin based on its
    # network ID and timestamp. This method does NOT test if the sample
    # has already been accumulated in this bin.
    self.networkID == sample.networkID and
      self.interval.include? sample.created_at
  end

  def interval
    # Returns a non-exclusive range [a,b) of UTC timestamps corresponding
    # to this bin's time interval. Implemented with caching.
    @interval ||= begin
      zoom_level = (binCode >> 28)
      bin_index = (binCode & 0x0fffffff)
      size = @@bin_size[zoom_level]
      begin_at = BinnedSample.at(bin_index*size)
      end_at = begin_at + size
      Range.new(begin_at,end_at,true) # [begin,end)      
    end
  end
  
  def self.window_info(zoom_level,window_index)
    # Returns the range [a,b) of UTC timestamps corresponding to the
    # specified window and the indices of windows centered on this one
    # at zoom levels +/-1 (or the original window_index if this zoom
    # level is already the min/max allowed)
    raise 'Zoom level must be 0-7' unless (0..7) === zoom_level
    size = @@bin_size[zoom_level]
    half_window = @@window_half_size[zoom_level]
    begin_at = window_index*half_window
    midpt_at = begin_at + half_window
    end_at= begin_at + 2*half_window
    zoom_in = (zoom_level > 0) ?
      midpt_at/@@window_half_size[zoom_level-1]-1 : window_index
    zoom_out = (zoom_level < 7) ?
      midpt_at/@@window_half_size[zoom_level+1]-1 : window_index
    return [BinnedSample.at(begin_at),BinnedSample.at(end_at),zoom_in,zoom_out]
  end

  def self.size(zoom_level)
    # Returns the bin size in seconds at the specified zoom level
    raise 'Zoom level must be 0-7' unless (0..7) === zoom_level
    @@bin_size[zoom_level]
  end

  def self.size_as_words(zoom_level)
    size = BinnedSample.size(zoom_level)
    return "#{size/604800}w" if size.modulo(604800) == 0
    return "#{size/86400}d" if size.modulo(86400) == 0
    return "#{size/3600}h" if size.modulo(3600) == 0
    return "#{size/60}m" if size.modulo(60) == 0
    return "#{size}s"
  end
  
  def self.window_as_words(zoom_level,window_index)
    raise 'Zoom level must be 0-7' unless (0..7) === zoom_level
    size = @@bin_size[zoom_level]
    half_window = @@window_half_size[zoom_level]
    begin_elapsed = window_index*half_window
    begin_at = BinnedSample.at(begin_elapsed)
    midpt_at = BinnedSample.at(begin_elapsed + half_window)
    end_at= BinnedSample.at(begin_elapsed + 2*half_window)
    sprintf "%s&nbsp;&ndash;&nbsp;%s %s",
      BinnedSample.strftime(begin_at,@@endpt_format[zoom_level]),
      BinnedSample.strftime(end_at,@@endpt_format[zoom_level]),
      BinnedSample.strftime(midpt_at,"%a %e %b %Y")
  end

  def self.strftime(at,format)
    # converts a Time to a DateTime ignoring usecs
    # see http://stackoverflow.com/questions/279769/convert-to-from-datetime-and-time-in-ruby
    offset = Rational(at.utc_offset,86400)
    dt = DateTime.new(at.year,at.month,at.day,at.hour,at.min,at.sec,offset)
    dt.strftime format
  end

  def self.bin(at,zoom_level)
    # Returns the bin code corresponding to the specified time.
    raise 'Zoom level must be 0-7' unless (0..7) === zoom_level
    bin_index = self.elapsed(at)/@@bin_size[zoom_level]
    # Combine the zoom level and bin index into a single 32-bit code
    return (zoom_level << 28) | bin_index
  end
  
  def self.window(at,zoom_level)
    raise 'Zoom level must be 0-7' unless (0..7) === zoom_level
    # the -1 below puts the specified time in the right half of the full window
    window_index = self.elapsed(at)/@@window_half_size[zoom_level] - 1
    # calcuate the bin index of the left-most bin in the full window
    # bin_index = window_index*@@bin_size[zoom_level]/@@window_half_size[zoom_level]
  end
  
  def self.first(nid,zoom_level)
    raise 'Zoom level must be 0-7' unless (0..7) === zoom_level
    # find the first bin with data for nid at the specified zoom level
    bin = for_zoom(zoom_level).find_by_networkID(nid)
    return 0 unless bin
    # return the corresponding window index
    ((bin.binCode & 0x0fffffff)*@@bin_size[zoom_level])/@@window_half_size[zoom_level]
  end
  
  # Accumulates one new sample at all zoom levels simultaneously.
  def self.accumulate(sample)
    # first-time initialization
    if not defined? @@accumulators then
      @@last_id = { }
      @@accumulators = { }
      at_exit { BinnedSample.flush }
    end
    # have we seen this network ID yet?
    netID = sample.networkID
    if @@last_id.has_key? netID then
      # samples must be passed to this method in ascending ID order.
      raise "Samples must be accumulated in increasing ID order " +
        "(#{sample.id} < #{@@last_id[netID]})" unless sample.id > @@last_id[netID]
    end
    @@last_id[netID] = sample.id
    # have we seen this network ID before?
    if not @@accumulators.has_key?(netID) then
      # create the accumulators at each zoom level for this network ID
      at = sample.created_at
      @@accumulators[netID] = Array.new(@@bin_size.length) do |zoom_level|
        code = bin(at,zoom_level)
        find_by_networkID_and_binCode(netID,code) or new_for_sample(code,sample)
      end
    else
      # loop over the active bins for this networkID
      at = sample.created_at
      spanned = false
      auto_save = false
      accumulators = @@accumulators[netID]
      accumulators.each_index do |zoom_level|
        bin = accumulators[zoom_level]
        if not spanned
          # this sample did not fit into a smaller zoom level bin so might
          # not fit into the bin at this zoom level either
          if at < bin.interval.end then
            # accumulate this sample (using send to call protected from class method)
            bin.send :add_sample,sample
            # periodic auto-save?
            bin.save if auto_save
            # the active bins at all larger zoom levels must, by construction,
            # span this sample
            spanned = true
          else
            # save the active bin
            bin.save
            # create a new bin containing only this sample
            code = bin(at,zoom_level)
            accumulators[zoom_level] = new_for_sample(code,sample)
            # auto-save bins at larger zoom levels?
            auto_save = (zoom_level >= 1)
          end
        else
          # accumulate this sample (using send to call protected from class method)
          bin.send :add_sample,sample
          # periodic auto-save?
          bin.save if auto_save
        end
      end
    end
    return
  end
  
  def self.flush
    # flushes accumulation bins in memory
    puts "Flushing BinnedSamples in memory..."
    @@accumulators.each do |netID,bins|
      puts "Flushing #{bins.length} bins for network ID #{netID}"
      bins.each do |bin|
        bin.save
      end
    end
    @@accumulators = { }
  end

protected

  # epoch for calculating bin indices: determines the natural alignment of bins
  # and so should be naturally aligned in local (non-DST) time, i.e., midnight
  # on a Sunday. The epoch must be chronoloogically before the first bin that
  # might ever be used.
  @@epoch = Time.local(2010,1,3).to_i # Sun Jan 03 00:00:00 2010

  # Tabulate the US daylight savings times for each year
  @@dst_ranges = Time.local(2010,3,14,2).isdst ?
    [
      Range.new(Time.local(2010,3,14,2),Time.local(2010,11,7,2),true),
      Range.new(Time.local(2011,3,13,2),Time.local(2011,11,6,2),true)
    ] :
    [ ] # no daylight savings in AZ, HI
    
  # Returns the number of seconds elapsed since the epoch with adjustment for
  # daylight savings so that elapsed/3600 is correctly aligned when daylight
  # savings is in effect (this introduces a one hour gap in the spring and
  # maps two hours onto one in the fall). Specifically:
  #
  #   BinnedSample.elapsed(Time.local(2010,3,14,1)+0.hour)/3600%24 == 1
  #   BinnedSample.elapsed(Time.local(2010,3,14,1)+1.hour)/3600%24 == 3
  #   BinnedSample.elapsed(Time.local(2010,3,14,3))/3600%24 == 3
  #
  #   BinnedSample.elapsed(Time.local(2010,11,7,3)-0.hour)/3600%24 == 3
  #   BinnedSample.elapsed(Time.local(2010,11,7,3)-1.hour)/3600%24 == 2
  #   BinnedSample.elapsed(Time.local(2010,11,7,3)-2.hour)/3600%24 == 2
  #   BinnedSample.elapsed(Time.local(2010,11,7,3)-3.hour)/3600%24 == 1
  #   BinnedSample.elapsed(Time.local(2010,11,7,1))/3600%24 == 1
  #   
  def self.elapsed(at)
    elapsed = at.to_i - @@epoch
    @@dst_ranges.each do |range|
      return elapsed+3600 if range.include? at
      # quit now if all remaining ranges are in the future
      last if at <= range.end
    end
    return elapsed
  end
  
  # Returns the Time corresponding to the specified number of elapsed seconds
  # calculated according to self.elapsed. Note that self.elapsed is not
  # invertible during the one-hour "fall back" DST change over so the
  # algorithm used here maps 1-3am onto 1-2am, creating a hole from 2-3am.
  # Specifically, the elapsed times calculated above correspond to:
  #
  #   Sun Mar 14 01:00:00 -0800 2010
  #   Sun Mar 14 03:00:00 -0700 2010
  #   Sun Mar 14 03:00:00 -0700 2010
  #
  #   Sun Nov 07 03:00:00 -0800 2010
  #   Sun Nov 07 01:00:00 -0800 2010
  #   Sun Nov 07 01:00:00 -0800 2010
  #   Sun Nov 07 01:00:00 -0700 2010
  #   Sun Nov 07 01:00:00 -0700 2010
  #
  def self.at(elapsed)
    at = Time.at(@@epoch + elapsed - 3600)
    @@dst_ranges.each do |range|
      return at if range.include? at
      # quit now if all remaining ranges are in the future
      last if at <= range.end
    end
    return at + 3600
  end

  # An infinite float16 lighting or power value is saved in the Sample
  # table using database NULL and read back as ruby nil. Translate it
  # to the value below for the purposes of binning.
  @@float16_inf = 32768

  def self.new_for_sample(code,sample)
    # Returns a new bin for the specified code containing one sample.
    # Method is protected since we do not check the consistency of code
    # and sample.created_at.
    new({
      :binCode => code,
      :networkID => sample.networkID,
      :temperatureSum => sample.temperature,
      :lightingSum => (sample.lighting or @@float16_inf),
      :artificialSum => sample.artificial,
      :lightFactorSum => sample.lightFactor,
      :powerSum => (sample.power or @@float16_inf),
      :powerFactorSum => sample.powerFactor,
      :complexitySum => sample.complexity,
      :binCount => 1
    })
  end

  def add_sample(sample)
    # Adds the specified sample to this bin.
    # Method is protected since we do not check the consistency of our code
    # and networkID with sample.created_at and sample.networkID.
    self.temperatureSum += sample.temperature
    self.lightingSum += (sample.lighting or @@float16_inf)
    self.artificialSum += sample.artificial
    self.lightFactorSum += sample.lightFactor
    self.powerSum += (sample.power or @@float16_inf)
    self.powerFactorSum += sample.powerFactor
    self.complexitySum += sample.complexity
    self.binCount += 1
  end

end
