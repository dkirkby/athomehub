class Engineering::LamController < Engineering::ApplicationController
  
  before_filter :valid_n,:only=>:recent
  
  def recent
    @count = LookAtMe.count
    @lams = LookAtMe.find(:all,:limit=>@n,:order=>'created_at DESC',:readonly=>true)
  end

  def bydate
  end

  def active
  end

protected

end
