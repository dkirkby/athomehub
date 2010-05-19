class Engineering::ApplicationController < ApplicationController

protected

  # Validates input params['n'] and uses it to set @n
  def valid_n
    @n = 10 # this is the default
    if params.has_key? 'n'
      value = params['n'].to_i
      if value < 1 or value > 1000
        flash.now[:notice] = "Invalid parameter n=#{params['n']}. Using #{@n} instead."
      else
        @n = value
      end
    end
  end

end
