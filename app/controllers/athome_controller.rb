class AthomeController < ApplicationController

  before_filter :valid_nid,:only=>:detail
  before_filter :valid_window,:only=>:detail

  def index
    @samples = [ ]
    # cutoff for supressing stale data
    stale_cutoff = @at - 1.minute
    # use profiles for the requested @at time
    DeviceProfile.latest(@at).each do |profile|
      # hide this profile's data if requested
      next if profile.display_order < 0
      # find most recent sample for this profile at the requested time
      sample = Sample.for_networkID(profile.networkID,@at).last
      # is this a recent enough sample to display?
      if sample.created_at < stale_cutoff then
        no_data = "<span class='nodata'>no data</span>"
        @samples << {
          :profile => profile,
          :temperature => no_data,
          :lighting => [no_data],
          :power => no_data
        }
      else
        @samples << {
          :profile => profile,
          :temperature => sample.displayTemperature,
          :lighting => [sample.lighting,sample.artificial,sample.lightFactor],
          :power => sample.displayPower
        }
      end
    end
    @note = new_note
  end
  
  def detail
    # retrieve all samples for the requested device within the requested window
    @samples = Sample.find(:all,
      :conditions=>['networkID = ? and created_at > ? and created_at <= ?',
      @config.networkID,@begin_at,@end_at],:readonly=>true)
    # downsample
    @binned = [ ]
    nbins = 12
    binsize = (@end_at.to_f - @begin_at.to_f)/nbins
    offset_origin = @begin_at.to_f
    nbins.times do |k|
      midpt = @begin_at.to_f + (k+0.5)*binsize
      nsamples,temperature,lighting,power = 0,0.0,0.0,0.0
      @samples.each do |s|
        next unless (s.created_at.to_f - midpt).abs < binsize/2
        nsamples += 1
        temperature += (s.temperature or 0)
        lighting += (s.lighting2 or 0)
        power += (s.power or 0)
      end
      @binned << {
        :when=> Time.at(midpt).localtime,
        :offset=> midpt - offset_origin,
        :lighting=> lighting/nsamples,
        :temperature=> temperature/(100*nsamples),
        :power=> power/(10*nsamples)
      } if nsamples > 0
    end
    @note = new_note
  end
  
  def create_note
    @note = Note.new(params[:note])
    # remember this note taker as the current user
    session[:user_id] = @note.user_id
    if @note.save
      flash[:notice] = 'Note saved'
    else
      flash[:notice] = 'Unable to save note!'
    end
    respond_to do |format|
      format.html { redirect_to :back }
      format.text do
        render :text=>flash[:notice]
        flash.discard
      end
    end
  end
  
  # Defines a replacement Sample class for demonstrating and testing
  class DemoSample
    def initialize(fields)
      @fields = fields
    end
    def temperature
      return @fields[:temperature]
    end
    def lighting
      return @fields[:lighting]
    end
    def artificial
      return @fields[:artificial]
    end
    def power
      return @fields[:power]
    end
    def cost
      return @fields[:cost]
    end
    def location
      return @fields[:location]
    end
  end

  # Returns fake data for demonstration and UI prototyping
  def demo
    # Declare some sample data
    @samples = [
      DemoSample.new({:location=>"Kitchen",
        :temperature=>7441,:lighting=>74,:artificial=>43,:power=>  52,:cost=>1.731}),
      DemoSample.new({:location=>"Family Room",
        :temperature=>7361,:lighting=>74,:artificial=>43,:power=>1856,:cost=>4.121}),
      DemoSample.new({:location=>"Dylan's Room",
        :temperature=>7811,:lighting=>74,:artificial=>43,:power=> 642,:cost=>0.171}),
      DemoSample.new({:location=>"Downstairs Bathroom",
        :temperature=>7291,:lighting=>74,:artificial=>43,:power=>  13,:cost=>0.060}),
      DemoSample.new({:location=>"Kids Bathroom",
        :temperature=>7751,:lighting=>74,:artificial=>43,:power=>   0,:cost=>1.840}),
      DemoSample.new({:location=>"Helen's Room",
        :temperature=>8141,:lighting=>74,:artificial=>43,:power=> 874,:cost=>0.693}),
      DemoSample.new({:location=>"Master Bedroom",
        :temperature=>8021,:lighting=>74,:artificial=>43,:power=>  38,:cost=>1.875}),
      DemoSample.new({:location=>"Master Bathroom",
        :temperature=>7871,:lighting=>74,:artificial=>43,:power=>   0,:cost=>0.876})
    ]
    @note = new_note
    render :action=>"index"
  end
  
