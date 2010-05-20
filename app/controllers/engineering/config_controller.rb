class Engineering::ConfigController < ApplicationController

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
      flash[:notice] = 'DeviceConfig was successfully created.'
      redirect_to :action=>"index"
    else
      render :action=>"new"
    end
  end

  def update
    @config = DeviceConfig.find(params[:id])
    if @config.update_attributes(params[:config])
      flash[:notice] = 'DeviceConfig was successfully updated.'
      redirect_to :action=>index
    else
      render :action=>"edit"
    end
  end

  def destroy
    @config = DeviceConfig.find(params[:id])
    @config.destroy
    redirect_to :action=>"index"
  end

end
