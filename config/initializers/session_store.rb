# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_hub_session',
  :secret      => '8b0391dbafebd6b3f07b8c3f078f60c52ebdc5f19a6f3808388b8eb64b27f28748d623103381030f117d7a45541e2a762b05d77d372a8a981bf426cab1314f48'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
