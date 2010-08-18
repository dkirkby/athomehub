class Engineering::HomeController < Engineering::ApplicationController

  def index
    @devices = [ ]
    # find the latest device configurations
    DeviceConfig.latest.find(:all,:order=>'serialNumber ASC').each do |config|
      @devices << { :config => config }
    end
  end

end
