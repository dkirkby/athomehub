module Engineering::LamHelper
  
  def format_serialNumber(lam)
    s = lam.serialNumber
    "#{s[0,2]}-#{s[2,2]}-#{s[4,2]}-#{s[6,2]}"
  end
  
  def link_to_commitID(lam)
    link_to lam.commitID,"http://github.com/dkirkby/athomehub/commit/#{lam.commitID}" 
  end
  
end
