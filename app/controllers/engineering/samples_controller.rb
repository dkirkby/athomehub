class Engineering::SamplesController < Engineering::ApplicationController

  before_filter :valid_n,:only=>:recent
  before_filter :valid_ival,:only=>:bydate

  def recent
    @count = Sample.count
    @samples = Sample.find(:all,:limit=>@n,:order=>'id DESC',:readonly=>true)
  end

  def bydate
    @samples = Sample.find(:all,
      :conditions=>['created_at > ? and created_at <= ?',@begin_at,@end_at],
      :order=>'created_at DESC',:readonly=>true)
    respond_to do |format|
      format.html
      format.text { render :text=> dump_by_device }
    end
  end
  
  def last
    @samples = Sample.find(:all,:group=>'networkID',
      :conditions=>'networkID IS NOT NULL',:readonly=>true)
  end
  
protected
  
  def dump_by_device
    # initialize the data dump we will return
    dump = [ ]
    # loop over @samples, building separate arrays for each device
    begin_at = Time.now
    by_device = { }
    @samples.each do |s|
      # create a new empty array when we first see a device
      if not by_device.has_key? s.networkID then
        by_device[s.networkID] = [ ]
      end
      # append this sample
      by_device[s.networkID] << s
      # update the earliest sample time seen
      begin_at = s.created_at if s.created_at < begin_at
    end
    # dump the data by device
    by_device.each do |id,data|
      dump << "# Network ID #{id} has #{data.length} samples"
      data.each do |s|
        # convert timestamp to hours since first sample
        offset = (s.created_at.to_i - begin_at.to_i)/3600.0
        dump << sprintf("%10.5f %6d %6d %6d %6d %7.2f",offset,
          s.lighting,s.artificial,s.lighting2,s.artificial2,1e-2*s.temperature)
      end
      # insert two blank lines between devices
      dump << "" << ""
    end
    dump.join "\n"
  end
  
end
