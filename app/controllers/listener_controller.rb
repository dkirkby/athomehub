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
      # Start the listener in a spawned subprocess
      listener = spawn(:nice=>1,:method=>fork) do
        # Open a serial connection to the hub device
        hub = SerialPort.new(port,115200)
        hub.read_timeout = -1 # don't wait for input
        while true do
          hub.readlines.each do |packet|
            print packet
          end
          sleep 0.25
        end
      end
      Rails.logger.info("Device listener running as PID #{listener.handle} on #{port}")
    end
  end

end
