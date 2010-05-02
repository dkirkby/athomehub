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
        parser = Regexp.compile('^([0-9A-F]+) \[([0-9A-F]+)\] ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)(?: \*([0-9A-F]+))?$')
        # Open a serial connection to the hub device
        hub = SerialPort.new(port,115200)
        hub.read_timeout = -1 # don't wait for input
        partialPacket = ""
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
            parseOK,deviceID,sequenceNumber,word0,word1,word2,word3,word4,status = *(parser.match(packet))
            if parseOK == nil then
              print "Parse error: #{packet}\n"
            else
              # perform string conversions
              deviceID,sequenceNumber = deviceID.hex,sequenceNumber.hex
              payload = [word0,word1,word2,word3,word4].map { |x| x.to_i }
              if deviceID > 0x8000 then
                print "#{payload[0]} #{payload[1]}\n#{payload[2]} #{payload[3]} #{payload[4]}\n"
              else
                print "#{packet}\n"
                # this is where we write the new sample into the database
                Sample.create(
                  :seqno => sequenceNumber,
                  :lighting => payload[0],
                  :artificial => payload[1],
                  :lighting2 => payload[2],
                  :artificial2 => payload[3],
                  :temperature => payload[4]
                )
              end
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
