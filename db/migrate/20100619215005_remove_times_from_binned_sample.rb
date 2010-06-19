class RemoveTimesFromBinnedSample < ActiveRecord::Migration
  def self.up
    remove_column :binned_samples, :created_at
    remove_column :binned_samples, :updated_at
  end

  def self.down
    add_column :binned_samples, :updated_at, :datetime
    add_column :binned_samples, :created_at, :datetime
  end
end
