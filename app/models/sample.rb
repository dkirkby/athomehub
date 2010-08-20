class Sample < ActiveRecord::Base

  include Measured
  include Scoped

  # We do not implement a :latest named_scope similar to the DeviceConfig and
  # DeviceProfile models because the correlated subquery used there is too
  # slow for a table with many records.

  def values_as_array
    [
      self.temperature,
      (self.lighting or @@float16_inf),
      self.artificial,
      self.lightFactor,
      (self.power or @@float16_inf),
      self.powerFactor,
      self.complexity
    ]
  end
  
protected

  # An infinite float16 lighting or power value is saved in the Sample
  # table using database NULL and read back as ruby nil. Translate it
  # to the value below.
  @@float16_inf = 32768

end