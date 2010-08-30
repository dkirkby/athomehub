class AthomeController < ApplicationController

  before_filter :valid_nid,:only=>[:detail,:replot]
  before_filter :valid_window,:only=>[:detail,:replot]

  def index
    @samples = [ ]
    # cutoff for supressing stale data
    stale_cutoff = @at - 1.minute
    # use profiles for the requested @at time
    DeviceProfile.latest(@at).each do |profile|
      # hide this profile's data if requested
      next if profile.display_order < 0
      # find the most recent sample for this profile at the requested time
      sample = Sample.for_networkID(profile.networkID,@at).last
      # find the most recent binned sample at the smallest zoom level
      bin = BinnedSample.for_networkID_and_zoom(profile.networkID,0,@at).last
      energyCost = bin ? bin.displayEnergyCost : nil
      # look up this network ID's configuration
      config = DeviceConfig.for_networkID(profile.networkID,@at).last
      # is this a recent enough sample to display?
      if (sample == nil) || (sample.created_at < stale_cutoff) then
        @samples << {
          :profile => profile,
          :serial => config ? config.serialNumber : nil,
          :temperature => nil,
          :lighting => nil,
          :power => nil,
          :cost => nil,
          :energy => energyCost
        }
      else
        @samples << {
          :profile => profile,
          :serial => config ? config.serialNumber : nil,
          :temperature => sample.displayTemperature,
          :lighting => sample.displayLighting,
          :power => sample.displayPower,
          :cost => sample.displayCost,
          :energy => energyCost
        }
      end
    end
    last_sample = Sample.last
    @max_id = last_sample ? last_sample.id : -1
    @note = new_note
  end
  
  @@max_samples_per_update = 10
  
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
    last_sample = Sample.last
    if last_sample and last_sample.id > last then
      # there is at least one new sample: make sure there are not too many
      last = last_sample.id - @@max_samples_per_update if
        last_sample.id > last + @@max_samples_per_update
      Sample.find(:all,:conditions=>['id > ?',last],:order=>'id ASC').each do |s|
        # Add this sample to our response, overwriting any previous update
        # for the same network ID.
        cells = [ ]
        cells << @template.colorize(s.displayTemperature) if
          ATHOME['display_temperature']
        cells << @template.lighting(s.displayLighting) if ATHOME['display_lighting']
        cells << @template.colorize(s.displayPower) <<
          @template.colorize(s.displayCost) if ATHOME['display_power']
        # lookup the latest energy usage for this networkID
        bin = BinnedSample.for_networkID_and_zoom(s.networkID,0).last
        cells << @template.colorize(bin.displayEnergyCost) if
          bin && ATHOME['display_power']
        tag = sprintf "nid%02x",s.networkID
        response[:updates][tag] = cells
      end
      last = last_sample.id
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
      :title => @window_title,
      :view_at => note.view_at.to_param,
      :data => @plotData, :labels => @dataLabels, :options => @plotOptions,
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
    tval,tval_e,temp,light,pwr,energy = [ ],[ ],[ ],[ ],[ ],[ ]
    temp_labels,light_labels,pwr_labels,energy_labels = [ ],[ ],[ ],[ ]
    temp_colors,light_colors,pwr_colors = [ ],[ ],[ ]
    @binned.each do |bin|
      # save the interval midpoint as this bin's timestamp
      ival = bin.interval
      midpt = ival.begin + midpt_offset
      # adjust for time zone bin by bin? (because of a DST boundary)
      midpt += midpt.utc_offset if tz_offset_varies
      # convert seconds since epoch to millisecs for javascript
      tval << 1e3*midpt.to_i
      temp << bin.theTemperature
      temp_labels << bin.displayTemperature[:content]
      color = @template.rgb_to_hex(bin.colorTemperature)
      temp_colors << color
      light << bin.lighting
      color = @template.rgb_to_hex(@template.hsb_to_rgb(bin.colorLighting))
      light_labels << bin.lighting.round
      light_colors << color
      pwr << bin.power
      pwr_labels << "#{bin.displayPower[:content]}, #{bin.displayCost[:content]}"
      color = @template.rgb_to_hex(@template.hsb_to_rgb(bin.colorPower))
      pwr_colors << color
      if bin.energyUsage then
        # display each energy usage update at the end of the corresponding bin
        # interval since it represents the running usage through the whole bin
        tval_e << 1e3*(midpt.to_i + @bin_size/2)
        energy << bin.theEnergyCost
        energy_labels << "#{bin.displayEnergyUsage}, #{bin.displayEnergyCost[:content]}"
      end
    end
    # prepare plot titles
    @plotTitles = {
      :temperature => "Temperature (&deg;#{ATHOME['temperature_units']})",
      :lighting => "Lighting",
      :power => "Power Consumption (Watts)",
      :energy => "Actual Energy Cost (&cent; for past 24 hours)"
    }
    # prepare datapoint labels
    @dataLabels = {
      :temperature => temp_labels,
      :lighting => light_labels,
      :power => pwr_labels,
      :energy => energy_labels
    }
    # prepare plotting options
    commonOptions = {
      :xaxis=>{
        :mode=>"time", :min=>leftEdge, :max=>rightEdge,
        :minTickSize=> @min_ticks, :timeformat=>@bin_format
      },
      :series=> {
        :lines=>{ :show=>true,:lineWidth=>3 },
        :points=>{ :show=>true,:radius=>5,:fill=>true,:lineWidth=>0 }
      },
      :grid => {
        :hoverable=> true
      }
    }
    label_width = 35
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
        :yaxis=>{ :labelWidth=>label_width, :min=>0 }
      }),
      :energy => commonOptions.merge({
        # energy axis always starts at zero
        :yaxis=>{ :labelWidth=>label_width, :min=>0 }
      })
    }
    # prepare the plots from the arrays built above
    plot_color = 'rgba(150,150,150,0.5)'
    @plotData = {
      :temperature => [{
        :data => tval.zip(temp), :color=>plot_color, :pointColors=>temp_colors
      }],
      :lighting => [{
        :data => tval.zip(light), :color=>plot_color, :pointColors=>light_colors
      }],
      :power => [{
        :data => tval.zip(pwr), :color=>plot_color, :pointColors=>pwr_colors,
        :lines=>{ :fill=>true, :fillColor=>'rgba(200,200,200,0.5)' }
      }],
      :energy => [{
        :data => tval_e.zip(energy), :color=>plot_color,
        :points => { :radius=>3, :fillColor=>plot_color }
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

end
