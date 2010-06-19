class AddIndicesToBinnedSample < ActiveRecord::Migration
  def self.up
    add_index :binned_samples, :binCode
  end

  def self.down
    remove_index :binned_samples, :binCode
  end
end
