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

  def index
    @lams = LookAtMe.latest.find(:all,:order=>'id DESC')
  end

protected

end
