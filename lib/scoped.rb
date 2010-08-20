# A mix-in module for database models with networkID and created_at fields

module Scoped
  
  def self.included(base)
    # define some named scopes in the appropriate class context when we are included
    base.class_eval do
      named_scope :for_networkID, lambda { |*args|
        {
          :conditions => (args.length > 1 && Time.now - args.last > 1.second) ?
            [ 'networkID = ? and created_at <= ?',args.first,args.last.utc ] :
            [ 'networkID = ?',args.first ],
          :order => 'id ASC',
          :readonly => true
        }
      }
    end
  end

end