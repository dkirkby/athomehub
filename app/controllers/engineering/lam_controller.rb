class Engineering::LamController < Engineering::ApplicationController
  
  before_filter :valid_n,:only=>:recent
  before_filter :valid_ival,:only=>:bydate
  before_filter :optional_nid, :only=>[:recent,:bydate]
  
  def recent
    @count = LookAtMe.count
    if @config then
      @lams = LookAtMe.for_serialNumber(@config.serialNumber).recent(@n)
    else
      @lams = LookAtMe.recent(@n)
    end
  end

  def bydate
    if @config then
      @lams = LookAtMe.for_serialNumber(@config.serialNumber).bydate(@begin_at,@end_at)
    else
      @lams = LookAtMe.bydate(@begin_at,@end_at)
    end
  end

  def index
    @lams = LookAtMe.find_latest(@at)
  end

protected

end
