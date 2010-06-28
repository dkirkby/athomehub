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
    tz_offset = @begin_at.localtime.utc_offset
    @dumps.each do |dump|
      # calculate a unix timestamp in the server timezone, suitable for plotting
      t = dump.created_at.to_i + tz_offset
      # unpack this buffer analysis header
      params = dump.unpack_header
      case dump.source
      when 0
        tLo << t
      when 1
        tHi << t
      when 4
        tPh << t
        fidArea << params[:moment0]
      end
    end
    # zip up (t,y) arrays for plotting and save them in a dictionary
    # that we will pass to javascript via json
    @analysisPlots = {
      :fidArea => [ { :data => tPh.zip(fidArea) } ]
    }
  end

end
