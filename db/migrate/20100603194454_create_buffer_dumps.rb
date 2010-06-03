class CreateBufferDumps < ActiveRecord::Migration
  def self.up
    create_table :buffer_dumps do |t|
      t.timestamp :created_at
      t.integer :networkID
      t.string :header
      t.integer :type
      t.integer :micros
      t.text :samples
    end
  end

  def self.down
    drop_table :buffer_dumps
  end
end
