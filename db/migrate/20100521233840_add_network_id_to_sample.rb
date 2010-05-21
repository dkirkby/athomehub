class AddNetworkIdToSample < ActiveRecord::Migration
  def self.up
    add_column :samples, :networkID, :integer
  end

  def self.down
    remove_column :samples, :networkID
  end
end
