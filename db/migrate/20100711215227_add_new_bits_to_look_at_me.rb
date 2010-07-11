class AddNewBitsToLookAtMe < ActiveRecord::Migration
  def self.up
    add_column :look_at_mes, :wdogReset, :boolean
    add_column :look_at_mes, :brownoutReset, :boolean
    add_column :look_at_mes, :extReset, :boolean
    add_column :look_at_mes, :powerReset, :boolean
  end

  def self.down
    remove_column :look_at_mes, :powerReset
    remove_column :look_at_mes, :extReset
    remove_column :look_at_mes, :brownoutReset
    remove_column :look_at_mes, :wdogReset
  end
end
