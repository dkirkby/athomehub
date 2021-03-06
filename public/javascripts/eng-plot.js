$(document).ready(function(){

  /* display any dump plots on this page */
  $('.dump-plot').each(function(index) {
    var plotID = this.id + '-plot';
    $(this).after('<div id="' + plotID + '" class="eng-plot"></div>');
    $.plot($("#" + plotID),[
      {data:plotData,color:"rgb(44,113,78)",points:{show:true,radius:2,fill:false}},
      {data:modelData,color:"rgba(222,211,54,0.4)",lines:{lineWidth:4}}
    ],plotOptions);
    $(this).hide();
  });
  
  /* display any analysis plots on this page */
  $('.analysis-plot').each(function(index) {
    var plotID = this.id + '-plot';
    $(this).after('<div id="' + plotID + '" class="eng-plot"></div>');
    $.plot($("#" + plotID),analysisPlotData[this.id],analysisPlotOptions[this.id]);
  });

  /* display any sample plots on this page */
  var samplePlotOptions = {
    xaxis: { mode:"time" },
    series:{ lines:{ show: true}, points:{ show:false,radius:2,fill:false } }
  };
  $('.sample-plot').each(function(index) {
    var plotID = this.id + '-plot';
    $(this).after('<div id="' + plotID + '" class="eng-plot"></div>');
    $.plot($("#" + plotID),samplePlots[this.id],samplePlotOptions);
  });

  /* display any binned plots on this page */
  var binnedPlotOptions = {
    xaxis: { mode:"time" },
    series:{ lines:{ show: true}, points:{ show:true,radius:4,fill:false } }
  };
  $('.binned-plot').each(function(index) {
    var plotID = this.id + '-plot';
    $(this).after('<div id="' + plotID + '" class="eng-plot"></div>');
    $.plot($("#" + plotID),binnedPlots[this.id],binnedPlotOptions);
  });

});
