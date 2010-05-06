require 'rubygems'
require 'serialport'

# Look for a hub serial device
port = (Dir.glob("/dev/tty.usbserial-*") | Dir.glob("/dev/ttyusb*")).first
if port == nil then
  print 'No hub serial device found\n'
else
  hub = SerialPort.new(port,115200)
  hub.read_timeout = -1 # don't wait for input
  print "\n\nConnected to #{port}...use ^C to disconnect\n\n"
  begin
    while true do
      hub.readlines.each do |line|
        print line
      end
      sleep 0.1
    end
  rescue Interrupt,IRB::Abort
    print "\nBye.\n"    
  end
end