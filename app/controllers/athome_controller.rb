class AthomeController < ApplicationController

  before_filter :valid_nid,:only=>[:detail,:replot]
  before_filter :valid_window,:only=>[:detail,:replot]

  def index
    @samples = [ ]
    # cutoff for supressing stale data
    stale_cutoff = @at - 1.minute
    # keep track of the maximum sample record ID seen
    @max_id = -1
    # use profiles for the requested @at time
    DeviceProfile.latest(@at).each do |profile|
      # hide this profile's data if requested
      next if profile.display_order < 0
      # find most recent sample for this profile at the requested time
      sample = Sample.for_networkID(profile.networkID,@at).last
      # update the maximum sample record ID seen
      @max_id = sample.id if sample.id > @max_id
      # is this a recent enough sample to display?
      if sample.created_at < stale_cutoff then
        no_data = "<span class='nodata'>no data</span>"
        @samples << {
          :profile => profile,
          :temperature => no_data,
          :lighting => [no_data],
          :power => no_data,
          :cost => no_data
        }
      else
        @samples << {
          :profile => profile,
          :temperature => sample.displayTemperature,
          :lighting => [sample.lighting,sample.artificial,sample.lightFactor],
          :power => sample.displayPower,
          :cost => sample.displayCost
        }
      end
    end
    @note = new_note
  end
  
  def update
    # initialize our response
    # (we create a temporary note to ensure that the view_at timestamp is
    # compatible with ActiveSupport::TimeWithZone... this is probably unecessary)
    note = Note.new(:view_at=>@at)
    response = {
      :view_at => note.view_at.to_param,
      :date => @template.format_date(@at),
      :time => @template.format_time(@at),
      :updates => { }
    }
    # loop over new samples with record IDs newer than the caller's
    # high watermark
    last = params['last'].to_i or -1
    Sample.find(:all,:conditions=>['id > ?',last],:order=>'id ASC').each do |s|
      last = s.id if (s.id > last)
      # Add this sample to our response, overwriting any previous update
      # for the same network ID.
      cells = [ ]
      cells << s[:temperature] if ATHOME['display_temperature']
      cells << s[:lighting][0] if ATHOME['display_lighting']
      cells << @template.colorize(s.displayPower) <<
        @template.colorize(s.displayCost) if ATHOME['display_power']
      tag = sprintf "nid%02x",s.networkID
      response[:updates][tag] = cells
    end
    # include the new high water mark in our response
    response[:last] = last
    # return our response via json
    render :json => response
  end
  
  def detail
    # describe this device
    if @profile then
      @description = @profile.description
    elsif @config then
      @description = @template.format_serialNumber @config.serialNumber
    else
      @description = 'Unknown Device'
    end
    # prepare a new note
    @note = new_note
    # prepare the plots
    make_plots
  end

  def replot
    make_plots
    note = Note.new(:view_at=>@at)
    response = {
      :view_at => note.view_at.to_param,
      :date => @template.format_date(@at),
      :time => @template.format_time(@at),
      :data => @plotData, :titles => @plotTitles, :options => @plotOptions,
      :zoom => @zoom, :index => @index,
      :zoom_in => @zoom_in, :zoom_out => @zoom_out
    }
    render :json => response
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

