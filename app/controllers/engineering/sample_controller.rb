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
      samples = Sample.find(:all,:conditions=>['networkID=?',@config.networkID],
        :limit=>@n,:order=>'id DESC',:readonly=>true)
    else
      samples = Sample.find(:all,:limit=>@n,:order=>'id DESC',:readonly=>true)
    end
    prepare configs,samples
    respond_to do |format|
      format.html
      format.text { render :text=> dump_by_device }
    end
  end

  def bydate
    # use configs that were active at the end of the requested interval
    configs = DeviceConfig.latest(@end_at)
    # fetch samples from the requested interval and filter on networkID if requested
    if @config then
      samples = Sample.find(:all,:order=>'created_at DESC',:readonly=>true,
        :conditions=>['created_at > ? and created_at <= ? and networkID=?',
          @begin_at,@end_at,@config.networkID])
    else
      samples = Sample.find(:all,:order=>'created_at DESC',:readonly=>true,
        :conditions=>['created_at > ? and created_at <= ?',@begin_at,@end_at])
    end
    prepare configs,samples
    respond_to do |format|
      format.html
      format.text { render :text=> dump_by_device }
    end
  end
  
protected

  def prepare(configs,samples)
    # prepare to build (t,y) arrays for plotting
    tz_offset = @at.localtime.utc_offset
    tval,temp,light,art,lf,power,pf,cmplx = { },{ },{ },{ },{ },{ },{ },{ }
    # make a hash of configs keyed on the netID and key the plot data on netID
    config_lookup = { }
    configs.each do |c|
      netID = c.networkID
      config_lookup[netID] = c
      tval[netID] = [ ]
      temp[netID] = [ ]
      light[netID] = [ ]
      art[netID] = [ ]
      lf[netID] = [ ]
      power[netID] = [ ]
      pf[netID] = [ ]
      cmplx[netID] = [ ]
    end
    # prepare to build an array of [config,sample] entries
    @samples = [ ]
    # build the arrays now
    samples.each do |s|
      netID = s.networkID
      # rescale temperature to degF (but no self-heating correction applied)
      s.temperature = 1e-2*s.temperature
      @samples << [ config_lookup[s.networkID],s ]
      # convert the sample timestamp to microseconds in the local timezone
      tval[netID] << 1e3*(s.created_at.to_i + tz_offset)
      temp[netID] << s.temperature
      light[netID] << s.lighting
      art[netID] << s.artificial
      lf[netID] << s.lightFactor
      power[netID] << s.power
      pf[netID] << s.powerFactor
      cmplx[netID] << s.complexity
    end
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
  
  def dump_by_device
    # initialize the data dump we will return
    dump = [ ]
    # loop over @samples, building separate arrays for each device
    by_device = { }
    @samples.each do |s|
      # create a new empty array when we first see a device
      if not by_device.has_key? s.networkID then
        by_device[s.networkID] = [ ]
      end
      # append this sample
      by_device[s.networkID] << s
    end
    # dump the data by device with timestamps in localtime seconds since epoch
    offset = Time.now.utc_offset
    by_device.each do |id,data|
      dump << "# Network ID #{id} has #{data.length} samples"
      data.each do |s|
        dump << sprintf("%d %f %d %f %6d %6d %7.2f",
          s.created_at.to_i+offset,
          s.lighting,s.artificial,s.lightFactor,s.power,s.powerFactor,s.complexity,
          1e-2*s.temperature)
      end
      # insert two blank lines between devices
      dump << "" << ""
    end
    dump.join "\n"
  end
  
end
