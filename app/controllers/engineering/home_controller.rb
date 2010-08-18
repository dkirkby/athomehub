class Engineering::HomeController < Engineering::ApplicationController

  def index
    @devices = [ ]
    # find the latest device configurations
    DeviceConfig.latest(@at).find(:all,:order=>'serialNumber ASC').each do |config|
      # look for a profile with the same network ID
      netID = config.networkID
      profile = DeviceProfile.for_networkID(netID,@at).last
      @devices << { :config => config, :profile => profile }
    end
  end

end
