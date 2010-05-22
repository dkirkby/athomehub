class Sample < ActiveRecord::Base

  belongs_to :config,
    :class_name => "DeviceConfig",
    :foreign_key => "networkID",
    :primary_key => "networkID",
    :readonly => true

  def location
    config.location if config
  end
  
  def cost
  end

end
