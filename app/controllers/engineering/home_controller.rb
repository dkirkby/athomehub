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
      dev[:profile] = profile
      # look for the most recent log of this device being configured
      last_config = DeviceLog.for_networkID(netID).find(:last,
        :conditions=>'code = -4 or code = -5',:readonly=>true)
      if last_config then
        dev[:last_config] = @template.time_ago_in_words last_config.created_at
      else
        dev[:last_config] = 'unconfigured'
      end
      # fetch the most recent sample from this device
      last_sample = Sample.for_networkID(netID).last
      if last_sample then
        dev[:last_sample] = @template.time_ago_in_words last_sample.created_at
      else
        dev[:last_sample] = 'no data'
      end
      @devices << dev
    end
  end

end
