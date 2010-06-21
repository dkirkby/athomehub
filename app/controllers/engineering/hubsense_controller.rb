class Engineering::HubsenseController < Engineering::ApplicationController

  before_filter :valid_n,:only=>:recent
  before_filter :valid_ival,:only=>:bydate

  def recent
    @count = HubSample.count
    @readings = HubSample.find(:all,:limit=>@n,:order=>'id DESC',:readonly=>true)
  end

  def bydate
  end
  
end
