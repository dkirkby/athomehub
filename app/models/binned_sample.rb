class BinnedSample < ActiveRecord::Base
  
  include Measured

  # bin size by zoom level: must divide evenly into half of the window size
  # and the bin size of the next zoom level.
  @@bin_size = [
    10.seconds, 30.seconds, 3.minutes, 15.minutes, 1.hour, 6.hours, 1.day, 1.week ]

  # window size by zoom level
  @@window_half_size = [
    2.minutes, 10.minutes, 30.minutes, 3.hours, 12.hours, 84.hours, 2.weeks, 10.weeks ]
    
  # bin formats (passed to javascript flot library)
  @@bin_format = [
    "%h:%M%p","%h:%M%p","%h:%M%p","%h%p","%h%p","%d-%b","%d-%b","%d-%b"
  ]
  
  # minimum plot tick spacing (passed to javascript flot library)
  @@min_tick_size = [
    [1,"minute"],[5,"minute"],[10,"minute"],[1,"hour"],
    [4,"hour"],[1,"day"],[4,"day"],[7,"day"]
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
  
  # Returns bins recorded for the specified networkID at the specified zoom level
  # and up to the specified utc time which defaults to now.
  named_scope :for_networkID, lambda { |*args|
    networkID,zoom_level = args[0..1]
    begin_code = (zoom_level << 28)
    if args.length > 2 then
      end_code = BinnedSample.bin(args.last,zoom_level)
    else
      end_code = (begin_code|0x0fffffff)
    end
    {
      :order => 'binCode ASC',
      :conditions => [ 'networkID = ? and binCode >= ? and binCode <= ?',
        networkID,begin_code,end_code],
      :readonly => true
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
  
  def theEnergyCost
    energyUsage*ATHOME['energy_cost'] if energyUsage
  end
  
  def displayEnergyCost
    autoRangeCost theEnergyCost
  end
  
  def displayEnergyUsage
    autoRange energyUsage,'kWh'
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

  def self.interval_for_code(code)
    # Returns a non-exclusive range [a,b) of Times corresponding
    # to the specified bin's time interval.
    zoom_level = (code >> 28)
    bin_index = (code & 0x0fffffff)
    size = @@bin_size[zoom_level]
    begin_at = BinnedSample.at(bin_index*size)
    Range.new(begin_at,begin_at+size,true) # [begin,end)    
  end

  def interval
    # Returns a non-exclusive range [a,b) of Times corresponding
    # to this bin's time interval. Implemented with caching.
    @interval ||= begin
      BinnedSample.interval_for_code(self.binCode)
    end
  end
  
  def self.window_info(zoom_level,window_index)
    # Calculate the range [a,b) of UTC timestamps corresponding to the
    # specified window.
    raise 'Zoom level must be 0-7' unless (0..7) === zoom_level
    size = @@bin_size[zoom_level]
    half_window = @@window_half_size[zoom_level]
    midpt_elapsed = (window_index+1)*half_window
    begin_at = BinnedSample.at(midpt_elapsed-half_window)
    end_at= BinnedSample.at(midpt_elapsed + half_window)
    # Calculate the indices of windows centered on this one
    # at zoom levels +/-1 (or the original window_index if this zoom
    # level is already the min/max allowed)
    zoom_in = (zoom_level > 0) ?
      midpt_elapsed/@@window_half_size[zoom_level-1]-1 : window_index
    zoom_out = (zoom_level < 7) ?
      midpt_elapsed/@@window_half_size[zoom_level+1]-1 : window_index
    # Prepare a formatted label describing this window's timespan
    title = Time.range_as_string(begin_at,end_at,' &ndash; ')
    # Lookup the flot format to use for time axis labels
    format = @@bin_format[zoom_level]
    # Lookup the minimum tick size to use for the time axis labels
    min_ticks = @@min_tick_size[zoom_level]
    return [title,format,min_ticks,begin_at,end_at,zoom_in,zoom_out]
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
  
  def self.array_order
    [
      :temperatureSum,
      :lightingSum,
      :artificialSum,
      :lightFactorSum,
      :powerSum,
      :powerFactorSum,
      :complexitySum,
      :energyUsage
    ]
  end
  
  def values_as_array
    [
      self.temperatureSum,
      self.lightingSum,
      self.artificialSum,
      self.lightFactorSum,
      self.powerSum,
      self.powerFactorSum,
      self.complexitySum,
      self.energyUsage
    ]
  end
  
  def values_from_array!(values)
    self.temperatureSum,
    self.lightingSum,
    self.artificialSum,
    self.lightFactorSum,
    self.powerSum,
    self.powerFactorSum,
    self.complexitySum,
    self.energyUsage = values
  end

protected

  # epoch for calculating bin indices: determines the natural alignment of bins
  # and so should be naturally aligned in local (non-DST) time, i.e., midnight
  # on a Sunday. The epoch must be chronoloogically before the first bin that
  # might ever be used.
  @@epoch = Time.local(2010,1,3).to_i # Sun Jan 03 00:00:00 2010

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
    elapsed += 3600 if at.localtime.isdst # BinnedSample.is_dst? at
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
    at += 3600 unless at.localtime.isdst # BinnedSample.is_dst? at
    return at
  end

end
