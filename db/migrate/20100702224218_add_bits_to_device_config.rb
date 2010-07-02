class AddBitsToDeviceConfig < ActiveRecord::Migration
  def self.up
    add_column :device_configs, :audioDiagnostics, :boolean
    add_column :device_configs, :powerEdgeAudio, :boolean
    add_column :device_configs, :powerLevelAudio, :boolean
    add_column :device_configs, :greenGlow, :boolean
    add_column :device_configs, :amberGlow, :boolean
    add_column :device_configs, :redGlow, :boolean
    add_column :device_configs, :greenFlash, :boolean
    add_column :device_configs, :amberFlash, :boolean
    add_column :device_configs, :redFlash, :boolean
    add_column :device_configs, :blueFlash, :boolean
  end

  def self.down
    remove_column :device_configs, :blueFlash
    remove_column :device_configs, :redFlash
    remove_column :device_configs, :amberFlash
    remove_column :device_configs, :greenFlash
    remove_column :device_configs, :redGlow
    remove_column :device_configs, :amberGlow
    remove_column :device_configs, :greenGlow
    remove_column :device_configs, :powerLevelAudio
    remove_column :device_configs, :powerEdgeAudio
    remove_column :device_configs, :audioDiagnostics
  end
end
