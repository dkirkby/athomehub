class Admin::NoteController < Admin::ApplicationController

  def index
    @notes = Note.all
  end

end
