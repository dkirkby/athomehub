# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  # all contoller actions will have a valid @at timestamp (see below for details)
  before_filter :valid_at

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

protected

  @@nonNegativeInteger = Regexp.compile("^(0|[1-9][0-9]*)$")

  # Validates input params['n'] and uses it to set @n
  def valid_n
    @n = 10 # this is the default
    if params.has_key? 'n' then
      value = params['n'].to_i
      if value < 1 or value > 1000 then
        flash.now[:notice] = "Invalid parameter n=#{params['n']}. Using #{@n} instead."
      else
        @n = value
      end
    end
  end
  
  @@ival_units = {
    'w'=>'weeks','d'=>'days','h'=>'hours','m'=>'minutes','s'=>'seconds'}
  
  # Validates inputs params['ival'] and optional params['end'] and uses
  # them to set @ival to the number of seconds in the requested interval,
  # and @begin_at and @end_at to Time objects that span the interval.
  def valid_ival
    @end_at = Time.now.utc
    if params.has_key? 'end' then
      begin
        @end_at = Time.parse(params['end']).utc
      rescue ArgumentError
        flash.now[:notice] = "Invalid parameter end=\'#{params['end']}\'. Using now (#{@end}) instead."
      end
    end
    @ival = 1.hour
    if params.has_key? 'ival' then
      # must be of the form <number><unit> where number can be decimal
      # and valid units are d(ays),h(ours),m(inutes) and s(seconds)
      parsed = /^([0-9]+(?:.[0-9]+)?)([wdhms])$/.match(params['ival'])
      if parsed then
        value = parsed[1].to_f
        unit = @@ival_units[parsed[2]]
        @ival = value.method(unit).call
        # check for an interval < 1 second, which is below our resolution
        if @ival < 1.second then
          flash.now[:notice] = "Requested interval is smaller than the timestamp resolution. Using 1s instead."
          @ival = 1.second
        end
      else
        # in case both 'end' and 'ival' are bad, this will overwrite the earlier flash
        flash.now[:notice] = "Invalid parameter ival=\'#{params['ival']}\'. Using 1h (#{@ival}) instead."
      end
    end
    # compute interval start
    @begin_at = @end_at - @ival
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
  
  # Validates input params['nid'] and sets @config and @profile. Value represents
  # the networkID of a configured device with a registered profile. The selected
  # @config and @profile depend on the value of @at and represent the settings that
  # were valid at the time. Sets @config = @profile = nil if no valid selection was
  # made. Sets a flash error message if an invalid selection was made but is silent
  # if no selection was made.
  def optional_nid
    @config = nil
    @profile = nil
    if params.has_key? 'nid' then
      # is it a decimal integer?
      if !!(params['nid'] =~ @@nonNegativeInteger) then
        nid = params['nid'].to_i
        # is it in range?
        if nid < 0 || nid > 255 then
          error_msg = "Parameter out of range (0-255): nid=#{nid}."
        else
          # is there a device registered with this network ID at the specified time?
          @config = DeviceConfig.for_networkID(nid,@at).last
          if not @config then
            error_msg = "No device registered with nid=#{nid} at #{@at}."
          elsif not @config.enabled then
            error_msg = "Device registered with nid=#{nid} is disabled at #{@at}."
          else
            @profile = DeviceProfile.for_networkID(nid,@at).last
          end
        end
      else
        error_msg = "Invalid parameter nid=\`#{params['nid']}\`."
      end
    end
    flash.now[:notice] = error_msg if error_msg
  end
  
  # Similar to optional_nid but sets a flash error if no selection was made
  # and attempts to pick a valid default network ID. Will still return
  # @config = nil if no default can be found.
  def valid_nid
    optional_nid
    # try to pick a default network ID if we don't have a valid selection
    if not @config then
      error_msg = "Missing required nid parameter."
      @config = DeviceConfig.latest(@at).first(:conditions=>'enabled=TRUE')
      if @config then
        @profile = DeviceProfile.for_networkID(@config.networkID,@at).last
        flash.now[:notice] = error_msg + " Using nid=#{@config.networkID} instead."
      else
        flash.now[:notice] = error_msg + " Aborting with no devices configured."
      end
    end
  end
  
  def valid_window
    # set the default zoom level
    @zoom = 2
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
    # lookup this window's timestamp range and zooming info
    @window_title,@bin_format,@min_ticks,@window_begin,@window_end,
      @zoom_in,@zoom_out = BinnedSample.window_info(@zoom,@index)
  end

end
