class DeviceProfile < ActiveRecord::Base

  # Returns the most recent profile records defined at the specified utc time
  # which defaults to now.
  named_scope :latest, lambda { |*args|
    {
      :from => 'device_profiles c1',
      :order => 'c1.display_order ASC',
      :conditions => args.first ?
        [ 'c1.id = (select id from device_profiles c2 where ' +
          'c2.networkID = c1.networkID and created_at <= ? ' +
          'ORDER BY id DESC LIMIT 1)',args.first ] :
        ( 'c1.id = (select id from device_profiles c2 where ' +
          'c2.networkID = c1.networkID ORDER BY id DESC LIMIT 1)' ),
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

  validates_numericality_of :networkID, :only_integer=>true,
    :greater_than_or_equal_to=>0, :less_than=>256
  validates_numericality_of :display_order, :only_integer=>true
  validates_presence_of :description
  
  validate_on_create :active_profiles_are_unique
  
  def active_profiles_are_unique
    # trim any whitespace from the proposed description
    description.strip!
    # lookup the most recent profile for each network ID
    DeviceProfile.latest.each do |profile|
      # skip any existing profile for the network ID we are updating since
      # we will be overwriting it
      next if profile.networkID == networkID
      # check for a duplicate description
      errors.add_to_base("Profile #{profile.networkID} is already using " +
        "the same description") if profile.description == description
    end
  end

end
