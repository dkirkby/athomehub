class RemoveUpdatedAtFromDeviceLog < ActiveRecord::Migration
  def self.up
    remove_column :device_logs, :updated_at
  end

  def self.down
    add_column :device_logs, :updated_at, :datetime
  end
end
