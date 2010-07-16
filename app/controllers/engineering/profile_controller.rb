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

  def create
    @profile = DeviceProfile.new(params[:device_profile])
    if @profile.save
      flash[:notice] = 'Device profile was successfully saved.'
      redirect_to :action=>"index"
    else
      render :action=>"new"
    end
  end

end
