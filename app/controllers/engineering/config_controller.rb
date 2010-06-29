class Engineering::ConfigController < Engineering::ApplicationController

  def index
    @configs = DeviceConfig.all
  end

  def new
    @config = DeviceConfig.new    
  end
  
  def edit
    @config = DeviceConfig.find(params[:id])
  end

  def create
    @config = DeviceConfig.new(params[:device_config])
    if @config.save
      flash[:notice] = 'Device configuration was successfully created.'
      redirect_to :action=>"index"
    else
      render :action=>"new"
    end
  end

  def update
    @config = DeviceConfig.find(params[:id])
    if @config.update_attributes(params[:device_config])
      flash[:notice] = 'Device configuration was successfully updated.'
      redirect_to :action=>"index"
    else
      render :action=>"edit"
    end
  end

  def destroy
    @config = DeviceConfig.find(params[:id])
    @config.destroy
    redirect_to :action=>"index"
  end
  
  def raw
    @config = DeviceConfig.find(params[:id])
    respond_to do |format|
      format.text { render :text=> @config.serialize_for_device + @config.lcd_format }
    end
  end

end
