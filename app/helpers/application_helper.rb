# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def format_serialNumber(sn)
    "#{sn[0,2]}-#{sn[2,2]}-#{sn[4,2]}-#{sn[6,2]}"
  end

end
