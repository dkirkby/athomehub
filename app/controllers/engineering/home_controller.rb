class Engineering::HomeController < Engineering::ApplicationController

  def index
    @devices = [ ]
    # find the latest device configurations
    DeviceConfig.latest(@at).find(:all,:order=>'serialNumber ASC').each do |config|
      # look for a profile with the same network ID
      @devices << { :config => config }
    end
  end

end
