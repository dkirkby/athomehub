namespace :listener do
  
  desc "Checks if a hub listener is already running"
  task :status do
    puts "Checking the hub listener status..."
  end
  
  desc "Starts a new hub listener process"
  task :start => :environment do
    puts "Starting the hub listener..."
  end

  desc "Stops a running hub listener process"
  task :stop do
    puts "Stopping the hub listener..."
  end

  desc "Restarts a running hub listener process"
  task :restart => [:stop,:start]

end