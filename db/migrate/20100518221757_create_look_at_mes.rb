class CreateLookAtMes < ActiveRecord::Migration
  def self.up
    create_table :look_at_mes do |t|
      t.string :serialNumber
      t.datetime :commitDate
      t.string :commitID
      t.boolean :modified

      t.timestamps
    end
  end

  def self.down
    drop_table :look_at_mes
  end
end
