class Engineering::LogController < Engineering::ApplicationController

  before_filter :valid_n,:only=>:recent
  before_filter :valid_ival,:only=>:bydate
  before_filter :valid_level

  def recent
    @count = DeviceLog.count
    @logs = DeviceLog.recent(@n).min_severity(@level)
  end

  def bydate
    @logs = DeviceLog.bydate(@begin_at,@end_at).min_severity(@level)
  end

protected

  # checks for a valid 'level' parameter and sets @level accordingly
  def valid_level
    @level = DeviceLog.severity_level('info')
    if params.has_key? 'level' then
      level = DeviceLog.severity_level(params['level'])
      if level then
        @level = level
      else
        flash.now[:notice] = "Ignoring bad severity level parameter \'#{params['level']}\'"
      end
    end
  end

end
