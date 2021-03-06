class Engineering::BinnedController < Engineering::ApplicationController

  before_filter :valid_nid
  before_filter :valid_ival,:only=>:bydate
  before_filter :valid_window,:only=>:window

  def window
    @begin_at = @window_begin
    @end_at = @window_end
    make_plots
  end

  def bydate
    make_plots
  end
    
protected

  def make_plots
    @binnedPlots = {
      :temperature => [ ],
      :lighting => [ ],
      :artificial => [ ],
      :lightFactor => [ ],
      :power => [ ],
      :energy => [ ],
      :powerFactor => [ ],
      :complexity => [ ],
    }
    # loop over zoom levels
    BinnedSample.zoom_levels.times do |zoom_level|
      # find the range of codes corresponding to the requested interval
      first_code = BinnedSample.bin(@begin_at,zoom_level)
      last_code = BinnedSample.bin(@end_at,zoom_level)
      bin_size = BinnedSample.size(zoom_level)
      # don't include zoom levels with too many bins
      next if last_code - first_code > 300
      # initialize arrays for plot values
      tval,tval_energy = [ ],[ ]
      temp,light,art,lf,pwr,energy,pf,cmplx = [ ],[ ],[ ],[ ],[ ],[ ],[ ],[ ]
      binned = BinnedSample.find_all_by_networkID(@config.networkID,
        :conditions=>['binCode >= ? and binCode <= ?',first_code,last_code])
      binned.each do |bin|
        # save the interval midpoint as this bin's timestamp
        ival = bin.interval
        midpt = ival.begin + bin_size/2
        next unless midpt >= @begin_at and midpt < @end_at
        tval << 1e3*(midpt.to_i + midpt.utc_offset)
        temp << bin.temperature
        light << bin.lighting
        art << bin.artificial
        lf << bin.lightFactor
        pwr << bin.power
        pf << bin.powerFactor
        cmplx << bin.complexity
        if bin.energyUsage then
          tval_energy << 1e3*(ival.end.to_i + ival.end.utc_offset)
          energy << bin.energyUsage
        end
      end
      next unless tval.length > 0
      label = "Zoom-#{zoom_level} #{BinnedSample.size_as_words(zoom_level)}"
      @binnedPlots[:temperature] << { :data => tval.zip(temp), :label => label }
      @binnedPlots[:lighting] << { :data => tval.zip(light), :label => label }
      @binnedPlots[:artificial] << { :data => tval.zip(art), :label => label }
      @binnedPlots[:lightFactor] << { :data => tval.zip(lf), :label => label }
      @binnedPlots[:power] << { :data => tval.zip(pwr), :label => label }
      @binnedPlots[:energy] << { :data => tval_energy.zip(energy), :label => label }
      @binnedPlots[:powerFactor] << { :data => tval.zip(pf), :label => label }
      @binnedPlots[:complexity] << { :data => tval.zip(cmplx), :label => label }
    end
  end

end
