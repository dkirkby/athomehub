class Engineering::ConfigController < Engineering::ApplicationController

  def active
    @configs = DeviceConfig.find(:all,:order=>'id DESC',:group=>:serialNumber,:readonly=>true)
    render :action=>"index"
  end

  def index
    @configs = DeviceConfig.find(:all,:order=>'id DESC',:readonly=>true)
  end

  def new
    @config = DeviceConfig.new
    # set defaults (capability booleans are false by default)
    @config.dumpInterval = 16 # samples
    @config.comfortTempMin = 70 # degF
    @config.comfortTempMax = 80 # degF
    @config.selfHeatOffset = 0 # degF/100
    @config.selfHeatDelay = 0 # secs*10
    @config.fiducialHiLoDelta = 90 # microsecs
    @config.fiducialShiftHi = 3000 # microsecs
    @config.powerGainHi = 253 # mW/ADC
    @config.powerGainLo = 4500 # mW/ADC
    @config.nClipCut = 8 # samples
  end
  
  def edit
    # Edit action returns a clone of the original element so that
    # all config history is preserved. The follow-up action should
    # be "create" instead of the usual "update".
    old_config = DeviceConfig.find(params[:id],:readonly=>true)
    @config = old_config.clone
  end

  def create
    @config = DeviceConfig.new(params[:device_config])
    if @config.save
      flash[:notice] = 'Device configuration was successfully saved.'
      redirect_to :action=>"active"
    else
      render :action=>"new"
    end
  end

  def raw
    @config = DeviceConfig.find(params[:id],:readonly=>true)
    respond_to do |format|
      format.text { render :text=> @config.serialize_for_device + @config.lcd_format }
    end
  end

end
