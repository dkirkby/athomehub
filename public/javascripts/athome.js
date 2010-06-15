// Javascript code shared by all views generated by the athome controller

$(document).ready(function(){
  updateNoteForm();
  displayGraphs();
});

// Replaces any tables of class 'graph-me' with a graph
function displayGraphs() {
  $('table.graph-me').each(function() {
    // create empty placeholders for the three graphs
    var tempID = this.id + '-temp';
    $(this).after("<div id='" + tempID + "' class='graph'>TEMP GRAPH GOES HERE</div>");
    var tempGraph = $('#'+tempID);
    var lightID = this.id + '-light';
    tempGraph.after("<div id='" + lightID + "' class='graph'>LIGHT GRAPH GOES HERE</div>");
    var lightGraph = $('#'+lightID);
    var powerID = this.id + '-power';
    lightGraph.after("<div id='" + powerID + "' class='graph'>POWER GRAPH GOES HERE</div>");
    var powerGraph = $('#'+powerID);
    // how many rows of data do we have to graph?
    var rowData = $(this).find('tr');
    var nrows = rowData.length - 1; // do not count the header row
    // prepare the plot data for each graph
    var tempData = new Array(nrows);
    var lightData = new Array(nrows);
    var powerData = new Array(nrows);
    var beginAt = 1e3*$('#begin_at').val();
    var endAt = 1e3*$('#end_at').val();
    var when,data;
    rowData.each(function(row){
      if(row == 0) return; // skip the header row
      data = $(this).find('td');
      when = beginAt + 1e3*Number($(data[1]).html());
      tempData[row-1] = [when,Number($(data[2]).html())];
      lightData[row-1] = [when,Number($(data[3]).html())];
      powerData[row-1] = [when,Number($(data[4]).html())];
    });
    // prepare the plot options
    var plotOptions = { xaxis: { mode: 'time', min: beginAt, max: endAt } };
    // plot into each placeholder
    var tempPlot = $.plot(tempGraph,[{data:tempData}],plotOptions);
    var lightPlot = $.plot(lightGraph,[{data:lightData}],plotOptions);
    var powerPlot = $.plot(powerGraph,[{data:powerData}],plotOptions);
  });
}

// Updates the note form found on all athome views to enable javascript behaviors
function updateNoteForm() {
  // check that there is a rails-generated new-note form on this page
  var f = $('#new_note');
  if(f.length == 0) {
    alert("updateNoteForm called on page with no new-note form");
    return;
  }
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
        $('#note_body').removeClass('active');
      });
    },"text");
    return false; // don't actually submit this form
  });
}