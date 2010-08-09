// Javascript code shared by all views generated by the athome controller

$(document).ready(function(){
  updateLighting();
  enableLiveUpdates();
  displayPlots();
  updateNoteForm();
});

function updateLighting() {
  $(".level").each(function() {
    var theLevel = $(this).attr("class").substr(6); // strip off leading "level "
    $(this).css('opacity',theLevel); // jquery handles IE special cases
    $(this).parent().attr('title',theLevel);
  });
}

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
      if(index > 0) $(this).replaceWith(cells[index-1]);
    })
  });
  updateLighting();
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
  // update the window title
  $('#datetime').html(response.title);
  // update the timestamp associated with a new note
  $('#note_view_at').val(response.view_at);
  // update the navigation globals
  zoom = response.zoom;
  index = response.index;
  zoom_in = response.zoom_in;
  zoom_out = response.zoom_out;
  updateControls();
  // update the plots
  plotData = response.data;
  plotOptions = response.options;
  dataLabels = response.labels;
  $('.plot').each(function() {
    if($(this).height() > 0) {
      $.plot($(this),plotData[this.id],plotOptions[this.id]);
    }
  });
}

function updateControls() {
  // disable zoom in if we are already at the limit
  $("#zoom-in").toggleClass('disabled',(zoom_in == index));
  // disable zoom out if we are already at the limit
  $("#zoom-out").toggleClass('disabled',(zoom_out == index));
  // disable older if we are already at the minimum index
  $("#older").toggleClass('disabled',(index == 0));
  // add our window parameters to the note form
  $('#note_view').val('detail?nid='+nid+'&zoom='+zoom+'&index='+index);
}

function requestPlotUpdate(clickable,options) {
  if(!$(clickable).hasClass('disabled')) {
    jQuery.getJSON("/athome/replot",options,updatePlot);
  }
}

var lastClick = null;

function displayPlots() {
  /* display any binned plots on this page */
  $('.section').each(function() {
    var thePlot = $(this).find(".plot").first();
    var plotID = $(thePlot).attr('id');
    // render the plot using the flot library
    $.plot(thePlot,plotData[plotID],plotOptions[plotID]);
    // display a plot title that is clickable to hide/show the plot
    var theFrame = $(this).find('.frame').first();
    $(this).find(".title").html(plotTitles[plotID]).hover(
      function() {
        $(this).addClass('hover');
        //$(this).children('.title-controls').fadeIn('fast');
      },
      function() {
        $(this).removeClass('hover');
        //$(this).children('.title-controls').fadeOut('fast');
      }
    ).toggle(
      function() {
        theFrame.slideUp(500);
      },
      function() {
        theFrame.slideDown(500);
        // update the plot (we can only do this when it is visible)
        $.plot(thePlot,plotData[plotID],plotOptions[plotID]);
      }
    );
    // bind a hover event handler to the plot
    thePlot.bind("plothover", function (event, pos, item) {
      if(item) {
        if(item.datapoint != lastClick) {
          $('#data-label').remove();
          lastClick = item.datapoint;
          $('<div id="data-label" class="popup">' +
            dataLabels[plotID][item.dataIndex] + '</div>').css({
            top: item.pageY - 35, left: item.pageX - 20
          }).appendTo("body");
        }
      }
      else {
        $('#data-label').remove();
        lastClick = null;
      }
    });
  });
  if($("#oldest").length > 0) {
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
    // double clicking on the header creates/updates a tooltip with debug info
    $('#header').dblclick(function() {
      $(this).attr('title',"nid="+nid+",zoom="+zoom+",index="+index);
    });
  }
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