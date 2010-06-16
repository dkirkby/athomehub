class CreateBinnedSamples < ActiveRecord::Migration
  def self.up
    create_table :binned_samples do |t|
      t.integer :networkID
      t.integer :binCode
      t.float :temperature
      t.float :lighting
      t.float :artificial
      t.float :power

      t.timestamps
    end
  end

  def self.down
    drop_table :binned_samples
  end
end
