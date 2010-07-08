class AddLightFactorToSample < ActiveRecord::Migration
  def self.up
    add_column :samples, :lightFactor, :integer
  end

  def self.down
    remove_column :samples, :lightFactor
  end
end
