class CreateDeviceLogs < ActiveRecord::Migration
  def self.up
    create_table :device_logs do |t|
      t.integer :code
      t.integer :value

      t.timestamps
    end
  end

  def self.down
    drop_table :device_logs
  end
end
