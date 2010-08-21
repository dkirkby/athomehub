class AddIndexToBufferDump < ActiveRecord::Migration
  def self.up
    add_index :buffer_dumps, :networkID
  end

  def self.down
    remove_index :buffer_dumps, :networkID
  end
end
