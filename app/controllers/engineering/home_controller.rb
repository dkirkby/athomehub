class Engineering::HomeController < Engineering::ApplicationController

  def index
    @devices = [ ]
    # find the latest device configurations
    DeviceConfig.latest(@at).find(:all,:order=>'serialNumber ASC',
      :readonly=>true).each do |config|
      dev = { :config => config }
      # look for a profile with the same network ID
      netID = config.networkID
      profile = DeviceProfile.for_networkID(netID,@at).last
      dev[:profile] = profile.description if profile
      # look for the most recent log of this device being configured
      last = DeviceLog.for_networkID(netID,@at).find(:last,:conditions=>'code in (-4,-5)')
      dev[:last_config] = last.created_at if last
      # fetch the most recent sample from this device, if any
      last = Sample.for_networkID(netID,@at).last
      dev[:last_sample] = last.created_at if last
      # fetch the most recent dumps from this device, if any
      last = BufferDump.for_networkID(netID,@at).find(:last,:conditions=>'source in (0,1,4)')
      dev[:last_power_dump] = last.created_at if last
      last = BufferDump.for_networkID(netID,@at).find(:last,:conditions=>'source in (2,3)')
      dev[:last_light_dump] = last.created_at if last
      # fetch the most recent LAM from this device, if any
      last = LookAtMe.for_serialNumber(config.serialNumber).last
      dev[:last_lam] = last if last        
      @devices << dev
    end
  end

end
