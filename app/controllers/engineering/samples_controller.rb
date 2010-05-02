class Engineering::SamplesController < ApplicationController

  before_filter :valid_n,:only=>:recent

  def recent
    @count = Sample.count
    @samples = Sample.find(:all,:limit=>@nrecent,:order=>'created_at DESC',:readonly=>true)
  end

  def bydate
  end
  
protected
  
  # Validates params['n'] and uses it to set @nrecent
  def valid_n
    @nrecent = 10 # this is the default
    if params.has_key? 'n'
      value = params['n'].to_i
      if value < 1 or value > 1000
        flash[:notice] = "Invalid parameter n=#{params['n']}. Using #{@nrecent} instead."
      else
        @nrecent = value
      end
    end
  end
  
end
