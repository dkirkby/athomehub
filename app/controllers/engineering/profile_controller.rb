class Engineering::ProfileController < Engineering::ApplicationController

  def index
    @profiles = DeviceProfile.latest(@at).find(:all,:order=>'networkID ASC')
  end

  def new
    @profile = DeviceProfile.new
    # by default, a new config displays after all existing configs
    last = DeviceProfile.latest.last
    @profile.display_order = last ? (last.display_order + 1) : 0
  end

end
