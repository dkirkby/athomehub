namespace :binned do

  desc 'Deletes all existing binned sample data'
  task :delete => ["listener:not_running",:environment] do
    puts "Deleting #{BinnedSample.count} BinnedSample records"
    BinnedSample.delete_all
  end

  desc 'Deletes and rebuilds the binned sample data'
  task :rebuild, [:weeks_ago] => :environment do |t,args|
    raise 'usage is binned:rebuild[w] where w=number of weeks ago to rebuild' unless
      args[:weeks_ago] and args[:weeks_ago].to_i >= 0
    Accumulator.rebuild(args[:weeks_ago].to_i.weeks.ago)
    Accumulator.validate(args[:weeks_ago].to_i.weeks.ago)
  end

  desc 'Profiles the accumulation of a small batch of sample data'
  task :profile => :environment do
    require 'ruby-prof'
    result = RubyProf.profile { Accumulator.rebuild(1.week.ago) }
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