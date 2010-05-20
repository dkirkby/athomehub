class Engineering::LamController < Engineering::ApplicationController
  
  before_filter :valid_n,:only=>:recent
  before_filter :valid_ival,:only=>:bydate
  
  def recent
    @count = LookAtMe.count
    @lams = LookAtMe.find(:all,:limit=>@n,:order=>'id DESC',:readonly=>true)
  end

  def bydate
    @lams = LookAtMe.find(:all,
      :conditions=>['created_at > ? and created_at <= ?',@begin_at,@end_at],
      :order=>'created_at DESC',:readonly=>true)
  end

  def active
    @lams = LookAtMe.find(:all,:group=>'serialNumber',:readonly=>true)
  end

protected

end
