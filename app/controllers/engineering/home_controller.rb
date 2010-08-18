class Engineering::HomeController < Engineering::ApplicationController

  def index
    @devices = [ ]
    # find the latest device configurations
    DeviceConfig.latest(@at).find(:all,:order=>'serialNumber ASC',
      :readonly=>true).each do |config|
      # look for a profile with the same network ID
      netID = config.networkID
      profile = DeviceProfile.for_networkID(netID,@at).last
      dev = { :config => config, :profile => profile }
      # fetch the most recent samples
      samples = Sample.for_networkID(netID).find(:all,:order=>'id DESC',:limit=>10,
        :readonly=>true)
      # calculate the elapsed time to record the recent samples
      if samples.length > 0 then
        if @at - samples.last.created_at > 30.seconds
          dev[:samples] = "last #{@template.time_ago_in_words samples.last.created_at} ago"
        else
          dev[:samples] = "#{samples.length} in #{@template.time_ago_as words samples.first.created_at}"
        end
      else
        dev[:samples] = "none"
      end
      @devices << dev
    end
  end

end
