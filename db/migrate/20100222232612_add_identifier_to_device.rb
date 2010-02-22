class AddIdentifierToDevice < ActiveRecord::Migration
  def self.up
    add_column :devices, :identifier, :integer
  end

  def self.down
    remove_column :devices, :identifier
  end
end
