class Engineering::SamplesController < ApplicationController

  def recent
    @nrecent = params['n']
    @count = Sample.count
    @samples = Sample.find(:all,:limit=>@nrecent,:order=>'created_at DESC',:readonly=>true)
  end

  def bydate
  end

end
