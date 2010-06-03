module Engineering::DumpHelper
  
  def source_label(dump)
    return 'UNKNOWN' unless (0..4).include? dump.source
    ['PowerLO','PowerHI','LightLO','LightHI','ACPhase'][dump.source]
  end
  
end
