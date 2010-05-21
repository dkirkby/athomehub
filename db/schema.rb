# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100521212232) do

  create_table "device_configs", :force => true do |t|
    t.string   "location"
    t.integer  "networkID"
    t.boolean  "lightingFeedback"
    t.boolean  "temperatureFeedback"
    t.decimal  "minTemperature",      :precision => 5, :scale => 2
    t.decimal  "maxTemperature",      :precision => 5, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "serialNumber"
  end

  create_table "device_logs", :force => true do |t|
    t.integer  "code"
    t.integer  "value"
    t.datetime "created_at"
    t.integer  "severity"
  end

  create_table "look_at_mes", :force => true do |t|
    t.string   "serialNumber"
    t.datetime "commitDate"
    t.string   "commitID"
    t.boolean  "modified"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "samples", :force => true do |t|
    t.integer  "seqno"
    t.integer  "temperature"
    t.integer  "lighting"
    t.integer  "artificial"
    t.integer  "power"
    t.datetime "created_at"
    t.integer  "lighting2"
    t.integer  "artificial2"
  end

end
