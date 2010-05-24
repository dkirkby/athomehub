class Admin::NoteController < Admin::ApplicationController

  before_filter :valid_n,:only=>:recent
  before_filter :valid_ival,:only=>:bydate

  def recent
    @count = Note.count
    @notes = Note.find(:all,:limit=>@n,:order=>'id DESC',:readonly=>true)
  end

  def bydate
    @notes = Note.find(:all,
      :conditions=>['created_at > ? and created_at <= ?',@begin_at,@end_at],
      :order=>'created_at DESC',:readonly=>true)
  end

end