protected

  # Prepares an empty new note or retrieves note-id if specified
  def new_note
    if params.has_key? 'note_id' then
      @replay = true
      Note.find(params['note_id'])
    else
      Note.new({
        :body=>"Click to enter a new note...",
        :view=>action_name,
        :view_at=>@at.localtime,
        :user_id=>session[:user_id]
      })
    end
  end

  def valid_window
    # set window parameter defaults
    @index = 0
    @zoom = 3
    # define the zoom levels: (formats are for DateTime.strftime)
    # label, seconds, label format, tick format, # ticks, index
    @zoomLevels = [
      ['2 minutes',      120, "%l:%M%P %a %e %B", ":%M:%S", 5, 0],
      ['10 minutes',     600, "%l:%M%P %a %e %B", "%l:%M", 11, 1],
      ['1 hour',        3600, "%l:%M%P %a %e %B", "%l:%M", 7, 2],
      ['6 hours',      21600, "%l%P %a %e %B", "%l%P", 7, 3],
      ['1 day',        86400, "%l%P %a %e %B", "%l%P", 5, 4],
      ['1 week',      604800, "%a %e %B %Y", "%l%P-%a", 15, 5],
      ['4 weeks',    2419200, "%e %B %Y", "%d-%b", 5, 6],
      ['16 weeks',   9676800, "%e %B %Y", "%d-%b", 5, 7]
    ]
    # do we have a zoom value to use?
    if params.has_key? 'zoom' then
      # is it a decimal integer?
      if !!(params['zoom'] =~ @@decimalInteger) then 
        @zoom = params['zoom'].to_i
        # clip an out of range zoom that is otherwise a valid integer
        if @zoom < 0 then
          @zoom = 0
          flash.now[:notice] = "Using minimum allowed zoom=#{@zoom}."
        elsif @zoom >= @zoomLevels.length then
          @zoom = @zoomLevels.length-1
          flash.now[:notice] = "Using maximum allowed zoom=#{@zoom}."
        end
      else
        flash.now[:notice] = "Invalid parameter zoom=\'#{params['zoom']}\'. Using zoom=\'#{@zoom}\' instead."
      end
    end
    # do we have an index value to use?
    if params.has_key? 'index' then
      # is it a decimal integer?
      if !!(params['index'] =~ @@decimalInteger) then
        @index = params['index'].to_i
      else
        flash.now[:notice] = "Invalid parameter index=\'#{params['index']}\'. Using index=\'#{@index}\' instead."
      end
    end
    # check for a commit parameter that requests a newer/older index
    case params['commit']
    when 'Newer' then
      if @index == 0 then
        flash.now[:notice] = "Already displaying newest data. Request ignored."
      else
        @index -= 1
      end
    when 'Older'
      if @index == -1 then
        flash.now[:notice] = "Already displaying oldest data. Request ignored."
      else
        @index += 1
      end
    when 'Newest'
      @index = 0
    when 'Oldest'
      @index = -1
    when nil,'Update'
      # no adjustment to index requested
    else
      flash.now[:notice] = "Ignoring invalid parameter commit=\`#{params['commit']}\`."
    end
    # calculate the half-window size in seconds
    interval = 0.5*@zoomLevels[@zoom][1]
    # calculate the local timezone offset in seconds
    @tz_offset = @at.localtime.utc_offset
    # calculate the timestamp (secs since epoch) corresponding to the window
    # midpoint with index=0
    midpoint_now = interval*((@at.to_i + @tz_offset)/interval).floor - @tz_offset
    # determine the valid index range
    oldest_sample = Sample.find(:first,:order=>'id ASC',
      :conditions=>['networkID = ?',@config.networkID],:readonly=>true)
    if oldest_sample then
      @max_index = ((midpoint_now - oldest_sample.created_at.to_i)/interval).ceil
      # check for an out of range index
      if @index > @max_index then
        flash.now[:notice] = "Requested index=#{@index} is out of range. Using index=#{@max_index}."
        @index = @max_index
      elsif @index < -@max_index-1 then
        flash.now[:notice] = "Requested index=#{@index} is out of range. Using index=#{-@max_index-1}."
        @index = -@max_index-1
      end
      # calculate midpoint of the indexed window
      if @index >= 0 then
        midpoint = midpoint_now - @index*interval
      else
        midpoint = midpoint_now - (@max_index+@index+1)*interval
      end
      # flag if the requested index is the oldest/newest allowed
      @newest = true if @index == 0 || @index == -@max_index-1
      @oldest = true if @index == -1 || @index == @max_index
    else
      @index = 0
      flash.now[:notice] = 'No samples have been recorded for this device.'
    end
    # calculate the UTC timestamp range corresponding to the selected window
    @mid_at = Time.at(midpoint).utc
    @end_at = Time.at(midpoint+interval).utc
    @begin_at = Time.at(midpoint-interval).utc
    # calculate display labels for this window
    label_format,tick_format,num_ticks = @zoomLevels[@zoom][2..4]
    @label = @mid_at.localtime.to_datetime.strftime label_format
    @tick_labels = [ ]
    delta = 2*interval/(num_ticks-1)
    num_ticks.times do |tick|
      tick_at = @begin_at + tick*delta
      @tick_labels << tick_at.localtime.to_datetime.strftime(tick_format)
    end
  end

end
