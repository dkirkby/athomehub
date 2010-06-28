$(document).ready(function(){
  $("#dump").after('<div id="dump-plot"></div>');
  $.plot($("#dump-plot"),[
    {data:plotData,color:"rgb(44,113,78)",points:{show:true,radius:2,fill:false}},
    {data:modelData,color:"rgba(222,211,54,0.4)",lines:{lineWidth:4}}
  ],plotOptions);
  $("#dump").hide();
});
