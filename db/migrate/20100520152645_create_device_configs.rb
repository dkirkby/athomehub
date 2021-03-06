class CreateDeviceConfigs < ActiveRecord::Migration
  def self.up
    create_table :device_configs do |t|
      t.string :location
      t.integer :networkID
      t.boolean :lightingFeedback
      t.boolean :temperatureFeedback
      t.decimal :minTemperature, :precision=>5, :scale=>2
      t.decimal :maxTemperature, :precision=>5, :scale=>2

      t.timestamps
    end
  end

  def self.down
    drop_table :device_configs
  end
end
