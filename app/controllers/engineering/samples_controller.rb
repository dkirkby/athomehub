class Engineering::SamplesController < ApplicationController

  before_filter :valid_n,:only=>:recent

  def recent
    @count = Sample.count
    @samples = Sample.find(:all,:limit=>@nrecent,:order=>'created_at DESC',:readonly=>true)
  end

  def bydate
  end
  
protected
  
end
