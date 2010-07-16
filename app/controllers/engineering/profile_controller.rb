class Engineering::ProfileController < Engineering::ApplicationController

  def index
    @profiles = DeviceProfile.latest(@at).find(:all,:order=>'networkID ASC')
  end

end
