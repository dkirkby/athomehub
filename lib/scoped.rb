# A mix-in module for read-only database models with networkID and created_at fields

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
      
      named_scope :recent, lambda { |n|
        {
          :limit => n,
          :order => 'id DESC',
          :readonly => true
        }
      }
      
      named_scope :bydate, lambda { |begin_at,end_at|
        {
          :conditions => ['created_at > ? and created_at <= ?',begin_at,end_at],
          :readonly => true
        }
      }
      
    end
  end

end