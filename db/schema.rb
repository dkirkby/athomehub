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

ActiveRecord::Schema.define(:version => 20100619215005) do

  create_table "binned_samples", :force => true do |t|
    t.integer "networkID"
    t.integer "binCode"
    t.float   "temperature"
    t.float   "lighting"
    t.float   "artificial"
    t.float   "power"
  end

  add_index "binned_samples", ["binCode"], :name => "index_binned_samples_on_binCode"

  create_table "buffer_dumps", :force => true do |t|
    t.datetime "created_at"
    t.integer  "networkID"
    t.string   "header"
    t.integer  "micros"
    t.text     "samples"
    t.integer  "source"
  end

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
    t.boolean  "lightingDump"
    t.boolean  "powerDump"
  end

  create_table "device_logs", :force => true do |t|
    t.integer  "code"
    t.integer  "value"
    t.datetime "created_at"
    t.integer  "severity"
    t.integer  "networkID"
  end

  create_table "look_at_mes", :force => true do |t|
    t.string   "serialNumber"
    t.datetime "commitDate"
    t.string   "commitID"
    t.boolean  "modified"
    t.datetime "created_at"
  end

  create_table "notes", :force => true do |t|
    t.integer  "user_id"
    t.string   "view"
    t.datetime "view_at"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "samples", :force => true do |t|
    t.integer  "temperature"
    t.integer  "lighting"
    t.integer  "artificial"
    t.integer  "power"
    t.datetime "created_at"
    t.integer  "lighting2"
    t.integer  "artificial2"
    t.integer  "networkID"
    t.integer  "power2"
    t.integer  "acPhase"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
