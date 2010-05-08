require 'rubygems'
require 'serialport'
require 'IRB'
require 'fcntl'

# Look for a hub serial device
port = (Dir.glob("/dev/tty.usbserial-*") | Dir.glob("/dev/ttyusb*")).first
if port == nil then
  print 'No hub serial device found\n'
else
  hub = SerialPort.new(port,115200)
  hub.read_timeout = -1 # don't wait for input
  print "\n\nConnected to #{port}...use ^C to disconnect\n\n"
  inputBuffer = ""
  stdin = IO::open($stdin.fileno)
  # This probably won't work, but we'll try anyway
  stdin.fcntl(Fcntl::O_NONBLOCK)
  begin
    while true do
      # Get any pending output from the hub
      hub.readlines.each do |line|
        print line
        if not inputBuffer.empty? then
          # repeat any partial line that got clobbered by the last print
          # (this will only work if STDIN is unbuffered, which it probably isn't)
          print ">>#{inputBuffer}"
        end
      end
      # Get any pending input from the terminal
      begin
        while gotInput = stdin.read_nonblock(1)
          inputBuffer += gotInput
          if gotInput == "\n" then
            print ">> Sending #{inputBuffer}"
            hub.write(inputBuffer)
            inputBuffer = ""
          end
        end
      rescue Errno::EAGAIN
        # nothing ready to read, try again later
      end
      sleep 0.1
    end
  rescue Interrupt,IRB::Abort
    print "\nBye.\n"    
  end
end