class Engineering::AnalysisController < Engineering::ApplicationController

  before_filter :valid_ival,:valid_nid
  
  def power
    # find power buffer dumps for the specified interval and network ID
    @dumps = BufferDump.find(:all,
      :conditions=>['created_at > ? and created_at <= ? and networkID = ? and source in (0,1,4)',
        @begin_at,@end_at,@config.networkID],
      :order=>'id ASC',:readonly=>true)
    # fill arrays of analysis results
    tPh,tLo,tHi = [ ],[ ],[ ]
    fidArea = [ ]
    nClippedHi,currentComplexityHi,currentRMSHi,relativePhaseHi = [ ],[ ],[ ],[ ]
    nClippedLo,currentComplexityLo,currentRMSLo,relativePhaseLo = [ ],[ ],[ ],[ ]
    calRMSLo,calRMSHi,calPhaseLo,calPhaseHi = [ ],[ ],[ ],[ ]
    tz_offset = @begin_at.localtime.utc_offset
    @dumps.each do |dump|
      # calculate a unix timestamp in the server timezone, suitable for plotting.
      # convert to milliseconds for javascript.
      t = 1e3*(dump.created_at.to_i + tz_offset)
      # unpack this buffer analysis header
      params = dump.unpack_header
      case dump.source
      when 0
        tLo << t
        nClippedLo << params[:nClipped]
        currentComplexityLo << params[:currentComplexity]
        currentRMSLo << params[:currentRMS]
        # apply the device gain calibration
        calRMSLo << 1e-3*params[:currentRMS]*@config.powerGainLo
        # undo the device phase calibration
        relativePhaseLo << (params[:relativePhase] + @config.fiducialShiftHi -
          @config.fiducialHiLoDelta).modulo(@@micros_per_120Hz)
        # shift the unsigned phase to be centered at zero
        if params[:relativePhase] < 0.5*@@micros_per_120Hz then
          calPhaseLo << params[:relativePhase]
        else
          calPhaseLo << params[:relativePhase] - @@micros_per_120Hz
        end
      when 1
        tHi << t
        nClippedHi << params[:nClipped]
        currentComplexityHi << params[:currentComplexity]
        currentRMSHi << params[:currentRMS]
        # apply the device gain calibration
        calRMSHi << 1e-3*params[:currentRMS]*@config.powerGainHi
        # undo the device phase calibration
        relativePhaseHi << (params[:relativePhase] +
          @config.fiducialShiftHi).modulo(@@micros_per_120Hz)
        # shift the unsigned phase to be centered at zero
        if params[:relativePhase] < 0.5*@@micros_per_120Hz then
          calPhaseHi << params[:relativePhase]
        else
          calPhaseHi << params[:relativePhase] - @@micros_per_120Hz
        end
      when 4
        tPh << t
        fidArea << params[:moment0]
      end
    end
    # zip up (t,y) arrays for plotting and save them in a dictionary
    # that we will pass to javascript via json
    @analysisPlots = {
      :fidArea => [
        { :data => tPh.zip(fidArea), :label=> stats(fidArea) }
      ],
      :relPhase => [
        { :data => tHi.zip(relativePhaseHi), :label=> "HI "+stats(relativePhaseHi) },
        { :data => tLo.zip(relativePhaseLo), :label=> "LO "+stats(relativePhaseLo) }
      ],
      :calPhase => [
        { :data => tHi.zip(calPhaseHi), :label=> "HI "+stats(calPhaseHi) },
        { :data => tLo.zip(calPhaseLo), :label=> "LO "+stats(calPhaseLo) },
      ],
      :rmsHi => [
        { :data => tHi.zip(currentRMSHi), :label => "HI "+stats(currentRMSHi,"%.3f") }
      ],
      :rmsLo => [
        { :data => tLo.zip(currentRMSLo), :label => "LO "+stats(currentRMSLo,"%.3f") }
      ],
      :rmsCal => [
        { :data => tHi.zip(calRMSHi), :label => "HI "+stats(calRMSHi,"%.3f") },
        { :data => tLo.zip(calRMSLo), :label => "LO "+stats(calRMSLo,"%.3f") }
      ],
      :complexity => [
        { :data => tHi.zip(currentComplexityHi), :label => "HI "+stats(currentComplexityHi) },
        { :data => tLo.zip(currentComplexityLo), :label => "LO "+stats(currentComplexityLo) }
      ],
      :nClipped => [
        { :data => tHi.zip(nClippedHi), :label => "HI "+stats(nClippedHi) },
        { :data => tLo.zip(nClippedLo), :label => "LO "+stats(nClippedLo) }
      ]
    }
  end
  
  def stats(values,floatFormat=nil)
    # Calculates statistics of the input values and returns a formatted label
    floatFormat = "%.1f" unless floatFormat
    labelFormat = floatFormat + " [" + floatFormat + "] &plusmn; " + floatFormat
    # calculate the mean and RMS using all values
    n = 1.0*values.length
    sum1 = values.sum
    sum2 = values.collect{ |x| x*x }.sum
    mean = sum1/n
    rms = Math.sqrt(sum2/n - sum1*sum1/(n*n))
    # calculated a truncated mean using the central 80% of values
    ndrop = values.length/10
    nkeep = values.length - 2*ndrop
    trunc_mean = values.sort[ndrop,nkeep].sum/(1.0*nkeep)
    # return a formattted string
    sprintf labelFormat,mean,trunc_mean,rms
  end
  
protected

  @@micros_per_120Hz = 1e6/120

end
