require 'hub_listener'

namespace :listener do
  
  desc "Checks if a hub listener is already running"
  task :status do
    puts HubListener.instance.status
  end
  
  desc "Starts a new hub listener process"
  task :start => :environment do
    HubListener.instance.start
  end

  desc "Stops a running hub listener process"
  task :stop do
    HubListener.instance.stop
  end

  desc "Restarts a running hub listener process"
  task :restart => [:stop,:start]

end