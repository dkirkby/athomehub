class Engineering::ConfigController < ApplicationController

  def index
    @configs = DeviceConfigs.find(:all)
  end

  def create
  end

  def update
  end

end
