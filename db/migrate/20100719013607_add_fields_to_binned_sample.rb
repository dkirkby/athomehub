class AddFieldsToBinnedSample < ActiveRecord::Migration
  def self.up
    add_column :binned_samples, :lightFactor, :float
    add_column :binned_samples, :powerFactor, :float
    add_column :binned_samples, :complexity, :float
    add_column :binned_samples, :binCount, :integer
  end

  def self.down
    remove_column :binned_samples, :binCount
    remove_column :binned_samples, :complexity
    remove_column :binned_samples, :powerFactor
    remove_column :binned_samples, :lightFactor
  end
end
