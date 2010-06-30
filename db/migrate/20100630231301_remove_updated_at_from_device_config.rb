class RemoveUpdatedAtFromDeviceConfig < ActiveRecord::Migration
  def self.up
    remove_column :device_configs, :updated_at
  end

  def self.down
    add_column :device_configs, :updated_at, :datetime
  end
end
