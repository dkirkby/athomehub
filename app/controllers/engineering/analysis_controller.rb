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
        relativePhaseLo << params[:relativePhase]
      when 1
        tHi << t
        nClippedHi << params[:nClipped]
        currentComplexityHi << params[:currentComplexity]
        currentRMSHi << params[:currentRMS]
        relativePhaseHi << params[:relativePhase]
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
      ]
    }
  end
  
  def stats(values,format=nil)
    format = "%.1f &plusmn; %.1f" unless format
    n = 1.0*values.length
    sum1 = values.sum
    sum2 = values.collect{ |x| x*x }.sum
    mean = sum1/n
    rms = Math.sqrt(sum2/n - sum1*sum1/(n*n))
    sprintf format,mean,rms
  end

end
