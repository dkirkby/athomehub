// Javascript code shared by all views generated by the athome controller

$(document).ready(function(){
  enableLiveUpdates();
  displayPlots();
  updateNoteForm();
});

function handleUpdate(response) {
  // remember our new high water mark
  last = response.last;
  // update our date and time display
  $('#date').html(response.date);
  $('#time').html(response.time);
  // update the timestamp associated with a new note
  $('#note_view_at').val(response.view_at);
  $.each(response.updates,function(nid_tag,cells) {
    // iterate over the cells of the table row displaying this network ID
    $('#'+nid_tag+' > *').each(function(index) {
      // replace the cell contents after the initial location cell
      if(index > 0) $(this).html(cells[index-1]);
    })
  });
}

function requestUpdate() {
  jQuery.getJSON("/athome/update",{last:last},handleUpdate);
}

function enableLiveUpdates() {
  if($('.live-updates').length) {
    // runs once per second
    setInterval(requestUpdate,1000);
  }
  if($('.click-to-update').length) {
    // runs on demand
    $('#datetime').click(requestUpdate);
  }
}

function updatePlot(response) {
  // update our date and time display
  $('#date').html(response.date);
  $('#time').html(response.time);
  // update the timestamp associated with a new note
  $('#note_view_at').val(response.view_at);
  // update the navigation globals
  zoom = response.zoom;
  index = response.index;
  zoom_in = response.zoom_in;
  zoom_out = response.zoom_out;
  updateControls();
  // update the plots
  $('.plot').each(function(index) {
    $.plot($(this),response.data[this.id],response.options[this.id]);
    $(this).siblings('.title').html(response.titles[this.id]);
  });
}

function updateControls() {
  // disable zoom in if we are already at the limit
  if(zoom_in == index) {
    $("#zoom-in").addClass('disabled');
  }
  else {
    $("#zoom-in").removeClass('disabled');    
  }  
  // disable zoom out if we are already at the limit
  if(zoom_out == index) {
    $("#zoom-out").addClass('disabled');
  }
  else {
    $("#zoom-out").removeClass('disabled');    
  }  
}

function requestPlotUpdate(clickable,options) {
  if(!$(clickable).hasClass('disabled')) {
    jQuery.getJSON("/athome/replot",options,updatePlot);
  }
  else {
    alert("sorry!");
  }
}

function displayPlots() {
  /* display any binned plots on this page */
  $('.plot').each(function(index) {
    // render the plot using the flot library
    $.plot($(this),plotData[this.id],plotOptions[this.id]);
    // display a title below the plot
    $(this).siblings('.title').html(plotTitles[this.id]);
  });
  /* attach ajax actions to the window navigation labels */
  $("#oldest").click(function() {
    requestPlotUpdate(this,{nid:nid,zoom:zoom,index:'first'});
  });
  $("#newest").click(function() {
    requestPlotUpdate(this,{nid:nid,zoom:zoom,index:'last'});
  });
  $("#older").click(function() {
    requestPlotUpdate(this,{nid:nid,zoom:zoom,index:index-1});
  });
  $("#newer").click(function() {
    requestPlotUpdate(this,{nid:nid,zoom:zoom,index:index+1});
  });
  $("#zoom-in").click(function() {
    requestPlotUpdate(this,{nid:nid,zoom:zoom-1,index:zoom_in});
  });
  $("#zoom-out").click(function() {
    requestPlotUpdate(this,{nid:nid,zoom:zoom+1,index:zoom_out});
  });
  updateControls();
}

// Updates the note form found on all athome views to enable javascript behaviors
function updateNoteForm() {
  // check that there is a rails-generated new-note form to update on this page
  var f = $('#new_note');
  if(f.length == 0) return;

  // if we have a default user, replace the selector with the name and a change link
  if($('#note_user_id option[selected]').length == 1) {
    $('#note_user_id').hide();
    $('#note_by').append("<span id='note_user'>" + $("#note_user_id :selected").text() +
      " (<a href='#'>change</a>)</span>");
    $('#note_user a').click(function() {
      $('#note_user').fadeOut('fast',function() {$('#note_user_id').fadeIn('fast');});
      return false;
    });
  }
  // replace the submit button with a link
  $('#note_save').html("<a href='#'>Save</a>");
  $('#note_save a').click(function() {
    f.submit();
    return false;
  });
  // hide the text below the note textarea until the textarea is selected
  $('#note_by').hide();
  $('#note_save').hide();
  $('#note_body').removeClass('active');
  $('#note_body').focus(function(){
    $('#note_body').addClass('active');
    $('#note_by').show();
    $('#note_save').show();
  });
  // select the textarea text if it still shows the initial prompt
  var initialPrompt = $('#note_body')[0].defaultValue;
  $('#note_body').click(function() {
    if(this.value == initialPrompt) this.select();
  });
  /** don't implement a blur handler since it interferes with the submit handler
  $('#note_body').blur(function() {
    // remove the textarea highlight
    $('#note_body').removeClass('active');
    // hide the text below the note textarea
    $('#note_by').hide();
    $('#note_save').hide();
  });
  **/
  // redefine the submit action to use Ajax
  f.submit(function(){
    $.post($(this).attr('action')+'.txt',$(this).serialize(),function(data) {
      // if the request is successful...
      // momentarily replace the submit link with create_note response
      $('#note_save a').hide();
      $('#note_save').append("<span>"+data+"</span>");
      $('#note_save span').delay(1500).fadeOut('fast',function() {
        $('#note_save span').remove();
        $('#note_save a').show();
        // update the message in the note textarea
        $('#note_body').removeClass('active').val(initialPrompt);
        // hide the text below the note textarea
        $('#note_by').hide();
        $('#note_save').hide();
      });
    },"text");
    return false; // don't actually submit this form
  });
}