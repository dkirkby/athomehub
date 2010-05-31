class AthomeController < ApplicationController

  before_filter :valid_at
  before_filter :valid_id,:only=>:detail
  before_filter :valid_window,:only=>:detail

  def index
    @samples = Sample.find(:all,:group=>'networkID',
      :conditions=>['networkID IS NOT NULL and created_at < ?',@at],
      :readonly=>true)
    @note = new_note
  end
  
  def detail
    @samples = Sample.find(:all,:limit=>10,:readonly=>true)
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
        :temperature=>7241,:lighting=>74,:artificial=>43,:power=>1328,:cost=>0.731}),
      DemoSample.new({:location=>"Family Room",
        :temperature=>7241,:lighting=>74,:artificial=>43,:power=>1328,:cost=>0.731}),
      DemoSample.new({:location=>"Dylan's Room",
        :temperature=>7241,:lighting=>74,:artificial=>43,:power=>1328,:cost=>0.731}),
      DemoSample.new({:location=>"Downstairs Bathroom",
        :temperature=>7241,:lighting=>74,:artificial=>43,:power=>1328,:cost=>0.731}),
      DemoSample.new({:location=>"Kids Bathroom",
        :temperature=>7241,:lighting=>74,:artificial=>43,:power=>1328,:cost=>0.731}),
      DemoSample.new({:location=>"Helen's Room",
        :temperature=>7241,:lighting=>74,:artificial=>43,:power=>1328,:cost=>0.731}),
      DemoSample.new({:location=>"Master Bedroom",
        :temperature=>7241,:lighting=>74,:artificial=>43,:power=>1328,:cost=>0.731}),
      DemoSample.new({:location=>"Master Bathroom",
        :temperature=>7241,:lighting=>74,:artificial=>43,:power=>1328,:cost=>0.731})
    ]
    @note = new_note
    render :action=>"index"
  end
  
protected

  @@decimalInteger = Regexp.compile("^(0|-?[1-9][0-9]*)$")

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

  # Validates input params['at'] and sets @at. Value represents timestamp
  # of when an action is run. If provided on input, the action will replay
  # a historical view. Otherwise @at is set to a value that can be used
  # for later replay of a current view.
  def valid_at
    # defaults to now
    @at = Time.now.utc
    # has a value been provided?
    if params.has_key? 'at' then
      begin
        @at = Time.parse(params['at']).utc
      rescue ArgumentError
        flash.now[:notice] = "Invalid parameter at=\'#{params['end']}\'. Using now (#{@at}) instead."
      end
    end
  end
  
  # Validates input params['id'] and sets @config. Value represents the
  # networkID of a configured device.
  def valid_id
    @config = nil
    if params.has_key? 'id' then
      # is it a decimal integer?
      if !!(params['id'] =~ @@decimalInteger) then
        id = params['id'].to_i
        # is it in range?
        if id < 0 || id > 255 then
          error_msg = "Parameter out of range (0-255): id=#{id}."
        else
          # is there a device registered with this ID?
          @config = DeviceConfig.find_by_networkID(id)
          if not @config then
            error_msg = "No such device with id=#{id}."
          end
        end
      else
        error_msg = "Invalid parameter id=\`#{params['id']}\`."
      end
    else
      error_msg = "Missing required id parameter."
    end
    # try to pick a default ID if we don't have a valid selection
    if not @config then
      @config = DeviceConfig.find(:first)
      if @config then
        flash.now[:notice] = error_msg + " Using id=#{@config.networkID} instead."
      else
        flash.now[:notice] = error_msg + " Aborting with no devices configured."
      end
    end
  end
  
  
  
  def valid_window
    # set window parameter defaults
    @index = 0
    @zoom = 3
    @zoomLevels = [
      ['2 minutes',      120, 0],
      ['10 minutes',     600, 1],
      ['1 hour',        3600, 2],
      ['6 hours',      21600, 3],
      ['1 day',        86400, 4],
      ['1 week',      604800, 5],
      ['4 weeks',    2419200, 6],
      ['16 weeks',   9676800, 7]
    ]
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
    when 'Update'
      # no adjustment to index requested
    else
      flash.now[:notice] = "Ignoring invalid parameter commit=\`#{params['commit']}\`."
    end
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
    @end_at = @at
  end

end
