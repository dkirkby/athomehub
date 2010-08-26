class LookAtMe < ActiveRecord::Base
  
  include Scoped

  # Returns the most recent LAM records defined at the specified utc time
  # which defaults to now.
  named_scope :latest, lambda { |*args|
    {
      :from => 'look_at_mes c1',
      :conditions => (args.first && Time.now - args.first > 1.second) ?
        [ 'c1.id = (select id from look_at_mes c2 where ' +
          'c2.serialNumber = c1.serialNumber and created_at <= ? ' +
          'ORDER BY id DESC LIMIT 1)',args.first.utc ] :
        ( 'c1.id = (select id from look_at_mes c2 where ' +
          'c2.serialNumber = c1.serialNumber ORDER BY id DESC LIMIT 1)' ),
      :readonly => true
    }
  }
  
  # Returns the most recent LAM record defined at the specified utc time,
  # which defaults to now, for the specified serial number.
  named_scope :for_serialNumber, lambda { |*args|
    {
      :conditions => (args.length > 1 && Time.now - args.last > 1.second) ?
        [ 'serialNumber = ? and created_at <= ?',args.first,args.last.utc ] :
        [ 'serialNumber = ?',args.first ],
      :readonly => true
    }
  }

  # A hub serial number starts with $FF
  def is_hub?
    return (serialNumber.hex & 0xff000000) == 0xff000000
  end
  
end
