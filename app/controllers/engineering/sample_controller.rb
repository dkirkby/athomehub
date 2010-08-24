class Engineering::SampleController < Engineering::ApplicationController

  before_filter :valid_n,:only=>:recent
  before_filter :valid_ival,:only=>:bydate
  before_filter :optional_nid, :only=>[:recent,:bydate]

  def index
    @samples = [ ]
    # use configs for the requested @at time
    DeviceConfig.latest(@at).find(:all,:order=>'serialNumber ASC').each do |config|
      next unless config.enabled
      # find most recent sample for each config at the requested @at time
      sample = Sample.for_networkID(config.networkID,@at).last
      @samples << [config,sample] if sample
    end
  end

  def recent
    @count = Sample.count
    # use the most recent configs
    configs = DeviceConfig.latest
    # fetch the most recent samples and filter on networkID if requested
    if @config then
      samples = Sample.for_networkID(@config.networkID).recent(@n)
    else
      samples = Sample.recent(@n)
    end
    prepare configs,samples
    respond_to do |format|
      format.html
      format.text { render :text=> render_as_text }
    end
  end

  def bydate
    # use configs that were active at the end of the requested interval
    configs = DeviceConfig.latest(@end_at)
    # fetch samples from the requested interval and filter on networkID if requested
    if @config then
      samples = Sample.for_networkID(@config.networkID).bydate(@begin_at,@end_at)
    else
      samples = Sample.bydate(@begin_at,@end_at)
    end
    prepare configs,samples
    respond_to do |format|
      format.html
      format.text { render :text=> render_as_text }
    end
  end
  
protected

  def prepare(configs,samples)
    # prepare to build (t,y) arrays for plotting
    tz_offset = @at.localtime.utc_offset
    tval,temp,light,art,lf,power,pf,cmplx = { },{ },{ },{ },{ },{ },{ },{ }
    # make a hash of configs keyed on the netID and key the plot data on netID
    @config_lookup = { }
    configs.each do |c|
      netID = c.networkID
      next if @config and @config.networkID != netID
      @config_lookup[netID] = c
      tval[netID] = [ ]
      temp[netID] = [ ]
      light[netID] = [ ]
      art[netID] = [ ]
      lf[netID] = [ ]
      power[netID] = [ ]
      pf[netID] = [ ]
      cmplx[netID] = [ ]
    end
    # build arrays of sample data for plotting and text dumping
    samples.each do |s|
      netID = s.networkID
      # convert the sample timestamp to microseconds in the local timezone
      tval[netID] << 1e3*(s.created_at.to_i + tz_offset)
      # rescale temperature to degF (but no self-heating correction applied)
      temp[netID] << 1e-2*s.temperature
      light[netID] << s.lighting
      art[netID] << s.artificial
      lf[netID] << s.lightFactor
      power[netID] << s.power
      pf[netID] << s.powerFactor
      cmplx[netID] << s.complexity
    end
    # make the arrays global for render_as_text
    @arrays = [tval,temp,light,art,lf,power,pf,cmplx]
    # build plots suitable for display with the javascript flot library
    @samplePlots = {
      :temperature => [ ],
      :lighting => [ ],
      :artificial => [ ],
      :lightFactor => [ ],
      :power => [ ],
      :powerFactor => [ ],
      :complexity => [ ],
    }
    configs.each do |c|
      netID = c.networkID
      next if @config and @config.networkID != netID
      label = @template.format_serialNumber c.serialNumber
      @samplePlots[:temperature] <<
        { :data => tval[netID].zip(temp[netID]), :label => label }
      @samplePlots[:lighting] <<
        { :data => tval[netID].zip(light[netID]), :label => label }
      @samplePlots[:artificial] <<
        { :data => tval[netID].zip(art[netID]), :label => label }
      @samplePlots[:lightFactor] <<
        { :data => tval[netID].zip(lf[netID]), :label => label }
      @samplePlots[:power] <<
        { :data => tval[netID].zip(power[netID]), :label => label }
      @samplePlots[:powerFactor] <<
        { :data => tval[netID].zip(pf[netID]), :label => label }
      @samplePlots[:complexity] <<
        { :data => tval[netID].zip(cmplx[netID]), :label => label }
    end
  end
  
  def render_as_text
    # renders the raw data in a text format suitable for gnuplot
    lines = [ ]
    tval,temp,light,art,lf,power,pf,cmplx = @arrays
    # loop over devices
    @config_lookup.each do |sn,c|
      # output the samples for each device in their own section
      netID = c.networkID
      lines << "# SN #{@template.format_serialNumber c.serialNumber} netID #{netID}"
      tval[netID].each_index do |k|
        lines << sprintf("%d %.2f %d %d %d %d %d %d",
          1e-3*tval[netID][k],temp[netID][k],light[netID][k],art[netID][k],
          lf[netID][k],power[netID][k],pf[netID][k],cmplx[netID][k])
      end
      # append two blank lines between devices
      lines << "" << ""
    end
    lines.join "\n"
  end
  
end
