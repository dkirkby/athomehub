class BinnedSample < ActiveRecord::Base

  # window size by zoom level
  @@window_size = [ 2.minutes, 10.minutes, 1.hour, 6.hours, 1.day, 1.week, 4.weeks, 16.weeks ]

  # bin size by zoom level
  @@bin_size = [ 10.seconds, 30.seconds, 3.minutes, 15.minutes, 1.hour, 6.hours, 1.day, 1.week ]

  # epoch for calculating bin indices
  @@epoch = Time.utc(2010).to_i

  def self.code(at,zoom_level)
    # calculates the bin code corresponding to the specified time
    raise 'Zoom level must be 0-7' unless (0..7) === zoom_level.to_i
    index = (at.utc.to_i - @@epoch)/@@bin_size[zoom_level.to_i]
    return (zoom_level << 28) | index
  end

end
