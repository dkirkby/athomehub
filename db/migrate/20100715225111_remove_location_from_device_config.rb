class RemoveLocationFromDeviceConfig < ActiveRecord::Migration
  def self.up
    remove_column :device_configs, :location
  end

  def self.down
    add_column :device_configs, :location, :string
  end
end
