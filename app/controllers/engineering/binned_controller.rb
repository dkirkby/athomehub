class Engineering::BinnedController < Engineering::ApplicationController

  before_filter :valid_ival
  before_filter :valid_nid

  def bydate
    @binned = [ ]
  end

end
