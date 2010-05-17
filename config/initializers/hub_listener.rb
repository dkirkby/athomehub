require 'serialport'
include Spawn

# Logging in this initializer goes to log/development.log
Rails.logger.info "Initializing the device listener..."

# Look for a hub serial device
port = (Dir.glob("/dev/tty.usbserial-*") | Dir.glob("/dev/ttyusb*")).first
if port == nil then
  Rails.logger.warn "No hub serial device found"
else
  # Start the listener in a forked subprocess
  listener = spawn({:nice=>1,:method=>:fork}) do
    # Prepare a regexp parser
    parser = Regexp.compile('^([0-9A-F]+) \[([0-9A-F]+)\] ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)(?: \*([0-9A-F]+))?$')
    # Open a serial connection to the hub device (which causes it to restart)
    hub = SerialPort.new(port,115200)
    hub.read_timeout = -1 # don't wait for input
    partialPacket = ""
    starting = true
    while true do
      hub.readlines.each do |packet|
        # add any earlier partial packet
        packet = partialPacket + packet
        # need to make sure we have a complete packet here (a line might be split)
        if packet[-1..-1] != "\n" then
          partialPacket = packet
          next
        else
          packet.rstrip!
          partialPacket = ""
        end
        # Parse a complete packet by splitting it into white-spaced separated
        # tokens. The first token is the command and the rest are values.
        cmd,*values = packet.split
        puts "#{cmd} => #{values.join(',')}"
        if cmd != 'HUB' and starting then
          # ignore anything in the serial buffer before the hub is restarted
          next
        end
        starting = false
        # HUB and LAM packets have the same format
        if cmd == 'HUB' or cmd == 'LAM' then
          # parse and validate the fields
          serialNumber = values[0].hex
          commitTimestamp = values[1].to_i
          commitID = values[2]
          modified = values[3]
          puts serialNumber,commitTimestamp,commitID,modified
        end
      end
      sleep 0.25
    end
  end
  Rails.logger.info "Device listener running as PID #{listener.handle} on #{port}"
end