class Engineering::ConfigController < Engineering::ApplicationController

  def index
    @configs = DeviceConfig.latest_at(@at)
  end

  def all
    @configs = DeviceConfig.find(:all,:order=>'id DESC',:readonly=>true)
  end

  def new
    @config = DeviceConfig.new
    @config.enabled = true
    # set defaults (capability booleans are false by default)
    @config.lightingFeedback = true
    @config.lightingDump = true
    @config.powerDump = true
    @config.audioDiagnostics = true
    @config.powerEdgeAudio = true
    @config.powerLevelAudio = true
    @config.lightAudio = true
    @config.dumpInterval = 2 # samples
    @config.comfortTempMin = 70 # degF
    @config.comfortTempMax = 80 # degF
    @config.selfHeatOffset = 0 # degF/100
    @config.selfHeatDelay = 0 # secs*10
    @config.fiducialHiLoDelta = 100 # microsecs
    @config.fiducialShiftHi = 3500 # microsecs
    @config.powerGainHi = 253 # mW/ADC
    @config.powerGainLo = 4500 # mW/ADC
    @config.nClipCut = 8 # samples
    @config.powerAudioControl = 0x1771 # =6001
    @config.lightFidHiLoDelta = 150 # microsecs
		@config.lightFidShiftHi = 7827 # microsecs
		@config.lightGainHi = 127 # gain of 1.0
		@config.lightGainHiLoRatio = 46562 # gain of about 22
		@config.darkThreshold = 0x040a # high byte is for low-gain
		@config.artificialThreshold = 5 # /512
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
      redirect_to :action=>"index"
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
