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
    @dump= BufferDump.find(params['id'])
    # fill a 2 x 250 table of (time,adc) values
    @data = Array.new 250
    @model = Array.new 250
    @dump.samples.each_index do |k|
      @data[k] = [ 200*k, @dump.samples[k] ]
      @model[k] = [ 200*k, 0.0 ]
    end
    # unpack the analysis header
    binary = "\0\0\0\0\0\0\0\0\0\0\0"
    binary.length.times do |k|
      binary[k] = @dump.header[2*k,2].hex
    end
    if (0..1).include? @dump.source then
      # powerAnalysis
      keys = [:nClipped,:currentComplexity,:currentRMS,:currentPhase,:relativePhase]
      @results = Hash[*keys.zip(binary.unpack("CCevv")).flatten]
      # the model displays a 60Hz function with the fitted RMS and phase
      amplitude = Math.sqrt(2)*@results[:currentRMS]
      tzero = @results[:currentPhase]
      mean = @dump.samples.sum/@dump.samples.length
      250.times do |k|
        t = @model[k][0]
        @model[k][1] = mean + amplitude*Math.sin(@@omega*(t-tzero))
      end
    end
    respond_to do |format|
      format.html
      format.text { render :text=> dump_raw_samples }
    end
  end
  
protected

  @@omega = 2*Math::PI*60/1e6

  def dump_raw_samples
    # Dumps raw sample data suitable for gnuplot and offline analysis
    dump = [ "# #{@dump.micros}" ]
    @data.each do |row|
      dump << "#{row[0]} #{row[1]}"
    end
    dump.join "\n"
  end

end
