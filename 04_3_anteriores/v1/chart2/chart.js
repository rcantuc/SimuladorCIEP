// JavaScript Document

var barSpacing = 0;
var barWidth = 0;
var chartHeight = 0;
var chartHeightArea = 0;
var chartHeightArea2 = 0;
var chartScale = 0;
var maxValue = 0;
var yearMax = 0;
var minValue = 10000;
var yearMin = 0;
var highestYlabel = 0;
var valueMultiplier = 0;
var aniosaSumarIndex=2013;

function colorBar(val) { /**** recibe arreglo de valores y regresa arreglo de coroles, los valores esperados en el intervalo (0,100] ****/
// verde rgb(0,201,59) 
// rojo  rgb(232,85,49)
	var r= parseInt(val*2.32);
	var g= parseInt(201-val*1.2);
	return "rgb(" + r +"," + g +",49)";
}

$(document).ready(function(){

	window.chartHeight = Number($('.chart-area').height());
	window.barWidth = $('.chart-area .chart-bar').width();
	window.highestYlabel = Number($('.chart-y-axis p span').first().html());
	window.chartHeightArea = window.chartHeight - Number($('p.axis-value').first().height());
	window.chartScale = chartHeightArea / window.highestYlabel;
	window.barSpacing = Number($('.chart-area').attr('bar-spacing'));
	positionBars();
	
	window.chartHeight2 = Number($('.chart-area2').height());
	window.chartHeightArea2 = window.chartHeight2 - Number($('p.axis-value').first().height());
	window.chartScale2 = chartHeightArea2 / window.highestYlabel;
	positionBars2();

});

function positionBars(){
	$('.chart-area .chart-bar').each(function(index){
	
		var barPosition = (window.barWidth*index)+(index*barSpacing)+barSpacing;
		//$(this).css('left',barPosition+'px');
		$(this).html('<p>'+$(this).attr('bar-value')+' %'+'</p>');
		//$('.chart-x-axis').append('<p style="left:'+(barPosition-(window.barWidth/2))+'px;">'+$(this).attr('label')+'</p>');
		
		var barValue = Number($(this).attr('bar-value'));
		$(this).attr('title',barValue+'% del P.I.B.');
		$(this).css('background-color', '');
		
		if(barValue > window.maxValue){
			window.maxValue = barValue;
			window.yearMax = Number(index)+aniosaSumarIndex;
			window.valueMultiplier = window.maxValue / window.highestYlabel;
		}
		$(this).removeClass('chart-negativo');
		$(this).removeClass('chart-minimo');
		
		if(barValue < 15){
			$(this).addClass('chart-minimo');
		}
		if(barValue < 0){
			$(this).addClass('chart-negativo');
			var valornegativo = Number($(this).attr('bar-value'))*-1;
			$(this).attr('bar-value',valornegativo);
		}
		else 
			$(this).css('background-color',colorBar(barValue));
/*
		if(barValue < 11){
			$(this).css('background-color','#00c93b');
		}
		else if(barValue < 21){
			$(this).css('background-color','#1cb836');
		}
		else if(barValue < 31){


			$(this).css('background-color','#459e2e');
		}
		else if(barValue < 41){
//			var a = colorBar(barValue);
//						alert(barValue +" ... "+a + "<-" );
									$(this).css('background-color',colorBar(barValue));
		}
		else if(barValue < 51){
			$(this).css('background-color','#897420');
		}
		else if(barValue < 61){
			$(this).css('background-color','#9d671c');
		}
		else if(barValue < 71){
			$(this).css('background-color','#b05c19');
		}
		else if(barValue < 81){
			$(this).css('background-color','#c15115');
		}
		else if(barValue < 91){
			$(this).css('background-color','#d14712');
		}
		else 
			$(this).css('background-color','#de3f10');
*/
	});
	animateChart();
}


function positionBars2(){
	$('.chart-area2 .chart-bar').each(function(index){
	
		var barPosition = (window.barWidth*index)+(index*barSpacing)+barSpacing;
		//$(this).css('left',barPosition+'px');
		$(this).html('<p>'+$(this).attr('bar-value')+' %'+'</p>');
		//$('.chart-x-axis').append('<p style="left:'+(barPosition-(window.barWidth/2))+'px;">'+$(this).attr('label')+'</p>');
		
		var barValue = Number($(this).attr('bar-value'));
		$(this).attr('title',barValue+'% del P.I.B.');
		$(this).css('background-color', '');

		if(barValue > window.maxValue){
			window.maxValue = barValue;
			window.valueMultiplier = window.maxValue / window.highestYlabel;
		}
		else if(barValue < window.minValue ){
			window.minValue = barValue;
			window.yearMin = Number(index)+aniosaSumarIndex;
		}
		$(this).removeClass('chart-negativo');
		$(this).removeClass('chart-minimo');
		
		if(barValue < 15){
			$(this).addClass('chart-minimo');
		}
		if(barValue < 0){
			$(this).addClass('chart-negativo');
			var valornegativo = Number($(this).attr('bar-value'))*-1;
			$(this).attr('bar-value',valornegativo);
		}
		else 
			$(this).css('background-color',colorBar(barValue));

	});
	animateChart2();
}



function animateChart(){

	$('.chart-area .chart-bar').each(function(index){
		var revisedValue = Number($(this).attr('bar-value'))*window.chartScale;
		var newDelay = 125*index;		
		$(this).delay(newDelay).animate({height:revisedValue},1000, function(){
		$(this).children('p').delay(500).fadeIn(250);

		});
	});

}


function animateChart2(){

	$('.chart-area2 .chart-bar').each(function(index){
		var revisedValue = Number($(this).attr('bar-value'))*window.chartScale2;
		var newDelay = 125*index;		
		$(this).delay(newDelay).animate({height:revisedValue},1000, function(){
		$(this).children('p').delay(500).fadeIn(250);

		});
	});
	
	/* debug */ $('.maxValue').html('% del P.I.B. máximo = <strong>'+window.maxValue+'%</strong> en <strong>'+window.yearMax+'</strong>');
	/* debug */ $('.minValue').html('% del P.I.B. mínimo = <strong>'+window.minValue+'%</strong> en <strong>'+window.yearMin+'</strong>');
	
	/* debug */ $('.valueMultiplier').html('valueMultiplier = '+window.valueMultiplier);
	/* debug */ $('.highestYlabel').html('highestYlabel = '+highestYlabel);
	/* debug */ $('.chartHeight').html('chartHeight = '+window.chartHeight);
	/* debug */ $('.chartHeightArea').html('chartHeightArea = '+window.chartHeightArea);
	/* debug */ $('.chartScale').html('chartScale = '+window.chartScale);

}
