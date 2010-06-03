class RemoveTypeFromBufferDump < ActiveRecord::Migration
  def self.up
    remove_column :buffer_dumps, :type
  end

  def self.down
    add_column :buffer_dumps, :type, :integer
  end
end
