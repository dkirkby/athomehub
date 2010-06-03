class AddSourceToBufferDump < ActiveRecord::Migration
  def self.up
    add_column :buffer_dumps, :source, :integer
  end

  def self.down
    remove_column :buffer_dumps, :source
  end
end
