class DeviceProfile < ActiveRecord::Base

  # Returns the most recent profile records defined at the specified utc time
  # which defaults to now.
  named_scope :latest, lambda { |*args|
    {
      :from => 'device_profiles c1',
      :order => 'c1.display_order ASC',
      :conditions => args.first ?
        [ 'c1.id = (select max(id) from device_profiles c2 where ' +
          'c2.networkID = c1.networkID and created_at <= ?)',args.first ] :
        ( 'c1.id = (select max(id) from device_profiles c2 where ' +
          'c2.networkID = c1.networkID)' ),
      :readonly => true
    }
  }

  # Returns the profiles for the specified networkID at the specified utc
  # time which defaults to now. Usage is similar to DeviceConfig.for_networkID.
  named_scope :for_networkID, lambda { |*args|
    {
      :order => 'c1.display_order ASC',
      :conditions => (args.length > 1) ?
        [ 'networkID = ? and created_at <= ?',args.first,args.last ] :
        [ 'networkID = ?',args.first ],
      :readonly => true
    }
  }

end
