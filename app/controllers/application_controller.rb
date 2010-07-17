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

  @@decimalInteger = Regexp.compile("^(0|-?[1-9][0-9]*)$")

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
      parsed = /^([0-9]+(?:.[0-9]+)?)([dhms])$/.match(params['ival'])
      if parsed then
        value = parsed[1].to_f
        unit = {'d'=>'days','h'=>'hours','m'=>'minutes','s'=>'seconds'}[parsed[2]]
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
  
  # Validates input params['nid'] and sets @config. Value represents the
  # networkID of a configured device. The selected @config depends on the
  # value of @at and represents the configuration that was valid at the time.
  # Sets @config = nil if no valid selection was made. Sets a flash error
  # message if an invalid selection was made but is silent if no selection
  # was made.
  def optional_nid
    @config = nil
    if params.has_key? 'nid' then
      # is it a decimal integer?
      if !!(params['nid'] =~ @@decimalInteger) then
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
        flash.now[:notice] = error_msg + " Using nid=#{@config.networkID} instead."
      else
        flash.now[:notice] = error_msg + " Aborting with no devices configured."
      end
    end
  end

end
