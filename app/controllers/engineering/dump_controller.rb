class Engineering::DumpController < Engineering::ApplicationController

  before_filter :valid_n,:only=>:recent
  before_filter :valid_ival,:only=>:bydate
  before_filter :optional_nid,:only=>[:recent,:bydate]
  before_filter :optional_type,:only=>[:recent,:bydate]
  
  # Checks for an optional 'power' or 'light' keyword which signals that
  # only the specified type of dump source is requested.
  def optional_type
    @only_power = false
    @only_light = false
    if params.has_key? 'power' and not params.has_key? 'light' then
      @only_power = true
    elsif params.has_key? 'light' and not params.has_key? 'power' then
      @only_light = true
    end
  end
  
  def query
    if @config then
      if @only_power then
        BufferDump.for_networkID(@config.networkID).power
      elsif @only_light then
        BufferDump.for_networkID(@config.networkID).light
      else
        BufferDump.for_networkID(@config.networkID)
      end
    else
      if @only_power then
        BufferDump.power
      elsif @only_light then
        BufferDump.light
      else
        BufferDump.any
      end
    end
  end

  def recent
    @count = BufferDump.count
    @dumps = query.recent(@n)
  end

  def bydate
    @dumps = query.bydate(@begin_at,@end_at)
  end
  
  def samples
    @dump= BufferDump.find(params['id'])
    # fill a 2 x 250 table of (time,adc) values
    @data = Array.new 250
    @dump.samples.each_index do |k|
      @data[k] = [ 200*k, (@dump.samples[k] or -1) ]
    end
    # unpack the analysis header
    @results = @dump.unpack_header
    case @dump.source
    when 0,1
      # powerAnalysis: model is 60Hz function with the fitted RMS and phase, with
      # vertical voltage-fiducial marks superimposed.
      amplitude = Math.sqrt(2)*@results[:currentRMS]
      tzero = @results[:rawPhase]
      offset = tzero-@results[:relativePhase]
      begin
        mean = @dump.samples.sum*1.0/@dump.samples.length
      rescue
        mean = 511
      end
      fit = lambda {|t| mean + amplitude*Math.sin(@@omega60*(t-tzero)) }
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
    when 2,3
      # lightingAnalysis: model is 120Hz function with the fitted amplitude and
      # phase
      tzero = @results[:rawPhase]
      offset = tzero-@results[:relativePhase]
      mean = 0.1*@results[:mean]
      amplitude = 0.1*@results[:amplitude]
      fit = lambda {|t| mean + amplitude*Math.sin(@@omega120*(t-tzero)) }
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

  @@omega60 = 2*Math::PI*60/1e6
  @@omega120 = 2*Math::PI*120/1e6
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
