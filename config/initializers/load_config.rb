# Loads the application wide configuration into the ATHOME global

ATHOME = YAML.load_file("#{RAILS_ROOT}/config/athome_defaults.yml")[RAILS_ENV]

# Apply local modifications if any are provided
local = "#{RAILS_ROOT}/config/athome_local.yml"
ATHOME.merge! YAML.load_file(local) if FileTest.exists? local
