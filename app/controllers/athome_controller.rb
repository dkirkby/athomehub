class AthomeController < ApplicationController

  def index
    @samples = Sample.find(:all,:group=>'networkID',
      :conditions=>'networkID IS NOT NULL',:readonly=>true)
  end

end
