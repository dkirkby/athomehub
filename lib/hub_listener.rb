require 'singleton'
require 'serialport'
require 'Spawn'

class HubListener
  
  include Singleton
  
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
  
  # Starts a new hub listener in a forked subprocess.
  def start
    raise "hub listener already running as PID #{@pid}" if @pid
    raise "no hub serial port found" unless self.port
    self.listen { |msg| self.handle(msg) }
  end

  # Stops a running hub listener, which may have been started in another
  # ruby instance.
  def stop
    raise "no hub listener process is running" unless @pid
    Process.kill("INT",@pid)
    self.cleanup
  end
  
  protected
  
  # Cleans up any old PID file and removes any record of a running process
  def cleanup
    File.delete(@pidFile) if File.exists? @pidFile
    @pid = nil
  end

  # Returns the name of the serial port device that we think a hub is connected to.
  def port
    (Dir.glob("/dev/tty.usbserial-*") | Dir.glob("/dev/ttyusb*")).first
  end

  # Handles a complete message received from the hub.
  def handle(msg)
    puts "Got >>#{msg}<<"
    cmd,*values = msg.split
    puts "#{cmd} => #{values.join(',')}"
    if cmd != 'HUB' and starting then
      # ignore anything in the serial buffer before the hub is restarted
      next
    end
    starting = false
    # HUB and LAM messages have the same format
    if cmd == 'HUB' or cmd == 'LAM' then
      # parse and validate the fields
      serialNumber = values[0].hex
      commitTimestamp = Time.at(values[1].to_i)
      commitID = values[2]
      if commitID.length != 40 then
        Rails.logger.warn "Unexpected commit ID length in '#{commitID}'"
      end
      if values[3] == '0' then
        modified = false
      else
        if values[3] != '1' then
          Rails.logger.warn "Unexpected LAM modified field '#{values[3]}'"
        end
        modified = true
      end
      puts sprintf("%08x",serialNumber),commitTimestamp,commitID,modified
    end
  end
  
  # Connects to a hub serial port and enters an infinite message handling loop,
  # yielding each complete message to the code block provided.
  def listen
    # Open a serial connection to the hub device
    hub = SerialPort.new(self.port,115200)
    hub.read_timeout = -1 # don't wait for input
    partialMessage = ""
    while true do
      hub.readlines.each do |message|
        # add any earlier partial message
        message = partialMessage + message
        # need to make sure we have a complete message since readlines will sometimes
        # split a line at a buffering boundary
        if message[-1..-1] != "\n" then
          partialMessage = message
          next
        else
          message.rstrip!
          partialMessage = ""
          yield message
        end
      end
      sleep 0.2
    end
  end

end