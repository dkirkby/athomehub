namespace :binned do

  desc 'Deletes all existing binned sample data'
  task :delete => ["listener:not_running",:environment] do
    puts "Deleting #{BinnedSample.count} BinnedSample records"
    BinnedSample.delete_all
  end

  desc 'Deletes and rebuilds the binned sample data'
  task :rebuild => :delete do
    count = Sample.count
    batch_size = 1000
    batch_count = count/batch_size
    puts "Rebuilding from #{count} Sample records in batches of #{batch_size}..."
    batch_count.times do |batch_number|
      Sample.find(:all,:order=>'id ASC',
        :offset=>batch_number*batch_size,:limit=>batch_size).each do |s|
        BinnedSample.accumulate(s,false)
      end
      puts "Finished batch #{batch_number+1} of #{batch_count}"
    end
    puts "Created #{BinnedSample.count} BinnedSample records"
  end

  desc 'Profiles the accumulation of a small batch of sample data'
  task :profile => :delete do

    batch_size = 1000
    batch_number = 10

    require 'ruby-prof'
    result = RubyProf.profile do
      Sample.find(:all,:order=>'id ASC',
        :offset=>batch_number*batch_size,:limit=>batch_size).each do |s|
        BinnedSample.accumulate(s,false)
      end
    end
    # print an html call graph to a temporary file
    output = File.new('/tmp/profile.html','w')
    printer = RubyProf::GraphHtmlPrinter.new(result)
    printer.print output
    output.close
    # print a flat summary to stdout
    printer = RubyProf::FlatPrinter.new(result)
    printer.print STDOUT, :min_percent=>1
  end

end