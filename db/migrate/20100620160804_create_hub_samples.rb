class CreateHubSamples < ActiveRecord::Migration
  def self.up
    create_table :hub_samples do |t|
      t.datetime :created_at
      t.float :temperature
      t.float :humidity
    end
  end

  def self.down
    drop_table :hub_samples
  end
end