def make_plots
  # look up the binned data for this device in the requested window
  @binned = BinnedSample.for_window(@zoom,@index).
    find_all_by_networkID(@config.networkID)
  # is the timezone offset constant over this window? (it might not be if
  # the window spans a DST adjustment and we are assuming that the largest
  # window cannot span two DST adjustments)
  midpt_offset = @bin_size/2
  tz_offset_varies = false
  tz_offset = @window_begin.utc_offset
  leftEdge = 1e3*(@window_begin.to_i + tz_offset)
  if @window_end.utc_offset == tz_offset then
    midpt_offset += tz_offset
    rightEdge = 1e3*(@window_end.to_i + tz_offset)
  else
    tz_offset_varies = true
    rightEdge = 1e3*(@window_end.to_i + @window_end.utc_offset)
  end
  # build arrays of t,y values to plot
  tval,temp,light,pwr = [ ],[ ],[ ],[ ]
  @binned.each do |bin|
    # save the interval midpoint as this bin's timestamp
    ival = bin.interval
    midpt = ival.begin + midpt_offset
    # adjust for time zone bin by bin? (because of a DST boundary)
    midpt += midpt.utc_offset if tz_offset_varies
    # convert seconds since epoch to millisecs for javascript
    tval << 1e3*midpt.to_i
    temp << bin.theTemperature
    light << bin.lighting
    pwr << bin.power
  end
  # prepare plot titles
  window_title = BinnedSample.window_as_words @zoom,@index
  @plotTitles = {
    :temperature => "Temperature (&deg;#{ATHOME['temperature_units']}) for #{window_title}",
    :lighting => "Lighting for #{window_title}",
    :power => "Power Consumption (Watts) for #{window_title}"
  }
  # prepare plotting options
  commonOptions = {
    :xaxis=>{
      :mode=>"time", :min=>leftEdge, :max=>rightEdge,
      :minTickSize=> [30,"second"]
    },
    :series=> {
      :lines=>{ :show=>true },
      :points=>{ :show=>true,:radius=>4,:fill=>false }
    }
  }
  label_width = 45
  @plotOptions = {
    :temperature => commonOptions.merge({
      # round temperature limits to whole degrees and ensure that at 1deg is shown
      :yaxis=>{
        :labelWidth=>label_width,
        :min=> (temp.min.floor if temp.min),
        :max=> (temp.max.ceil if temp.max)
      }
    }),
    :lighting => commonOptions.merge({
      # lighting axis always starts at zero
      :yaxis=>{ :labelWidth=>label_width, :min=>0 }
    }),
    :power => commonOptions.merge({
      # power axis always starts at zero
      :yaxis=>{ :labelWidth=>label_width, :min=>0 },
      :lines=>{ :fill=>true, :fillColor=>'rgba(200,200,200,0.5)' }
    })
  }
  # prepare the plots from the arrays built above
  @plotData = {
    :temperature => [{
      :data => tval.zip(temp)
    }],
    :lighting => [{
      :data => tval.zip(light)
    }],
    :power => [{
      :data => tval.zip(pwr)
    }]
  }
end


  # Prepares an empty new note or retrieves note-id if specified
  def new_note
    if params.has_key? 'note_id' then
      @replay = true
      Note.find(params['note_id'])
    else
      Note.new({
        :body=>"Click to enter a new note...",
        :view=>action_name,
        # timestamp will be rendered by ActiveSupport::TimeWithZone.to_param
        :view_at=> @at,
        :user_id=>session[:user_id]
      })
    end
  end

  def valid_window
    # set the default zoom level
    @zoom = 3
    # do we have a zoom value to use?
    if params.has_key? 'zoom' then
      # is it a decimal integer?
      if !!(params['zoom'] =~ @@nonNegativeInteger) then
        zoom = params['zoom'].to_i
        begin
          BinnedSample.size zoom # will fail unless zoom is in range
          @zoom = zoom
        rescue
          flash.now[:notice] = "Out of range zoom=#{zoom}. Using zoom=#{@zoom}."
        end
      else
        flash.now[:notice] = "Invalid zoom=\'#{params['zoom']}\'. Using zoom=#{@zoom}."
      end
    end
    @bin_size = BinnedSample.size @zoom
    @bin_size_as_words = BinnedSample.size_as_words @zoom
    # do we have an index value to use?
    if params.has_key? 'index' then
      case params['index']
      when @@nonNegativeInteger then
        @index = params['index'].to_i
      when 'last' then
        @index = BinnedSample.window(@at,@zoom)
      when 'first' then
        @index = defined?(@config) ? BinnedSample.first(@config.networkID,@zoom) : 0
      else
        @index = BinnedSample.window(@at,@zoom)
        flash.now[:notice] = "Invalid index=\'#{params['index']}\'. Using index=\'#{@index}\'."
      end
    else
      # default to showing the most recent window at this zoom level
      @index = BinnedSample.window(@at,@zoom)
    end
    # lookup this window's timestamp and zooming info
    @window_begin,@window_end,@zoom_in,@zoom_out =
      BinnedSample.window_info(@zoom,@index)
  end

end
