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

ActiveRecord::Schema.define(:version => 20100821214846) do

  create_table "binned_samples", :force => true do |t|
    t.integer "networkID"
    t.integer "binCode"
    t.float   "temperatureSum"
    t.float   "lightingSum"
    t.float   "artificialSum"
    t.float   "powerSum"
    t.float   "lightFactorSum"
    t.float   "powerFactorSum"
    t.float   "complexitySum"
    t.integer "binCount"
    t.float   "energyUsage"
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

  add_index "buffer_dumps", ["networkID"], :name => "index_buffer_dumps_on_networkID"
  add_index "buffer_dumps", ["source"], :name => "index_buffer_dumps_on_source"

  create_table "device_configs", :force => true do |t|
    t.integer  "networkID"
    t.boolean  "lightingFeedback"
    t.boolean  "temperatureFeedback"
    t.datetime "created_at"
    t.string   "serialNumber"
    t.boolean  "lightingDump"
    t.boolean  "powerDump"
    t.integer  "comfortTempMin"
    t.integer  "comfortTempMax"
    t.integer  "selfHeatOffset"
    t.integer  "selfHeatDelay"
    t.integer  "fiducialHiLoDelta"
    t.integer  "fiducialShiftHi"
    t.integer  "powerGainHi"
    t.integer  "powerGainLo"
    t.integer  "nClipCut"
    t.integer  "dumpInterval"
    t.boolean  "audioDiagnostics"
    t.boolean  "powerEdgeAudio"
    t.boolean  "powerLevelAudio"
    t.boolean  "greenGlow"
    t.boolean  "amberGlow"
    t.boolean  "redGlow"
    t.boolean  "greenFlash"
    t.boolean  "amberFlash"
    t.boolean  "redFlash"
    t.boolean  "blueFlash"
    t.boolean  "lightAudio"
    t.integer  "powerAudioControl"
    t.integer  "lightFidHiLoDelta"
    t.integer  "lightFidShiftHi"
    t.integer  "lightGainHi"
    t.integer  "lightGainHiLoRatio"
    t.integer  "darkThreshold"
    t.integer  "artificialThreshold"
    t.boolean  "enabled"
  end

  create_table "device_logs", :force => true do |t|
    t.integer  "code"
    t.integer  "value"
    t.datetime "created_at"
    t.integer  "severity"
    t.integer  "networkID"
  end

  create_table "device_profiles", :force => true do |t|
    t.integer  "networkID"
    t.string   "description"
    t.datetime "created_at"
    t.integer  "display_order"
  end

  create_table "hub_samples", :force => true do |t|
    t.datetime "created_at"
    t.float    "temperature"
    t.float    "humidity"
  end

  create_table "look_at_mes", :force => true do |t|
    t.string   "serialNumber"
    t.datetime "commitDate"
    t.string   "commitID"
    t.boolean  "modified"
    t.datetime "created_at"
    t.boolean  "wdogReset"
    t.boolean  "brownoutReset"
    t.boolean  "extReset"
    t.boolean  "powerReset"
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
    t.integer  "artificial"
    t.datetime "created_at"
    t.integer  "networkID"
    t.float    "lighting"
    t.float    "power"
    t.integer  "powerFactor"
    t.integer  "complexity"
    t.integer  "lightFactor"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
  end

end
