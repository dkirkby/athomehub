class AthomeController < ApplicationController

  before_filter :valid_at

  def index
    @samples = Sample.find(:all,:group=>'networkID',
      :conditions=>'networkID IS NOT NULL',:readonly=>true)
    @note = Note.new
    #@note.user = User.find(3)
  end
  
  def create_note
    render :text=>params.inspect
  end
  
  # Defines a replacement Sample class for demonstrating and testing
  class DemoSample
    def initialize(fields)
      @fields = fields
    end
    def temperature
      return @fields[:temperature]
    end
    def lighting
      return @fields[:lighting]
    end
    def artificial
      return @fields[:artificial]
    end
    def power
      return @fields[:power]
    end
    def cost
      return @fields[:cost]
    end
    def location
      return @fields[:location]
    end
  end

  # Returns fake data for demonstration and UI prototyping
  def demo
    # Declare some sample data
    @samples = [
      DemoSample.new({:location=>"Kitchen",
        :temperature=>7241,:lighting=>74,:artificial=>43,:power=>1328,:cost=>0.731}),
      DemoSample.new({:location=>"Family Room",
        :temperature=>7241,:lighting=>74,:artificial=>43,:power=>1328,:cost=>0.731}),
      DemoSample.new({:location=>"Dylan's Room",
        :temperature=>7241,:lighting=>74,:artificial=>43,:power=>1328,:cost=>0.731}),
      DemoSample.new({:location=>"Downstairs Bathroom",
        :temperature=>7241,:lighting=>74,:artificial=>43,:power=>1328,:cost=>0.731}),
      DemoSample.new({:location=>"Kids Bathroom",
        :temperature=>7241,:lighting=>74,:artificial=>43,:power=>1328,:cost=>0.731}),
      DemoSample.new({:location=>"Helen's Room",
        :temperature=>7241,:lighting=>74,:artificial=>43,:power=>1328,:cost=>0.731}),
      DemoSample.new({:location=>"Master Bedroom",
        :temperature=>7241,:lighting=>74,:artificial=>43,:power=>1328,:cost=>0.731}),
      DemoSample.new({:location=>"Master Bathroom",
        :temperature=>7241,:lighting=>74,:artificial=>43,:power=>1328,:cost=>0.731})
    ]
    @note = Note.new
    render :action=>"index"
  end
  
protected

  # Validates input params['at'] and sets @at. Value represents timestamp
  # of when an action is run. If provided on input, the action will replay
  # a historical view. Otherwise @at is set to a value that can be used
  # for later replay of a current view.
  def valid_at
    # defaults to now
    @at = Time.now.utc
    # has a value been provided?
    if params.has_key? 'at' then
      begin
        @at = Time.parse(params['at']).utc
      rescue ArgumentError
        flash.now[:notice] = "Invalid parameter at=\'#{params['end']}\'. Using now (#{@at}) instead."
      end
    end
  end

end
