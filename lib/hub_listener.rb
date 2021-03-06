require 'singleton'

class HubListener
  
  include Singleton
  
  @@periodicInterval = 30.seconds
  
  # Looks for a running listener process and sets the @pid global if one
  # is found.
  def initialize
    # look for a file containing the PID of the running listener process
    @pidFile = "/tmp/hub_listener.pid"
    @pid = File.open(@pidFile,"r").readline.to_i if File.exists? @pidFile
    if @pid then
      # is the listener still running?
      begin
        Process.getpriority(Process::PRIO_PROCESS,@pid)
      rescue
        self.cleanup
      end
    end
  end
  
  # Returns a status string that reports wether a listener is running and
  # what serial port a hub is connected to.
  def status
    # do we have a hub connected to a serial port?
    if self.port then
      port_status = " (using serial port #{self.port})"
    else
      port_status = " (no hub serial port found)"
    end
    # is there a listener process running?
    if @pid then
      "hub listener running as PID #{@pid}" + port_status
    else
      "no hub listener is running" + port_status
    end
  end
  
  # Fails if a listener is currently running
  def not_running
    raise "hub listener running as PID #{@pid}" if @pid
  end
  
  # Starts a new hub listener.
  def start(options={})
    raise "hub listener already running as PID #{@pid}" if @pid
    raise "no hub serial port found" unless self.port
    @starting = true
    if options[:debug] then
      # run interactively with logging to stdout
      @logger = Logger.new(STDOUT)
      @logger.info "Running interactively. Use ^C to stop."
      self.listen { |msg| self.handle msg }
    elsif options[:service] then
      # run in the foreground with filtered logging to stdout
      # this mode is appropriate for use as an upstart service
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::ERROR
      puts "Listener service started (will stop on SIGINT)"
      self.listen { |msg| self.handle msg }
    elsif options[:raw] then
      # run interactively and simply print all serial traffic to stdout
      @@periodicInterval = nil
      @logger = Logger.new(STDOUT)
      @logger.info "Tracing raw serial messages. Use ^C to stop."
      self.listen { |msg| puts msg }
    else
      # run in a background process with logging to Rails.logger
      listener = spawn({:nice=>1, :method=> :fork}) do
        @logger = Rails.logger
        self.listen { |msg| self.handle(msg) }
      end
      # record the listener process' PID
      @pid = listener.handle
      puts "hub listener starting as PID #{@pid}..."
      begin
        file = File.new(@pidFile,"w")
        file.syswrite(@pid)
        file.close
      rescue
        puts "error while saving hub listener PID to #{@pidFile}"
      end
      # wait a few seconds for the hub to (re)start and send its LAM info
      delay = 10
      sleep delay
      # check that we can find the hub's new LAM info in the db
      recent = LookAtMe.find(:all,:conditions=>["created_at > ?",(delay+5).seconds.ago])
      foundHub = false
      recent.each do |lam|
        if lam.is_hub? then
          msg = "hub s/n #{lam.serialNumber}: commit #{lam.commitID} at #{lam.commitDate}"
          msg += " (modified)" if lam.modified
          puts msg
          foundHub = true
        end
      end
      if foundHub then
        # detach the listener process so its does not become a zombie
        Process.detach @pid
      else
        puts "hub did not register at startup...stopping"
        self.stop
      end
    end
  end

  # Stops a running hub listener, which may have been started in another
  # ruby instance.
  def stop
    raise "no hub listener process is running" unless @pid
    Process.kill("INT",@pid)
    puts "stopped hub listener PID #{@pid}"
    self.cleanup
  end
  
