class AddSeverityToDeviceLog < ActiveRecord::Migration
  def self.up
    add_column :device_logs, :severity, :integer
  end

  def self.down
    remove_column :device_logs, :severity
  end
end
