namespace :binned do

  desc 'Deletes all existing binned sample data'
  task :delete => ["listener:not_running",:environment] do
    puts "Deleting #{BinnedSample.count} BinnedSample records"
    BinnedSample.delete_all
  end

  desc 'Deletes and rebuilds the binned sample data'
  task :rebuild => :delete do
    puts "Rebuilding BinnedSample records from #{Sample.count} Sample records..."
    Sample.all.each do |s|
      BinnedSample.accumulate s
      puts "Binned sample ID #{s.id}" if 0 == s.id.modulo(1000)
    end
    puts "Created #{BinnedSample.count} BinnedSample records"
  end

end