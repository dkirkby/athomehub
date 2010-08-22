# A mix-in module for read-only database models with networkID and created_at fields

module Scoped
  
  def self.included(base)
    # define some named scopes in the appropriate class context when we are included
    base.class_eval do

      # Returns records with the specified networkID, optionally qualified by a
      # maximum created_at timestamp value. No ordering is specified for the query
      # results.
      named_scope :for_networkID, lambda { |*args|
        {
          :conditions => (args.length > 1 && Time.now - args.last > 1.second) ?
            [ 'networkID = ? and created_at <= ?',args.first,args.last.utc ] :
            [ 'networkID = ?',args.first ],
          :readonly => true
        }
      }
      
      # Returns the n most recent records in reverse creation order.
      named_scope :recent, lambda { |n|
        {
          :limit => n,
          :order => 'id DESC',
          :readonly => true
        }
      }
      
      # Returns all records created within the specified timestamp interval in
      # reverse creation order.
      named_scope :bydate, lambda { |begin_at,end_at|
        {
          :conditions => ['created_at > ? and created_at <= ?',begin_at,end_at],
          :order => 'id DESC',
          :readonly => true
        }
      }
      
    end
  end

end