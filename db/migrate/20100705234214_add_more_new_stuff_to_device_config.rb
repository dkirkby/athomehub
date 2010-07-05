class AddMoreNewStuffToDeviceConfig < ActiveRecord::Migration
  def self.up
    add_column :device_configs, :lightAudio, :boolean
    add_column :device_configs, :powerAudioControl, :integer
    add_column :device_configs, :lightFidHiLoDelta, :integer
    add_column :device_configs, :lightFidShiftHi, :integer
    add_column :device_configs, :lightGainHi, :integer
    add_column :device_configs, :lightGainHiLoRatio, :integer
    add_column :device_configs, :darkThreshold, :integer
    add_column :device_configs, :artificialThreshold, :integer
  end

  def self.down
    remove_column :device_configs, :artificialThreshold
    remove_column :device_configs, :darkThreshold
    remove_column :device_configs, :lightGainHiLoRatio
    remove_column :device_configs, :lightGainHi
    remove_column :device_configs, :lightFidShiftHi
    remove_column :device_configs, :lightFidHiLoDelta
    remove_column :device_configs, :powerAudioControl
    remove_column :device_configs, :lightAudio
  end
end
