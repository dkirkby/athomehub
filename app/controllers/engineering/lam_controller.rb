class Engineering::LamController < Engineering::ApplicationController
  
  before_filter :valid_n,:only=>:recent
  before_filter :valid_ival,:only=>:bydate
  
  def recent
    @count = LookAtMe.count
    @lams = LookAtMe.recent(@n)
  end

  def bydate
    @lams = LookAtMe.bydate(@begin_at,@end_at)
  end

  def active
    @lams = LookAtMe.find(:all,:group=>'serialNumber',:readonly=>true)
  end

protected

end
