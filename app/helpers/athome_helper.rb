module AthomeHelper
  
  # Inserts a link that, when clicked, creates a new note by the specified
  # user via an ajax call, and resets the note_body textarea contents.
  def note_for_user_link(link_text,user)
    link_to_remote link_text,
      :url=>{:action=>"create_note",:user_id=>user.id},
      :submit=>"note",
      :complete=>"$('note_body').setValue('Note saved. Click here to enter another one...');"
  end

end