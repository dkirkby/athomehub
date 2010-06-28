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
    @dump.samples.each_index do |k|
      @data[k] = [ 200*k, @dump.samples[k] ]
    end
    # unpack the analysis header (multi-byte values from device are little-endian)
    binary = "\0\0\0\0\0\0\0\0\0\0\0"
    binary.length.times do |k|
      binary[k] = @dump.header[2*k,2].hex
    end
    case @dump.source
    when 0,1
      # powerAnalysis
      keys = [:nClipped,:currentComplexity,:currentRMS,:currentPhase,:relativePhase]
      values = binary.unpack("CCevv")
      @results = Hash[*keys.zip(values).flatten]
      # the model displays a 60Hz function with the fitted RMS and phase
      amplitude = Math.sqrt(2)*@results[:currentRMS]
      tzero = @results[:currentPhase]
      offset = @results[:relativePhase]
      mean = @dump.samples.sum/@dump.samples.length
      @model = [ ]
      250.times do |k|
        t = 200*k # microseconds
        # insert a fiducial spike before the next point?
        if (t-offset).modulo(@@micros_per_120Hz) < 200 then
          tmark = t-100
          @model << [tmark,mean+amplitude] << [tmark,mean-amplitude]
        end
        @model << [t, mean + amplitude*Math.sin(@@omega*(t-tzero))]
      end
    when 4
      # phaseAnalysis
      keys = [:moment1,:moment0,:voltagePhase]
      values = binary.unpack("VVv")
      @results = Hash[*keys.zip(values).flatten]
      # the model has spikes at the fiducial signal centroids
      @model = [ [0,0] ]
      t = @results[:voltagePhase]
      while t < 50000 do
        @model << [t-1,0] << [t,1024] << [t+1,0]
        t += @@micros_per_120Hz
      end
      @model << [50000,0]
    else
      @model = [ ]
      @results = { }
    end
    respond_to do |format|
      format.html
      format.text { render :text=> dump_raw_samples }
    end
  end
  
protected

  @@omega = 2*Math::PI*60/1e6
  @@micros_per_120Hz = 1e6/120

  def dump_raw_samples
    # Dumps raw sample data suitable for gnuplot and offline analysis
    dump = [ "# #{@dump.micros}" ]
    @data.each do |row|
      dump << "#{row[0]} #{row[1]}"
    end
    dump.join "\n"
  end

end
