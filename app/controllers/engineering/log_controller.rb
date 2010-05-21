class Engineering::LogController < Engineering::ApplicationController

  before_filter :valid_n,:only=>:recent
  before_filter :valid_ival,:only=>:bydate
  before_filter :valid_level

  def recent
    @count = DeviceLog.count
    @logs = DeviceLog.find(:all,:limit=>@n,:order=>'id DESC',
      :conditions=>['severity >= ?',@level],:readonly=>true)
  end

  def bydate
    @logs = DeviceLog.find(:all,
      :conditions=>[
        'created_at > ? and created_at <= ? and severity >= ?',
        @begin_at,@end_at,@level
      ],:order=>'created_at DESC',:readonly=>true)
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
