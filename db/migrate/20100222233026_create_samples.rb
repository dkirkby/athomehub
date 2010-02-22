class CreateSamples < ActiveRecord::Migration
  def self.up
    create_table :samples do |t|
      t.reference :device_id
      t.integer :seqno
      t.integer :temperature
      t.integer :lighting
      t.integer :artificial
      t.integer :power
      t.datetime :created_at
    end
  end

  def self.down
    drop_table :samples
  end
end
