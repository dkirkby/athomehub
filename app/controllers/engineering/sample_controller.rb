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
    prepare DeviceConfig.latest,
      Sample.find(:all,:limit=>@n,:order=>'id DESC',:readonly=>true)
    respond_to do |format|
      format.html
      format.text { render :text=> dump_by_device }
    end
  end

  def bydate
    # use configs that were active at the end of the requested interval
    prepare DeviceConfig.latest(@end_at),
      Sample.find(:all,:order=>'created_at DESC',:readonly=>true,
        :conditions=>['created_at > ? and created_at <= ?',@begin_at,@end_at])
    respond_to do |format|
      format.html
      format.text { render :text=> dump_by_device }
    end
  end
  
protected

  def prepare(configs,samples)
    # make a hash of configs keyed on the network ID
    config_lookup = { }
    configs.each do |c|
      config_lookup[c.networkID] = c
    end
    # prepare to build (t,y) arrays for plotting
    tz_offset = @at.localtime.utc_offset
    tval,temp,light,art,lf,power,pf,cmplx = [ ],[ ],[ ],[ ],[ ],[ ],[ ],[ ]
    # prepare to build an array of [config,sample] entries
    @samples = [ ]
    # build the arrays now
    samples.each do |s|
      @samples << [ config_lookup[s.networkID],s ]
      # convert the sample timestamp to microseconds in the local timezone
      tval << 1e3*(s.created_at.to_i + tz_offset)
      # convert temperature to degrees F (no self-heating correction applied)
      temp << 1e-2*s.temperature
      # the remaining fields are displayed without any transformation
      light << s.lighting
      art << s.artificial
      lf << s.lightFactor
      power << s.power
      pf << s.powerFactor
      cmplx << s.complexity
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
