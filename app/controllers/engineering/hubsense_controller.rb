class Engineering::HubsenseController < Engineering::ApplicationController

  before_filter :valid_n,:only=>:recent
  before_filter :valid_ival,:only=>:bydate

  def recent
    @count = HubSample.count
    @readings = HubSample.find(:all,:limit=>@n,:order=>'id DESC',:readonly=>true)
  end

  def bydate
    @readings = HubSample.find(:all,
      :conditions=>['created_at > ? and created_at <= ?',@begin_at,@end_at],
      :order=>'created_at DESC',:readonly=>true)
  end
  
end