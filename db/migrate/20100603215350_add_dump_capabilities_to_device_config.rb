class AddDumpCapabilitiesToDeviceConfig < ActiveRecord::Migration
  def self.up
    add_column :device_configs, :lightingDump, :boolean
    add_column :device_configs, :powerDump, :boolean
  end

  def self.down
    remove_column :device_configs, :powerDump
    remove_column :device_configs, :lightingDump
  end
end
