class AddDumpIntervalToDeviceConfig < ActiveRecord::Migration
  def self.up
    add_column :device_configs, :dumpInterval, :integer
  end

  def self.down
    remove_column :device_configs, :dumpInterval
  end
end
