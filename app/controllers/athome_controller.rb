class AthomeController < ApplicationController

  before_filter :valid_nid,:only=>:detail
  before_filter :valid_window,:only=>:detail

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
    # look up the binned data for this device in the requested window
    @binned = BinnedSample.for_window(@zoom,@index).
      find_all_by_networkID(@config.networkID)
    return unless @binned
    midpt_offset = @bin_size/2
    # is the timezone offset constant over this window? (it might not be if
    # the window spans a DST adjustment and we are assuming that the largest
    # window cannot span two DST adjustments)
    tz_offset_varies = false
    tz_offset = @binned.first.interval.begin.utc_offset
    if @binned.last.interval.end.utc_offset == tz_offset then
      midpt_offset += tz_offset
    else
      tz_offset_varies = true
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
    # build plots to display
    @plotLabels = {
      :temperature => "Temperature (&deg;#{ATHOME['temperature_units']})",
      :lighting => "Lighting",
      :power => "Power Consumption (W)"
    }
    leftEdge = 1e3*(@window_interval.begin.to_i + @window_interval.begin.utc_offset)
    rightEdge = 1e3*(@window_interval.end.to_i + @window_interval.end.utc_offset)
    commonOptions = {
      :xaxis=>{ :mode=>"time", :min=>leftEdge, :max=>rightEdge },
      :series=> {
        :lines=> {:show=>true},
        :points=>{:show=>true,:radius=>4,:fill=>false}
      }
    }
    @plotOptions = {
      :temperature => commonOptions.merge({        
      }),
      :lighting => commonOptions.merge({
        :yaxis=>{:min=>0}
      }),
      :power => commonOptions.merge({
        :yaxis=>{:min=>0}
      })
    }
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
        # timestamp will be rendered by ActiveSupport::TimeWithZone.to_param
        :view_at=> @at,
        :user_id=>session[:user_id]
      })
    end
  end

  def valid_window
    # set the default zoom level
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
      if !!(params['zoom'] =~ @@nonNegativeInteger) then
        zoom = params['zoom'].to_i
        begin
          @bin_size = BinnedSample.size zoom
          @bin_size_as_words = BinnedSample.size_as_words zoom
          @zoom = zoom
        rescue
          flash.now[:notice] = "Out of range zoom=#{zoom}. Using zoom=#{@zoom}."
        end
      else
        flash.now[:notice] = "Invalid zoom=\'#{params['zoom']}\'. Using zoom=#{@zoom}."
      end
    end
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
    # lookup the timestamps corresponding to this window
    @window_interval = BinnedSample.window_interval(@zoom,@index)
  end

end
