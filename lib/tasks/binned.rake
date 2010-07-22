namespace :binned do

  desc 'Deletes all existing binned sample data'
  task :delete => ["listener:not_running",:environment] do
    puts "Deleting #{BinnedSample.count} BinnedSample records"
    BinnedSample.delete_all
  end

  desc 'Deletes and rebuilds the binned sample data'
  task :rebuild => :delete do
    puts "Rebuilding BinnedSample records from #{Sample.count} Sample records..."
    Sample.all.each {|s| BinnedSample.accumulate(s) }
    puts "Created #{BinnedSample.count} BinnedSample records"
  end

end