protected
  
  @@hexPattern = Regexp.compile("^[0-9a-fA-F]+$")
  
  # Cleans up any old PID file and removes any record of a running process
  def cleanup
    File.delete(@pidFile) if File.exists? @pidFile
    @pid = nil
  end

  # Returns the name of the serial port device that we think a hub is connected to.
  def port
    (Dir.glob("/dev/tty.usbserial-*") | Dir.glob("/dev/ttyUSB*")).first
  end

  # Sends a device its configuration data
  def sendConfig(config)
    @logger.info "Sending config ID #{config.id} created at #{config.created_at.localtime} for SN #{config.serialNumber}"
    # update this config, if necessary to reflect visual energy feedback prefs
    updated = config.update_energy_feedback
    @logger.info "Modified config based on energy feedback prefs to " +
      "green=#{config.greenGlow}, red=#{config.redGlow}" if updated
    # prepare the serial command to send to the hub
    config_msg = config.serialize_for_device
    @logger.info "Using config command #{config_msg.rstrip}"
    # The following write sometimes gets corrupted but I don't know why.
    # The Arduino serial input buffer is supposed to be 128 bytes, which
    # should be plenty. Also, breaking the message into 8-byte chunks
    # separated by "sleep 0.1" does not seem to help.
    @hub.write config_msg
    # remember that this device has been sent this configuration
    @configs_pending[config.networkID] = config
  end

  # Registers that a device configuration has been received
  def registerConfig(networkID)
    # were we expecting this?
    @logger.error(
      "No pending config to register for network ID #{networkID}") unless
      @configs_pending.has_key? networkID
    # lookup the config this device was pending on
    config = @configs_pending[networkID]
    # update the config associated with each serial number
    @configs[config.serialNumber] = config
    # remember that this networkID is configured
    @configured[config.networkID] = config
    # update our config high water mark if it was set by this pending config
    @config_min_id += 1 if @config_min_id == config.id
    # we are no longer pending on this device
    @configs_pending.delete networkID
  end

  # Handles a Look-at-Me message
  def handleLAM(values)
    lam = LookAtMe.new
    # parse and validate the fields
    lam.serialNumber = sprintf "%08X",values[0].hex
    lam.commitDate = Time.at(values[1].to_i)
    lam.commitID = values[2]
    if lam.commitID.length != 40 then
      @logger.warn(
        "Unexpected commit ID length #{lam.commitID.length} in '#{lam.commitID}'")
    end
    # parse the LAM status bits
    status = values[3].to_i
    lam.powerReset = (0 != status & (1<<0))
    lam.extReset = (0 != status & (1<<1))
    lam.brownoutReset = (0 != status & (1<<2))
    lam.wdogReset = (0 != status & (1<<3))
    lam.modified = (0 != status & (1<<4))
    # save this message in the db
    lam.save
    # should we respond with a config message?
    if not lam.is_hub? and lam.serialNumber != '00000000' then
      # find the most recent config for this serial number
      config = DeviceConfig.for_serialNumber(lam.serialNumber).last
      if not config then
        @logger.warn "No config found for SN #{lam.serialNumber}"
      elsif not config.enabled then
        @logger.warn "Not sending config to disabled SN #{lam.serialNumber}"
      else
        sendConfig config
      end
    end
  end

  # Handles a hub sensor reading message
  def handleHubSensorReadings(values)
    if values.length != 2 then
      log = DeviceLog.create({:code=>-13,:value=>values.length})
      @logger.error log.message
      return
    end
    # try to parse the two values as floats
    begin
      sample = HubSample.new
      sample.temperature = Float(values[0])
      sample.humidity = Float(values[1])
      sample.save
    rescue ArgumentError
      log = DeviceLog.create({:code=>-14})
      @logger.error log.message
    end
  end

  # Handles a Data message
  def handleData(values)
    # do we have the expected number of values?
    if values.length != 10 then
      log = DeviceLog.create({:code=>-1,:value=>values.length})
      @logger.error log.message
      return
    end
    # parse the message
    index = 0
    networkID,seqno,status,*sampleData = values.map do |v|
      if !(v =~ @@hexPattern) then
        log = DeviceLog.create({:code=>-7,:value=>index})
        @logger.error log.message
      end
      index += 1
      v.hex
    end
    # the power and lighting values are IEEE floats: unpack them now
    binary = [sampleData[0],sampleData[3]].pack("LL")
    lighting,power = binary.unpack("ee")
    # is this a valid network ID?
    if networkID > 255 then
      log = DeviceLog.create({:code=>-16,:value=>networkID})
      @logger.warn log.message
      return
    end
    # did we drop any packets since the last one seen?
    if @sequences[networkID] then
      dropped = (seqno-@sequences[networkID])%256 - 1
      if dropped > 0 then
        log = DeviceLog.create({:code=>-2,:value=>dropped,:networkID=>networkID})
        @logger.warn log.message
      end
    end
    @sequences[networkID] = seqno
    # did we have to retransmit the last data message?
    retransmits = (status & 0x0f)
    if retransmits > 0 then
      log = DeviceLog.create({:code=>-3,:value=>retransmits,:networkID=>networkID})
      @logger.warn log.message
    end
    # did the device receive config data?
    if (status & 0x10) != 0 then
      # initial config
      log = DeviceLog.create({:code=>-4,:networkID=>networkID})
      @logger.info log.message
      registerConfig networkID
    end
    if (status & 0x20) != 0 then
      # updated config
      log = DeviceLog.create({:code=>-5,:networkID=>networkID})
      @logger.info log.message
      registerConfig networkID
    end
    if (status & 0x40) != 0 then
      # invalid config
      log = DeviceLog.create({:code=>-6,:networkID=>networkID})
      @logger.warn log.message
    end
    # have we ever configured this device?
    if not @configured.has_key? networkID then
      log = DeviceLog.create({:code=>-15,:value=>networkID,:networkID=>networkID})
      @logger.warn log.message
      # find the most recent config for this network ID
      config = DeviceConfig.for_networkID(networkID).last
      if not config then
        log = DeviceLog.create({:code=>-17,:value=>networkID,:networkID=>networkID})
        @logger.error log.message
        return
      elsif not config.enabled then
        log = DeviceLog.create({:code=>-18,:value=>networkID,:networkID=>networkID})
        @logger.error log.message
        return
      else
        sendConfig config
      end
    end
    # Finally, write the sample values we received, translating
    # float infinity to database NULL.
    s = Sample.create({
      :networkID=>networkID,
      :lighting=>(lighting.infinite? ? nil : lighting),
      :artificial=>sampleData[1],
      :lightFactor=>sampleData[2],
      :power=>(power.infinite? ? nil : power),
      :powerFactor=>sampleData[4],
      :complexity=>sampleData[5],
      :temperature=>sampleData[6]
    })
    # Accumulate this sample in our BinnedSample accumulators
    Accumulator.accumulate s
  end

  # Handles a buffer dump message.
  def handleDump(values)
    # check that we have at least an initial header
    if values.length < 2 then
      log = DeviceLog.create({:code=>-21,:value=>values.length})
      @logger.warn log.message
      return
    end
    # check that all fields are pure hex
    index = 0
    values.each do |v|
      if !(v =~ @@hexPattern) then
        log = DeviceLog.create({:code=>-8,:value=>index})
        @logger.error log.message
        return
      end
      index += 1
    end
    # extract the packet header
    networkID,sequenceNumber = values[0].hex,values[1].hex
    # should we start assembling a new dump?
    if sequenceNumber == 0 then
      # give up on a previous partially assembled dump?
      if @dumps[networkID] then
        log = DeviceLog.create({:code=>-9,:networkID=>networkID})
        @logger.error log.message
        @dumps[networkID].save
      end
      # check for the expected length
      if values.length != 15 then
        log = DeviceLog.create({:code=>-21,:networkID=>networkID,:value=>values.length})
        @logger.warn log.message
        return
      end      
      # create a new dump for this device
      source = values[3].hex
      log = DeviceLog.create({:code=>-10,:networkID=>networkID,:value=>source})
      @logger.info log.message
      @dumps[networkID] = BufferDump.new({
        :networkID=>networkID,
        :header=>values[2],
        :source=>source,
        :micros=>values[4].hex
      })
      # add the first 8 samples
      @dumps[networkID].init_samples 250,values[5..14]
    elsif sequenceNumber <= 10 then
      # check for the expected length
      if values.length != 26 then
        log = DeviceLog.create({:code=>-21,:networkID=>networkID,:value=>values.length})
        @logger.warn log.message
        return
      end      
      # has this dump already been started?
      if not @dumps[networkID] then
        log = DeviceLog.create({:code=>-12,:networkID=>networkID,
          :value=>sequenceNumber})
        @logger.info warn log.message
        # create a new dump with unknown source
        @dumps[networkID] = BufferDump.new
      end
      # add the next 24 samples
      @dumps[networkID].add_samples 10+24*(sequenceNumber-1),values[2..25]
      # save this dump now?
      if sequenceNumber == 10 then
        # find the most recent config for this network ID
        config = DeviceConfig.for_networkID(networkID).last
        if not config then
          log = DeviceLog.create({:code=>-19,:value=>networkID,:networkID=>networkID})
          @logger.error log.message
        elsif not config.enabled then
          log = DeviceLog.create({:code=>-20,:value=>networkID,:networkID=>networkID})
          @logger.error log.message
        else
          # config looks ok, go ahead and save now
          @dumps[networkID].save
        end
        # closeout this dump reconstruction
        @dumps.delete networkID
      end
    else
      # we should never see a sequence number > 11
      log = DeviceLog.create({:code=>-11,:networkID=>networkID,
          :value=>sequenceNumber})
      @logger.error log.message
    end
  end

  # Handles a log message
  def handleLog(values)
    log = DeviceLog.create({:code=>values[0],:value=>values[1]})
    level = log.severity_symbol or :error
    @logger.send(level,log.message)
  end

  # Handles a complete message received from the hub. Logging is via @logger.
  def handle(msg)
    begin
      # Split the message into whitespace-separated tokens. The first token
      # identifies the message type.
      msgType,*values = msg.split
      # ignore anything in the serial buffer before the hub is restarted
      return if msgType != 'HUB' and @starting
      @starting = false
      # HUB and LAM messages have the same format
      if msgType == 'HUB' or msgType == 'LAM' then
        handleLAM values
      elsif msgType == 'DATA' then
        handleData values
      elsif msgType == 'DUMP' then
        handleDump values
      elsif msgType == 'LOG' then
        handleLog values
      elsif msgType == 'SENS' then
        handleHubSensorReadings values
      else
        @logger.error "Skipping unexpected hub message \"#{msg}\""
      end
    rescue => e
      # log the exception and keep going
      @logger.error 'Exception caught in listener::handler (will try to keep going)'
      @logger.error e.inspect
      @logger.error e.backtrace.join("\n    ")
    end
  end
  
  # Performs periodic housekeeping
  def periodicHandler
    now = Time.now
    @logger.debug "periodicHandler: config.id >= #{@config_min_id} and "+
      "#{@configs_pending.length} config(s) pending at #{now}"
    # look for any new device configurations
    new_configs = DeviceConfig.find(:all,:readonly=>true,:order=>'id ASC',
      :conditions=>['id >= ?',@config_min_id])
    # keep track of the most recent config update for each serial number, just
    # in case there have been multiple updates since the last time this
    # handler ran
    to_send = { }
    id_min = nil
    new_configs.each do |c|
      # remember the smallest id we see
      id_min = c.id if not id_min or c.id < id_min
      # are we already talking to the device whose config this is?
      if @configs.has_key? c.serialNumber then
        # is this config newer than what we have already sent?
        if @configs[c.serialNumber].id && c.id <= @configs[c.serialNumber].id then
          # don't resend it
          @config_min_id += 1 if c.id == @config_min_id
        elsif not c.enabled then
          @logger.info "Disabling SN #{c.serialNumber} for config ID #{c.id}"
          @configs.delete c.serialNumber
          @configured.delete c.networkID
          @configs_pending.delete c.networkID
          @config_min_id += 1 if c.id == @config_min_id
        else
          @logger.info "Found an updated config ID #{c.id} for SN #{c.serialNumber}"
          to_send[c.serialNumber] = c
        end
      else
        # ignore updates for devices that we are not already talking to
        @config_min_id += 1 if c.id == @config_min_id
      end
    end
    # our min ID should be at least the smallest ID seen
    @config_min_id = id_min if id_min and id_min > @config_min_id
    # check if we need to update the config of any already-configured device
    # because of a change in its 24-hour energy usage
    @configured.each do |netID,c|
      ##@logger.info "NetworkID #{netID} visual energy feedback: " +
      ##  "green=#{c.greenGlow}, red=#{c.redGlow}"
      next if to_send.has_key? netID
      # test if this config needs updating (without actually updating it)
      next unless c.update_energy_feedback(false)
      # queue up a new config with the energy feedback updates
      new_config = c.clone
      new_config.id = c.id # copy the id to allow the check for a newer config above
      new_config.update_energy_feedback(true)
      @logger.info "Updating visual energy feedback for network ID #{netID} to " +
        "green=#{new_config.greenGlow}, red=#{new_config.redGlow}"
      to_send[c.serialNumber] = new_config
    end
    # send the config updates now
    to_send.each do |sn,c|
      sendConfig c
    end
    return now + @@periodicInterval
  end
  
  # Connects to a hub serial port and enters an infinite message handling loop,
  # yielding each complete message to the code block provided. Send an Interrupt
  # signal to request a clean shutdown. Logging message go to Rails.logger.
  def listen
    # Open a serial connection to the hub device
    require 'serialport'
    @hub = SerialPort.new(self.port,115200)
    # don't wait for input
    @hub.read_timeout = -1
    # force a reboot by pulling DTR low momentarily
    @hub.dtr= 0
    sleep 0.1
    @hub.dtr= 1
    # The message handler will track the sequence numbers from each device
    # in this hash
    @sequences = { }
    # The message handler will assemble buffer dumps in this hash
    @dumps = { }
    # We will reconstruct message fragments in this string buffer
    partialMessage = ""
    # Track the configuration status of devices...
    # @configs is indexed by serial number and used by the periodic handler
    # to ensure that we only push updates for devices we are talking to.
    @configs = { }
    # @configured is indexed by networkID and allows us to automatically
    # push the latest config to a device that is already sending samples
    # when the listener starts up.
    @configured = { }
    # @configs_pending is indexed by networkID and tracks configurations that
    # have been sent at least once but not yet updated in the appropriate device.
    @configs_pending = { }
    # @configs_max_id keeps track of which new configs we have already
    # acted upon in the periodic handler's push logic.
    @config_min_id = 0
    # Initialize our periodic housekeeping
    nextIntervalExpiresAt = periodicHandler if @@periodicInterval
    begin
      while true do
        @hub.readlines.each do |message|
          # add any earlier partial message
          message = partialMessage + message
          # need to make sure we have a complete message since
          # readlines will sometimes split a line at a buffering boundary
          if message[-1..-1] != "\n" then
            partialMessage = message
            next
          else
            message.rstrip! if message
            partialMessage = ""
            yield message
          end
        end
        if @@periodicInterval and nextIntervalExpiresAt < Time.now then
          nextIntervalExpiresAt = periodicHandler
        else
          sleep 0.2
        end
      end
    rescue Interrupt
      @logger.info 'Hub listener exiting'
    rescue => e
      @logger.error e.inspect
      @logger.error e.backtrace.join("\n    ")
      # retry
    end
  end

end