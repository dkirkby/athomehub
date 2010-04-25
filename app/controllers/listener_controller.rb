require 'serialport'
include Spawn

class ListenerController < ApplicationController
  
  def self.create(*args)
    super
    logger.info('ListenerController#create')
  end
  
  def status
    logger.info('Gathering status now...')
  end

  def start

    Rails.logger.info("Initializing the device listener...")

    # Get the list of known devices
    @devices = Device.find(:all)

    # Look for a hub serial device
    port = (Dir.glob("/dev/tty.usbserial-*") | Dir.glob("/dev/ttyusb*")).first
    if port == nil then
      Rails.logger.warn("No hub serial device found")
    else
      # Start the listener in a forked subprocess
      listener = spawn({:nice=>1,:method=>:fork}) do
        # Prepare a regexp parser
        parser = Regexp.compile('^([0-9A-F]+) \[([0-9A-F]+)\] ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)(?: \*([0-9A-F]+))?$')
        # Open a serial connection to the hub device
        hub = SerialPort.new(port,115200)
        hub.read_timeout = -1 # don't wait for input
        while true do
          hub.readlines.each do |packet|
            parseOK,deviceID,sequenceNumber,word0,word1,word2,word3,status = *(parser.match(packet.strip()))
            if parseOK == nil then
              print "Parse error: #{packet}"
            else
              print packet
              #print "Received #{word0} #{word1} #{word2} #{word3} from #{deviceID}\n"
            end
          end
          sleep 0.25
        end
      end
      Rails.logger.info("Device listener running as PID #{listener.handle} on #{port}")
    end
  end

end
