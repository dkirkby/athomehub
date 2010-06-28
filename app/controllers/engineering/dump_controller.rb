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
    # unpack the analysis header
    @results = @dump.unpack_header
    case @dump.source
    when 0,1
      # powerAnalysis: model is 60Hz function with the fitted RMS and phase, with
      # vertical voltage-fiducial marks superimposed.
      amplitude = Math.sqrt(2)*@results[:currentRMS]
      tzero = @results[:currentPhase]
      offset = tzero-@results[:relativePhase]
      mean = @dump.samples.sum*1.0/@dump.samples.length
      fit = lambda {|t| mean + amplitude*Math.sin(@@omega*(t-tzero)) }
      @model = [ ]
      dt = 200 # microseconds
      250.times do |k|
        t = dt*k # microseconds
        # insert a fiducial spike before the next point?
        delta = (t-offset).modulo(@@micros_per_120Hz)
        if delta < dt then
          tmark = t-delta
          ymark = fit[tmark]
          @model << [tmark,ymark] << [tmark,mean+amplitude] << [tmark,mean-amplitude] << [tmark,ymark]
        end
        @model << [t,fit[t]]
      end
    when 4
      # phaseAnalysis: model shows voltage fiducial spikes corresponding to the
      # mean pulse centroid (modulo 120 Hz)
      @model = [ [0,0] ]
      t = @results[:voltagePhase]
      while t < 50000 do
        @model << [t,0] << [t,1024] << [t,0]
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
