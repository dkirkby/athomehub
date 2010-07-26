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

  def show
    # retrieve the requested note (should handle an invalid id here...)
    @note = Note.find(params[:id])
    # split off any options already attached to @note.view
    uri = URI.parse @note.view
    action = uri.path
    url_params = Rack::Utils.parse_query uri.query
    # re-display the original view with the note below
    redirect_to url_params.merge({
      :controller=>'/athome', :action=>action,
      :at=>@note.view_at.to_param, :note_id=>params[:id]
    })
  end

end
