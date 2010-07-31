class AddUsageToBinnedSample < ActiveRecord::Migration
  def self.up
    add_column :binned_samples, :energyUsage, :float
  end

  def self.down
    remove_column :binned_samples, :energyUsage
  end
end
