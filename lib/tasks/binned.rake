namespace :binned do

  desc 'Deletes all existing binned sample data'
  task :delete => :environment do
    puts "Deleting #{BinnedSample.count} records"
    BinnedSample.delete_all
  end

end