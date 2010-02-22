class CreateDevices < ActiveRecord::Migration
  def self.up
    create_table :devices do |t|
      t.boolean :configured
      t.string :location

      t.timestamps
    end
  end

  def self.down
    drop_table :devices
  end
end
