class Engineering::DumpController < Engineering::ApplicationController

  before_filter :valid_n,:only=>:recent
  before_filter :valid_ival,:only=>:bydate
  
  def recent
    @count = BufferDump.count
    @dumps = BufferDump.find(:all,:limit=>@n,:order=>'id DESC',:readonly=>true)
  end

  def bydate
    @dumps = BufferDump.find(:all,
      :conditions=>['created_at > ? and created_at <= ?',@begin_at,@end_at],
      :order=>'created_at DESC',:readonly=>true)
  end
  
  def samples
    # Samples are actually timestamp,ADC pairs. Unwrap into a 2-column array here.
    # We also reconstruct the high-order bits of the 8-bit timestamp counter.
    dump= BufferDump.find(params['id'])
    @samples = [ ]
    cycle = 0
    last_timestamp = 0
    (dump.samples.length/2).times do |k|
      timestamp,adc_value = dump.samples[2*k], dump.samples[2*k+1]
      cycle += 1 if timestamp < last_timestamp
      last_timestamp = timestamp
      @samples << [ 256*cycle + timestamp , adc_value ]
    end
    respond_to do |format|
      format.html
      format.text { render :text=> @samples.inspect }
    end
  end

end
