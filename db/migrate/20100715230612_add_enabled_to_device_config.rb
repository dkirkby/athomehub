class AddEnabledToDeviceConfig < ActiveRecord::Migration
  def self.up
    add_column :device_configs, :enabled, :boolean
    # mark all existing configs as enabled since this was the implicit default before
    DeviceConfig.reset_column_information
    DeviceConfig.find(:all).each do |c|
      c.update_attribute :enabled, true
    end
  end

  def self.down
    remove_column :device_configs, :enabled
  end
end
