class RemoveUpdatedAtFromLookAtMe < ActiveRecord::Migration
  def self.up
    remove_column :look_at_mes, :updated_at
  end

  def self.down
    add_column :look_at_mes, :updated_at, :datetime
  end
end
