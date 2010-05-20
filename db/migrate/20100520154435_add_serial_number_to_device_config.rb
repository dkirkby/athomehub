class AddSerialNumberToDeviceConfig < ActiveRecord::Migration
  def self.up
    add_column :device_configs, :serialNumber, :string
  end

  def self.down
    remove_column :device_configs, :serialNumber
  end
end
