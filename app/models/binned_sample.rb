class BinnedSample < ActiveRecord::Base

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
  # and must be chronoloogically before the first bin that might ever be used.
  @@epoch = Time.utc(2010).to_i

  def self.bin(at,zoom_level)
    # Returns the bin code corresponding to the specified time.
    raise 'Zoom level must be 0-7' unless (0..7) === zoom_level
    bin_index = (at.utc.to_i - @@epoch)/@@bin_size[zoom_level]
    return (zoom_level << 28) | bin_index
  end

  def self.window(window_index,zoom_level)
    # Returns the bin code corresponding to the first bin of the indexed window.
    raise 'Zoom level must be 0-7' unless (0..7) === zoom_level
    # Successive windows overlap by 50%.
    return (zoom_level << 28) | window_index*@@bins_per_half_window[zoom_level]
  end
  
  def self.time(code)
    # Returns the UTC time corresponding to the specified bin code
    zoom_level = (code >> 28)
    bin_index = (code & 0x0fffffff)
    Time.at(@@epoch + bin_index*@@bin_size[zoom_level]).utc
  end
  
  def self.accumulate(sample)
  end

end
