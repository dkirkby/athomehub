class RemoveTempRangeFromDeviceConfig < ActiveRecord::Migration
  def self.up
    remove_column :device_configs, :minTemperature
    remove_column :device_configs, :maxTemperature
  end

  def self.down
    add_column :device_configs, :maxTemperature, :decimal, :precision => 5, :scale => 2
    add_column :device_configs, :minTemperature, :decimal, :precision => 5, :scale => 2
  end
end
