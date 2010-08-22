class Note < ActiveRecord::Base

  include Scoped
  
  belongs_to :user
  
end
