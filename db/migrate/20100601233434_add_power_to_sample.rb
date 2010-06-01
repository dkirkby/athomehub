class AddPowerToSample < ActiveRecord::Migration
  def self.up
    add_column :samples, :power2, :integer
    add_column :samples, :acPhase, :integer
  end

  def self.down
    remove_column :samples, :acPhase
    remove_column :samples, :power2
  end
end
