class RenameColsOfBinnedSample < ActiveRecord::Migration
  def self.up
    rename_column :binned_samples, :temperature, :temperatureSum
    rename_column :binned_samples, :lighting, :lightingSum
    rename_column :binned_samples, :artificial, :artificialSum
    rename_column :binned_samples, :lightFactor, :lightFactorSum
    rename_column :binned_samples, :power, :powerSum
    rename_column :binned_samples, :powerFactor, :powerFactorSum
    rename_column :binned_samples, :complexity, :complexitySum
  end

  def self.down
    rename_column :binned_samples, :temperatureSum, :temperature
    rename_column :binned_samples, :lightingSum, :lighting
    rename_column :binned_samples, :artificialSum, :artificial
    rename_column :binned_samples, :lightFactorSum, :lightFactor
    rename_column :binned_samples, :powerSum, :power
    rename_column :binned_samples, :powerFactorSum, :powerFactor
    rename_column :binned_samples, :complexitySum, :complexity
  end
end
