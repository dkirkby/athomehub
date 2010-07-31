class AddUsageToBinnedSample < ActiveRecord::Migration
  def self.up
    add_column :binned_samples, :usage, :float
  end

  def self.down
    remove_column :binned_samples, :usage
  end
end
