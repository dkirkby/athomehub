class DeviceConfig < ActiveRecord::Base

  validates_uniqueness_of :serialNumber
  validates_uniqueness_of :networkID
  validates_uniqueness_of :location

end
