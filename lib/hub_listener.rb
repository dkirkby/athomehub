require 'singleton'

class HubListener
  
  include Singleton
  
  def initialize
    # look for a file containing the PID of the running listener process
    @pidFile = "/tmp/hub_listener.pid"
    @pid = File.open(@pidFile,"r").readline.to_i if File.exists? @pidFile
    if @pid then
      # is the listener still running?
      begin
        Process.getpriority(Process::PRIO_PROCESS,@pid)
      rescue
        cleanup
      end
    end
  end
  
  def status
    if @pid then
      "hub listener running as PID #{@pid}"
    else
      "no hub listener is running"
    end
  end
  
  def start
    raise "hub listener already running as PID #{@pid}" if @pid
  end

  def stop
    raise "no hub listener process is running" unless @pid
    Process.kill("INT",@pid)
    cleanup
  end
  
  private
  
  def cleanup
    File.delete(@pidFile) if File.exists? @pidFile
    @pid = nil
  end

end