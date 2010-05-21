class RemoveSeqnoFromSample < ActiveRecord::Migration
  def self.up
    remove_column :samples, :seqno
  end

  def self.down
    add_column :samples, :seqno, :integer
  end
end
