class Engineering::ProfileController < Engineering::ApplicationController

  def index
    @profiles = DeviceProfile.latest(@at).find(:all,:order=>'networkID ASC')
  end

  def all
    @profiles = DeviceProfile.find(:all,:order=>'networkID ASC',:readonly=>true)
  end

  def new
    @profile = DeviceProfile.new
    # by default, a new config displays after all existing configs
    last = DeviceProfile.latest.last
    @profile.display_order = last ? (last.display_order + 1) : 0
  end

  def edit
    # Edit action returns a clone of the original record so that
    # all history is preserved. The follow-up action should
    # be "create" instead of the usual "update".
    old_profile = DeviceProfile.find(params[:id],:readonly=>true)
    @profile = old_profile.clone
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
