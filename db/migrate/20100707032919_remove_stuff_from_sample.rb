class RemoveStuffFromSample < ActiveRecord::Migration
  def self.up
    remove_column :samples, :lighting
    remove_column :samples, :power
    remove_column :samples, :lighting2
    remove_column :samples, :artificial2
    remove_column :samples, :power2
    remove_column :samples, :acPhase
  end

  def self.down
    add_column :samples, :acPhase, :integer
    add_column :samples, :power2, :integer
    add_column :samples, :artificial2, :integer
    add_column :samples, :lighting2, :integer
    add_column :samples, :power, :integer
    add_column :samples, :lighting, :integer
  end
end
