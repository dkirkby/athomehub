class LookAtMe < ActiveRecord::Base
  
  include Scoped

  # Returns the most recent LAM record defined at the specified utc time,
  # which defaults to now, for the specified serial number.
  named_scope :for_serialNumber, lambda { |*args|
    {
      :conditions => (args.length > 1 && args.last && Time.now - args.last > 1.second) ?
        [ 'serialNumber = ? and created_at <= ?',args.first,args.last.utc ] :
        [ 'serialNumber = ?',args.first ],
      :readonly => true
    }
  }

  # Returns the most recent LAM records defined at the specified utc time
  # which defaults to now.
  def self.find_latest(at=nil)
    latest = [ ]
    LookAtMe.find(:all,:select=>:serialNumber,:group=>:serialNumber).each do |sn|
      lam = LookAtMe.for_serialNumber(sn.serialNumber,at).last
      latest << lam if lam
    end
    latest
  end

  # A hub serial number starts with $FF
  def is_hub?
    return (serialNumber.hex & 0xff000000) == 0xff000000
  end
  
end
