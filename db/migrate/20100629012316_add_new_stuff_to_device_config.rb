class AddNewStuffToDeviceConfig < ActiveRecord::Migration
  def self.up
    add_column :device_configs, :comfortTempMin, :integer
    add_column :device_configs, :comfortTempMax, :integer
    add_column :device_configs, :selfHeatOffset, :integer
    add_column :device_configs, :selfHeatDelay, :integer
    add_column :device_configs, :fiducialHiLoDelta, :integer
    add_column :device_configs, :fiducialShiftHi, :integer
    add_column :device_configs, :powerGainHi, :integer
    add_column :device_configs, :powerGainLo, :integer
    add_column :device_configs, :nClipCut, :integer
  end

  def self.down
    remove_column :device_configs, :nClipCut
    remove_column :device_configs, :powerGainLo
    remove_column :device_configs, :powerGainHi
    remove_column :device_configs, :fiducialShiftHi
    remove_column :device_configs, :fiducialHiLoDelta
    remove_column :device_configs, :selfHeatDelay
    remove_column :device_configs, :selfHeatOffset
    remove_column :device_configs, :comfortTempMax
    remove_column :device_configs, :comfortTempMin
  end
end
