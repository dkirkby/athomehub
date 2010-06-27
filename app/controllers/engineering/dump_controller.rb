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
    @dump= BufferDump.find(params['id'])
    respond_to do |format|
      format.html
      format.text { render :text=> dump_raw_samples }
    end
  end
  
protected

  def dump_raw_samples
    # Dumps raw sample data suitable for gnuplot and offline analysis
    dump = [ "# #{@dump.micros}" ]
    @dump.samples.each_index do |k|
      dump << "#{200*k} #{@dump.samples[k]}"
    end
    dump.join "\n"
  end

end
