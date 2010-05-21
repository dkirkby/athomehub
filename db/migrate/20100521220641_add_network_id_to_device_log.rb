class AddNetworkIdToDeviceLog < ActiveRecord::Migration
  def self.up
    add_column :device_logs, :networkID, :integer
  end

  def self.down
    remove_column :device_logs, :networkID
  end
end
