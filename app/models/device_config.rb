class DeviceConfig < ActiveRecord::Base

  validates_uniqueness_of :serialNumber
  validates_uniqueness_of :networkID
  validates_uniqueness_of :location

  validates_numericality_of :minTemperature,
    :greater_than_or_equal_to=>0, :less_than=>200
  validates_numericality_of :maxTemperature,
    :greater_than_or_equal_to=>0, :less_than=>200
  validates_numericality_of :networkID, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>255
    
  validates_format_of :serialNumber, :with=>/^[0-9a-fA-F]{8}$/,
    :message=>"is invalid (expected 8 hex digits)"
    
  validate :min_less_than_max
  
  def min_less_than_max
    errors.add_to_base("min temperature must be < max temperature") unless minTemperature < maxTemperature
  end

  def serialize_for_device
    "hello world\n"
  end

end