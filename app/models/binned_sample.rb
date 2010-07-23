class BinnedSample < ActiveRecord::Base
  
  include Measured

  # window size by zoom level
  @@window_size = [
    2.minutes, 10.minutes, 1.hour, 6.hours, 1.day, 1.week, 4.weeks, 16.weeks ]

  # bin size by zoom level: must divide evenly into half of the window size
  # and the bin size of the next zoom level.
  ##
  ##?? How to handle the alignment of bins bigger than one hour with respect to
  ##?? daylight saving or other time zone shifts by a number hours ??
  ##
  @@bin_size = [
    10.seconds, 30.seconds, 3.minutes, 15.minutes, 1.hour, 6.hours, 1.day, 1.week ]

  # number of bins per half window by zoom level
  @@bins_per_half_window = @@window_size.zip(@@bin_size).map {|wb| wb[0]/(2*wb[1]) }

  # epoch for calculating bin indices: determines the natural alignment of bins
  # and so should be naturally aligned in local (non-DST) time. The epoch must
  # be chronoloogically before the first bin that might ever be used.
  @@epoch = Time.local(2010).to_i

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
      self.interval.include? sample.created_at.to_i
  end

  def interval
    # Returns a non-exclusive range [a,b) of UTC timestamps corresponding
    # to this bin's time interval. Implemented with caching.
    @interval ||= begin
      zoom_level = (binCode >> 28)
      bin_index = (binCode & 0x0fffffff)
      size = @@bin_size[zoom_level]
      # calculate the number of seconds elapsed since the epoch
      begin_at = @@epoch + bin_index*size
      # correct for DST if necessary (since the epoch is non-DST)
      ##begin_at -= 3600 if Time.at(begin_at).dst?
      end_at = begin_at + size.to_i
      Range.new(begin_at,end_at,true) # [begin,end)      
    end
  end

  def self.bin(at,zoom_level)
    # Returns the bin code corresponding to the specified time.
    raise 'Zoom level must be 0-7' unless (0..7) === zoom_level
    # Calculate the number of seconds elapsed since the epoch.
    elapsed = at.to_i - @@epoch
    # Spring forward if we are on daylight savings: this will create
    # an hour gap in the spring and map two hours of samples into a
    # one-hour bin in the fall.
    ##elapsed += 3600 if at.dst?
    # Integer division by the zoom level's bin size in seconds give the bin index
    bin_index = elapsed/@@bin_size[zoom_level]
    # Combine the zoom level and bin index into a single 32-bit code
    return (zoom_level << 28) | bin_index
  end

  def self.accumulate(sample)
    # Accumulates one new sample at all zoom levels simultaneously.
    @@last_id = { } unless defined? @@last_id
    @@accumulators = { } unless defined? @@accumulators
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
      at = sample.created_at.to_i
      spanned = false
      accumulators = @@accumulators[netID]
      accumulators.each_index do |zoom_level|
        bin = accumulators[zoom_level]
        if not spanned
          # this sample did not fit into a smaller zoom level bin so might
          # not fit into the bin at this zoom level either
          if at < bin.interval.end then
            # accumulate this sample (using send to call protected from class method)
            bin.send :add_sample,sample
            # the active bins at all larger zoom levels must, by construction,
            # span this sample
            spanned = true
          else
            # save the active bin
            bin.save
            # create a new bin containing only this sample
            code = bin(sample.created_at,zoom_level)
            accumulators[zoom_level] = new_for_sample(code,sample)
          end
        else
          # accumulate this sample (using send to call protected from class method)
          bin.send :add_sample,sample
        end
      end
    end
    return
  end

protected

  # Tabulate the US daylight savings times for each year (not valid in AZ,HI)
  @@dst_ranges = [
      [Time.local(2010,3,14,2),Time.local(2010,11,7,2)],
      [Time.local(2011,3,13,2),Time.local(2011,11,6,2)]
    ]

  def self.new_for_sample(code,sample)
    # Returns a new bin for the specified code containing one sample.
    # Method is protected since we do not check the consistency of code
    # and sample.created_at.
    new({
      :binCode => code,
      :networkID => sample.networkID,
      :temperatureSum => sample.temperature,
      :lightingSum => sample.lighting,
      :artificialSum => sample.artificial,
      :lightFactorSum => sample.lightFactor,
      :powerSum => sample.power,
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
    self.lightingSum += sample.lighting
    self.artificialSum += sample.artificial
    self.lightFactorSum += sample.lightFactor
    self.powerSum += sample.power
    self.powerFactorSum += sample.powerFactor
    self.complexitySum += sample.complexity
    self.binCount += 1
  end

end
