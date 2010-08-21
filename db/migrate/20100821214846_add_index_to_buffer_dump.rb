class AddIndexToBufferDump < ActiveRecord::Migration

  def self.up
    add_index :buffer_dumps, :networkID
    add_index :buffer_dumps, :source
  end

  def self.down
    remove_index :buffer_dumps, :networkID
    remove_index :buffer_dumps, :source
  end

end
