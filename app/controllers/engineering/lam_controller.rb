class Engineering::LamController < ApplicationController
  
  def recent
    @count = LookAtMe.count
    @lams = LookAtMe.find(:all,:limit=>@nrecent,:order=>'created_at DESC',:readonly=>true)
  end

  def bydate
  end

  def active
  end

end
