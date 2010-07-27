class Sample < ActiveRecord::Base

  include Measured

  # We do not implement a :latest named_scope similar to the DeviceConfig and
  # DeviceProfile models because the correlated subquery used there is too
  # slow for a table with many records.

  # Returns samples recorded for the specified networkID up to the specified
  # utc time which defaults to now.
  named_scope :for_networkID, lambda { |*args|
    {
      :order => 'id ASC',
      :conditions => (args.length > 1) ?
        [ 'networkID = ? and created_at <= ?',args.first,args.last ] :
        [ 'networkID = ?',args.first ],
      :readonly => true
    }
  }

  def values_as_hash
    {
      :temperatureSum => self.temperature,
      :lightingSum => (self.lighting or @@float16_inf),
      :artificialSum => self.artificial,
      :lightFactorSum => self.lightFactor,
      :powerSum => (self.power or @@float16_inf),
      :powerFactorSum => self.powerFactor,
      :complexitySum => self.complexity
    }
  end
  
protected

  # An infinite float16 lighting or power value is saved in the Sample
  # table using database NULL and read back as ruby nil. Translate it
  # to the value below.
  @@float16_inf = 32768

end