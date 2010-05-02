class AddExtraLightingToSample < ActiveRecord::Migration
  def self.up
    add_column :samples, :lighting2, :integer
    add_column :samples, :artificial2, :integer
  end

  def self.down
    remove_column :samples, :artificial2
    remove_column :samples, :lighting2
  end
end
