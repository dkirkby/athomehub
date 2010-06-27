$(document).ready(function(){
  $("#dump").after('<div id="dump-plot"></div>');
  $.plot($("#dump-plot"),[{data:plotData}],plotOptions);
  $("#dump").hide();
});
