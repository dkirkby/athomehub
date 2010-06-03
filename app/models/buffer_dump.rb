class BufferDump < ActiveRecord::Base

  belongs_to :config,
    :class_name => "DeviceConfig",
    :foreign_key => "networkID",
    :primary_key => "networkID",
    :readonly => true

  def init_samples(size,values)
    @samples = Array.new(size)
    self.add_samples 0,values
  end

  def add_samples(base,values)
    values.each_with_index do |v,k|
      @samples[base+k]= v.hex
      puts "#{base+k} -> #{v}"
    end
  end

end
