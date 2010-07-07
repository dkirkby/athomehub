class AddStuffToSample < ActiveRecord::Migration
  def self.up
    add_column :samples, :lighting, :float
    add_column :samples, :power, :float
    add_column :samples, :powerFactor, :integer
    add_column :samples, :complexity, :integer
  end

  def self.down
    remove_column :samples, :complexity
    remove_column :samples, :powerFactor
    remove_column :samples, :power
    remove_column :samples, :lighting
  end
end
