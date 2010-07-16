class CreateDeviceProfiles < ActiveRecord::Migration
  def self.up
    create_table :device_profiles do |t|
      t.integer :networkID
      t.string :description
      t.datetime :created_at
      t.integer :display_order
    end
  end

  def self.down
    drop_table :device_profiles
  end
end
