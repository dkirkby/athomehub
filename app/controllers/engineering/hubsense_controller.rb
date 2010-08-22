class Engineering::HubsenseController < Engineering::ApplicationController

  before_filter :valid_n,:only=>:recent
  before_filter :valid_ival,:only=>:bydate

  def recent
    @count = HubSample.count
    @readings = HubSample.recent(@n)
  end

  def bydate
    @readings = HubSample.bydate(@begin_at,@end_at)
  end
  
end
