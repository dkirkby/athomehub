require 'hub_listener'

namespace :listener do
  
  desc "Checks if a hub listener is already running"
  task :status do
    puts HubListener.instance.status
  end

  desc "Asserts that a hub listener is not running"
  task :not_running do
    HubListener.instance.not_running
  end
  
  desc "Starts a new background hub listener process"
  task :start => :environment do
    include Spawn
    HubListener.instance.start
  end

  desc "Starts the hub listener service as a foreground process"
  task :service => :environment do
    HubListener.instance.start :service=>true
  end

  desc "Starts a new interactive hub listener process for debugging"
  task :debug => :environment do
    HubListener.instance.start :debug=>true
  end

  desc "Starts a new interactive hub listener process for raw serial tracing"
  task :raw => :environment do
    HubListener.instance.start :raw=>true
  end

  desc "Stops a running hub listener process"
  task :stop do
    HubListener.instance.stop
  end

  desc "Restarts a running hub listener process"
  task :restart => [:stop,:start]

end