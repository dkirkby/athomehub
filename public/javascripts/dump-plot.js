$(document).ready(function(){
  $("#dump").after('<div id="dump-plot"></div>');
  $.plot($("#dump-plot"),[
      {data:modelData},
      {data:plotData, points:{show:true}}
    ],plotOptions);
  $("#dump").hide();
});
