module Engineering::LamHelper
  
  def link_to_commitID(lam)
    link_to lam.commitID,"http://github.com/dkirkby/athomeleaf/commit/#{lam.commitID}" 
  end
  
end
