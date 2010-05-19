class Engineering::ApplicationController < ApplicationController

protected

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
  # and @begin_at and @end_at to DateTime objects that span the interval.
  def valid_ival
    @end_at = DateTime.now()
    if params.has_key? 'end' then
      begin
        @end_at = DateTime.parse(params['end'])
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

end
