class Engineering::HomeController < Engineering::ApplicationController

  def index
    # scan the last 1000 samples
    last_sample = { }
    Sample.find(:all,:select=>'networkID,created_at',
      :order=>'id DESC',:limit=>1000).each do |sample|
      netID = sample.networkID
      last_sample[netID] = sample unless last_sample[netID]
    end
    # scan the last 1000 device log messages
    last_config = { }
    DeviceLog.find(:all,:select=>'code,created_at,networkID',
      :order=>'id DESC',:limit=>1000).each do |log|
      next unless (log.code == -4 || log.code == -5)
      netID = log.networkID
      last_config[netID] = log unless last_config[netID]
    end
    # scan the last 100 buffer dumps
    last_power_dump = { }
    last_light_dump = { }
    BufferDump.find(:all,:select=>'created_at,networkID,source',
      :order=>'id DESC',:limit=>100).each do |dump|
      netID = dump.networkID
      if dump.source == 2 || dump.source == 3 then
        last_light_dump[netID] = dump unless last_light_dump[netID]
      else
        last_power_dump[netID] = dump unless last_power_dump[netID]
      end
    end
    # scan the latest device configurations
    @devices = [ ]
    DeviceConfig.latest(@at).find(:all,:order=>'serialNumber ASC',
      :readonly=>true).each do |config|
      dev = { :config => config }
      # look for a profile with the same network ID
      netID = config.networkID
      profile = DeviceProfile.for_networkID(netID,@at).last
      if profile then
        dev[:profile] = profile.description
        dev[:profile_id] = profile.id
      end
      # look for the most recent log of this device being configured
      ##last = DeviceLog.for_networkID(netID,@at).find(:last,:conditions=>'code in (-4,-5)')
      last = last_config[netID]
      dev[:last_config] = last.created_at if last
      # fetch the most recent sample from this device, if any
      ##last = Sample.for_networkID(netID,@at).last
      last = last_sample[netID]
      dev[:last_sample] = last.created_at if last
      # fetch the most recent dumps from this device, if any
      ##last = BufferDump.for_networkID(netID,@at).find(:last,:conditions=>'source=0')
      last = last_power_dump[netID]
      dev[:last_power_dump] = last.created_at if last
      ##last = BufferDump.for_networkID(netID,@at).find(:last,:conditions=>'source=2')
      last = last_light_dump[netID]
      dev[:last_light_dump] = last.created_at if last
      # fetch the most recent LAM from this device, if any
      last = LookAtMe.for_serialNumber(config.serialNumber,@at).last
      dev[:last_lam] = last if last        
      @devices << dev
    end
    # find the most recent LAM record from a hub
    @hub = nil
    LookAtMe.find_latest.each do |lam|
      next unless lam.is_hub?
      next if @hub and @hub.created_at > lam.created_at
      @hub = lam
    end
  end

end
