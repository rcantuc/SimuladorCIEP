// JavaScript Document

function sumatoria(arreglo,inicio,fin ) {
	var resultado =0;
	if(inicio>=fin || !Array.isArray(arreglo))
		return resultado;
	for(var i=inicio;i<=fin;i++) {
		resultado+=arreglo[i];	
	}
	return resultado;
}

function formato(cnt, cents) {
	if (typeof cnt === "undefined")
		return 0;
	cnt = cnt.toString().replace(/\$|\u20AC|\,/g,'');
	if (isNaN(cnt))
		return 0;	
	var sgn = (cnt == (cnt = Math.abs(cnt)));
	cnt = Math.floor(cnt * 100 + 0.5);
	var cvs = cnt % 100;
	cnt = Math.floor(cnt / 100).toString();
	if (cvs < 10)
	cvs = '0' + cvs;
	for (var i = 0; i < Math.floor((cnt.length - (1 + i)) / 3); i++)
		cnt = cnt.substring(0, cnt.length - (4 * i + 3)) + ',' + cnt.substring(cnt.length - (4 * i + 3));
	
	return (((sgn) ? '' : '-') + cnt) + ( cents ?  '.' + cvs : '');
};

function quitaFormato(cnt) {
	if (typeof cnt === "undefined")
		return 0;	
	cnt = cnt.toString().replace(/,/g,'');
	if (isNaN(cnt))
		return 0;	
	return Number(cnt);
};



function makeid()
{
    var text = "";
    var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    for( var i=0; i < 8; i++ )
        text += possible.charAt(Math.floor(Math.random() * possible.length));

    return text;
}


function setCookie(c_name,value,exdays) {
	var exdate=new Date();
	exdate.setDate(exdate.getDate() + exdays);
	var c_value=escape(value) + ((exdays==null) ? "" : "; expires="+exdate.toUTCString());
	document.cookie=c_name + "=" + c_value;
}


function getCookie(c_name)
{
	var c_value = document.cookie;
	var c_start = c_value.indexOf(" " + c_name + "=");
	if (c_start == -1) {
	  c_start = c_value.indexOf(c_name + "="); 
	}
	if (c_start == -1) {
	  c_value = null;
	} else {
	  c_start = c_value.indexOf("=", c_start) + 1;
	  var c_end = c_value.indexOf(";", c_start);
	  if (c_end == -1) {
		c_end = c_value.length;
	  }
	  c_value = unescape(c_value.substring(c_start,c_end));
	}
	return c_value;
}


function esnumero(numero){
	if(numero!='' && numero!='.' && ((/^[0-9]*[.][0-9]*/).test(numero) || (/^[0-9]+$/).test(numero) ) && !(/[a-zA-Z]+/).test(numero))
		return true;
	return false;
}

function esnumeroConNeg(numero){
	if(numero!='' && numero!='.' && ((/^[-]?[0-9]*[.][0-9]*/).test(numero) || (/^[-]?[0-9]+$/).test(numero) ) && !(/[a-zA-Z]+/).test(numero))
		return true;
	return false;
}

function entreIntervalo(menor, valor, mayor){
	var vmin= parseFloat(menor);
	var v= parseFloat(valor);
	var vmax= parseFloat(mayor);
	if(vmin < v  && v < vmax) {
		return true;
		
	}
	return false;
}

google.load("visualization", "1", {packages:["corechart"]});


$(document).ready(function() {
	var Ingresos ="";
	var Gastos ="";				
	var Deuda ="";				
	var fechas ="";
	var Gini=0;
	var giniold=0;
	var idSession="";
	var recaudacionGasto=new Array();
	if(getCookie("idSession")!=null) {
		idSession=getCookie("idSession");
	} 
	$.ajax({
	url: "default.xml", // MUSEO (2026-10-01): respuesta estática con las cifras de la LIF/PEF 2014; el original llamaba default.php?idSession=
	dataType: "xml",
	async:false,
	success: function (xml) {
			Ingresos= eval($(xml).find("Ingresos").text());
			Gastos= eval($(xml).find("Gastos").text());
			Deuda= eval($(xml).find("Deuda").text());
			fechas= eval($(xml).find("fecha").text());
			Gini=eval($(xml).find("Gini").text());
			Gini=Gini[0];
			var ii=0;
			for (i=0;i<fechas.length-1;i++) {
				ii=i+1;
				recaudacionGasto[i] = eval($(xml).find("Lif"+ii).text());
			}
			var year =0;
			var lif = new Array(
				sumatoria(recaudacionGasto[year],0,45), sumatoria(recaudacionGasto[year],0,19),recaudacionGasto[year][0], 
				recaudacionGasto[year][0], recaudacionGasto[year][1],sumatoria(recaudacionGasto[year],2,12), recaudacionGasto[year][2], 
				sumatoria(recaudacionGasto[year],3,12),recaudacionGasto[year][3], recaudacionGasto[year][4], recaudacionGasto[year][5],
				recaudacionGasto[year][6], recaudacionGasto[year][7], recaudacionGasto[year][8], recaudacionGasto[year][9], recaudacionGasto[year][10],
				recaudacionGasto[year][11], recaudacionGasto[year][12], recaudacionGasto[year][13], recaudacionGasto[year][14], recaudacionGasto[year][14],	
				recaudacionGasto[year][15],recaudacionGasto[year][16], recaudacionGasto[year][17],	recaudacionGasto[year][18], recaudacionGasto[year][19],
				recaudacionGasto[year][20], sumatoria(recaudacionGasto[year],21,25), recaudacionGasto[year][21], recaudacionGasto[year][22], 
				recaudacionGasto[year][23], recaudacionGasto[year][24], recaudacionGasto[year][25], recaudacionGasto[year][26], recaudacionGasto[year][26], 
				sumatoria(recaudacionGasto[year],27,32), recaudacionGasto[year][27], recaudacionGasto[year][28], recaudacionGasto[year][29], 
				recaudacionGasto[year][30], recaudacionGasto[year][31], recaudacionGasto[year][32], sumatoria(recaudacionGasto[year],33,35), 
				recaudacionGasto[year][33], recaudacionGasto[year][34], recaudacionGasto[year][35], sumatoria(recaudacionGasto[year],36,37), 
				recaudacionGasto[year][36], recaudacionGasto[year][37], sumatoria(recaudacionGasto[year],38,43), sumatoria(recaudacionGasto[year],38,39),
				recaudacionGasto[year][38], recaudacionGasto[year][39], sumatoria(recaudacionGasto[year],40,42), recaudacionGasto[year][40], 
				recaudacionGasto[year][41], recaudacionGasto[year][42],recaudacionGasto[year][43], recaudacionGasto[year][44], recaudacionGasto[year][45],
				sumatoria(recaudacionGasto[year],0,45)			
				);
			var valores = lif.length;

			for(var i = 0; i< valores;i++) {
				ii=i+1;
				$('.recaudacionGasto'+ii+'-1').text('$ ' +formato(lif[i],true));	
				porcentaje  = lif[i] /Ingresos[year]*100;
				$('.recaudacionGasto'+ii).text( porcentaje.toFixed(2) + '%');	
				$('#valor'+ii).css("width", porcentaje.toFixed(2) );	
			}
			
		}
	});

	$.ajax({
	url: "inputsaved.xml", // MUSEO (2026-10-01): respuesta estática; el original llamaba inputsaved.php?idSession=
	dataType: "xml",
	async:false,
	success: function (xml) {
//		alert(xml);
			giniold=eval($(xml).find("giniold").text());
			giniold=giniold[0];
		}
	});

	$('#recaudacionMPD').text(formato(Ingresos[0],true));
	$('#gastoMPD').text(formato(Gastos[0],true));
	$('#deudaMPD').text(formato(Deuda[0],true));

	demoGauge.set(Gini*100); // función del velocimetro cambia valor
	gauge.set(giniold*100); // función del velocimetro cambia valor
//	alert(giniold + " - " + gauge );
	$('.vel-val').text(Gini);
	$('.vel-val0').text(giniold);

	var actualizaItemGraf = function(num, valor) {
		$('#barI'+num).attr('bar-value',valor);
		$('#barII'+num).attr('bar-value',valor);
		$('#bar_shrfsp'+num).text(valor);					
	}
	var actualizaItemGrafPrima = function(num, SHRFSP, RFSP, BT, IPAB ,Adecuaciones, FARAC, Deudores, Banca, PIDIREGAS) {
		var otros = Number(IPAB)+Number(Adecuaciones)+Number(FARAC)+Number(Deudores)+Number(Banca)+Number(PIDIREGAS);

		$('#barI'+num).attr('bar-value',SHRFSP);
		$('#barII'+num).attr('bar-value',SHRFSP);
		$('#bar_shrfsp'+num).text(-1*Number(SHRFSP));		
		$('#barII_shrfsp'+num).text(-1*Number(SHRFSP));		
		$('#barII_RFSP'+num).text(RFSP);		
		$('#barII_otros'+num).text(parseFloat(otros).toFixed(2));		
		$('#barII_BT'+num).text(BT);		
	}

	var actualizaItemtabla = function(idvalor, valor) {

		$(idvalor).html(valor); 
		
		if(quitaFormato(valor)>=0) {
			$(idvalor).addClass('positive');
			$(idvalor).removeClass('negative');
		} else {
			$(idvalor).addClass('negative');
			$(idvalor).removeClass('positive');
		}

	}

	var actualizaItemtablaString = function(idvalor, valor, cadena) {

		$(idvalor).html(valor + cadena); 
		if(quitaFormato(valor)>=0) {
			$(idvalor).addClass('positive');
			$(idvalor).removeClass('negative');
		} else {
			$(idvalor).addClass('negative');
			$(idvalor).removeClass('positive');
		}

	}

	$('#borrarCambios').click(function () {		
		setCookie("idSession",null,-1);
		
	});



		/*****************  envio de Seguridad Social ************************/	
	$('#seguridadSocialSub').click(function () {		
		var seguridadSocialIn1 =  $('#seguridadSocialIn1').val();
		var seguridadSocialIn2 =  $('#seguridadSocialIn2').val();
		var seguridadSocialIn3 =  $('#seguridadSocialIn3').val();
		var seguridadSocialIn4 =  $('#seguridadSocialIn4').val();
		var seguridadSocialIn5 =  $('#seguridadSocialIn5').val();
		var seguridadSocialIn6 =  $('#seguridadSocialIn6').val();
		var seguridadSocialIn7 =  $('#seguridadSocialIn7').val();
		var seguridadSocialIn8 =  $('#seguridadSocialIn8').val();
		var seguridadSocialIn9 =  $('#seguridadSocialIn9').val();
		var seguridadSocialIn10 =  $('#seguridadSocialIn10').val();
		var seguridadSocialIn11 =  $('#seguridadSocialIn11').val();
		var seguridadSocialIn12 =  $('#seguridadSocialIn12').val();
		var seguridadSocialIn13 =  $('#seguridadSocialIn13').val();
		var seguridadSocialIn14 =  $('#seguridadSocialIn14').val();
		var seguridadSocialIn15 =  $('#seguridadSocialIn15').val();
		var seguridadSocialIn16 =  $('#seguridadSocialIn16').val();
		var seguridadSocialIn17 =  $('#seguridadSocialIn17').val();
		var seguridadSocialIn18 =  $('#seguridadSocialIn18').val();
		var seguridadSocialIn19 =  $('#seguridadSocialIn19').val();
		var seguridadSocialIn20 =  $('#seguridadSocialIn20').val();
		var seguridadSocialIn21 =  $('#seguridadSocialIn21').val();
		var seguridadSocialIn22 =  $('#seguridadSocialIn22').val();
		var seguridadSocialIn23 =  $('#seguridadSocialIn23').val();
		var seguridadSocialIn24 =  $('#seguridadSocialIn24').val();
		var seguridadSocialIn25 =  $('#seguridadSocialIn25').val();
		var seguridadSocialIn26 =  $('#seguridadSocialIn26').val();
		var seguridadSocialIn27 =  $('#seguridadSocialIn27').val();
		var seguridadSocialIn28 =  $('#seguridadSocialIn28').val();
		var seguridadSocialIn29 =  $('#seguridadSocialIn29').val();
		var seguridadSocialIn30 =  $('#seguridadSocialIn30').val();
		var seguridadSocialIn31 =  $('#seguridadSocialIn31').val();
		var seguridadSocialIn32 =  $('#seguridadSocialIn32').val();
		var seguridadSocialIn33 =  $('#seguridadSocialIn33').val();
		var seguridadSocialIn34 =  $('#seguridadSocialIn34').val();
		
		                      
		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);
		
		var data = 'seguridadSocialIn1=' + seguridadSocialIn1 + '&seguridadSocialIn2=' + seguridadSocialIn2 + '&seguridadSocialIn3=' + seguridadSocialIn3 + '&seguridadSocialIn4=' + seguridadSocialIn4 + '&seguridadSocialIn5=' + seguridadSocialIn5 + '&seguridadSocialIn6=' + seguridadSocialIn6 + '&seguridadSocialIn7=' + seguridadSocialIn7 + '&seguridadSocialIn8=' + seguridadSocialIn8 + '&seguridadSocialIn9=' + seguridadSocialIn9 + '&seguridadSocialIn10=' + seguridadSocialIn10 + '&seguridadSocialIn11=' + seguridadSocialIn11 + '&seguridadSocialIn12=' + seguridadSocialIn12 + '&seguridadSocialIn13=' + seguridadSocialIn13 + '&seguridadSocialIn14=' + seguridadSocialIn14 + '&seguridadSocialIn15=' + seguridadSocialIn15 + '&seguridadSocialIn16=' + seguridadSocialIn16 + '&seguridadSocialIn17=' + seguridadSocialIn17 + '&seguridadSocialIn18=' + seguridadSocialIn18 + '&seguridadSocialIn19=' + seguridadSocialIn19 + '&seguridadSocialIn20=' + seguridadSocialIn20 + '&seguridadSocialIn21=' + seguridadSocialIn21 + '&seguridadSocialIn22=' + seguridadSocialIn22 + '&seguridadSocialIn23=' + seguridadSocialIn23 + '&seguridadSocialIn24=' + seguridadSocialIn24 + '&seguridadSocialIn25=' + seguridadSocialIn25 + '&seguridadSocialIn26=' + seguridadSocialIn26 + '&seguridadSocialIn27=' + seguridadSocialIn27 + '&seguridadSocialIn28=' + seguridadSocialIn28 + '&seguridadSocialIn29=' + seguridadSocialIn29 + '&seguridadSocialIn30=' + seguridadSocialIn30 + '&seguridadSocialIn31=' + seguridadSocialIn31 + '&seguridadSocialIn32=' + seguridadSocialIn32 + '&seguridadSocialIn33=' + seguridadSocialIn33 + '&seguridadSocialIn34=' + seguridadSocialIn34 + '&idSession='+idSession ;

//		alert("data");
		$.ajax({
			url: "seguridad-socialStata.php",	
			
			async:false,

			//GET method is used
			type: "GET",

			//pass the data			
			data: data,		
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (html) {	
				$('.loading').css('visibility','hidden');
				$('.loading').hide();

				fechas = eval($(html).find("fecha").text()); 				
				var distribucion = eval($(html).find("distribucion").text());								
				var SHRFSP = eval($(html).find("SHRFSP").text());
				var RFSP = eval($(html).find("RFSP").text());
				var BalanceTrad = eval($(html).find("BalanceTrad").text());
				var IPAB = eval($(html).find("IPAB").text());
				var Adecuaciones = eval($(html).find("Adecuaciones").text());
				var FARAC = eval($(html).find("FARAC").text());
				var Deudores = eval($(html).find("Deudores").text());
				var Banca = eval($(html).find("Banca").text());
				var PIDIREGAS = eval($(html).find("PIDIREGAS").text());				
				Gini = eval($(html).find("Gini").text());				
				Gini=Gini[0];
				
				Ingresos = eval($(html).find("Ingresos").text());				
				Gastos = eval($(html).find("Gastos").text());				
				Deuda = eval($(html).find("Deuda").text());		

				var edades = eval($(html).find("edades").text());
				var cuotashom = eval($(html).find("cuotashom").text());
				var cuotasmuj = eval($(html).find("cuotasmuj").text());
				var reccuotas = eval($(html).find("reccuotas").text());
				var pibcuotas = eval($(html).find("pibcuotas").text());
				var cuotas_1 = eval($(html).find("cuotas_1").text());
				var cuotas_2 = eval($(html).find("cuotas_2").text());
				var cuotas_3 = eval($(html).find("cuotas_3").text());

				 
				for(var i =0;i<SHRFSP.length;i++) {
					SHRFSP[i]=-1*Number(SHRFSP[i]); 									
				}


				$('#ecuRGD').html('');
				
				for(var i =0;i<Ingresos.length;i++) {
					$("#ecuRGD").append('<option value='+i+'>'+fechas[i]+'</option>');
				}
				

				demoGauge.set(Gini*100); // función del velocimetro cambia valor
				$('.vel-val').text(Gini);
				$('#recaudacionProyectada').text(formato(reccuotas,true));
				$('#pibProyectado').text(pibcuotas);
				
				for(var i=0;i<cuotas_1.length;i++) {
					actualizaItemtabla("#cuotas1_"+i,formato(cuotas_1[i],true));
					actualizaItemtablaString("#cuotas2_"+i,cuotas_2[i]," %");
					actualizaItemtablaString("#cuotas3_"+i,cuotas_3[i]," %");
				}

				$('#recaudacionMPD').text(formato(Ingresos[0],true));
				$('#gastoMPD').text(formato(Gastos[0],true));
				$('#deudaMPD').text(formato(Deuda[0],true));

				/******************  Actualizar el gráfico de barras ***********/
				actualizaItemGrafPrima('13',SHRFSP[0],RFSP[0],BalanceTrad[0],IPAB[0],Adecuaciones[0],FARAC[0],Deudores[0],Banca[0],PIDIREGAS[0]);
				actualizaItemGrafPrima('14',SHRFSP[1],RFSP[1],BalanceTrad[1],IPAB[1],Adecuaciones[1],FARAC[1],Deudores[1],Banca[1],PIDIREGAS[1]);
				actualizaItemGrafPrima('15',SHRFSP[2],RFSP[2],BalanceTrad[2],IPAB[2],Adecuaciones[2],FARAC[2],Deudores[2],Banca[2],PIDIREGAS[2]);
				actualizaItemGrafPrima('16',SHRFSP[3],RFSP[3],BalanceTrad[3],IPAB[3],Adecuaciones[3],FARAC[3],Deudores[3],Banca[3],PIDIREGAS[3]);
				actualizaItemGrafPrima('17',SHRFSP[4],RFSP[4],BalanceTrad[4],IPAB[4],Adecuaciones[4],FARAC[4],Deudores[4],Banca[4],PIDIREGAS[4]);
				actualizaItemGrafPrima('18',SHRFSP[5],RFSP[5],BalanceTrad[5],IPAB[5],Adecuaciones[5],FARAC[5],Deudores[5],Banca[5],PIDIREGAS[5]);
				actualizaItemGrafPrima('19',SHRFSP[6],RFSP[6],BalanceTrad[6],IPAB[6],Adecuaciones[6],FARAC[6],Deudores[6],Banca[6],PIDIREGAS[6]);
				actualizaItemGrafPrima('20',SHRFSP[7],RFSP[7],BalanceTrad[7],IPAB[7],Adecuaciones[7],FARAC[7],Deudores[7],Banca[7],PIDIREGAS[7]);
				actualizaItemGrafPrima('21',SHRFSP[8],RFSP[8],BalanceTrad[8],IPAB[8],Adecuaciones[8],FARAC[8],Deudores[8],Banca[8],PIDIREGAS[8]);
				actualizaItemGrafPrima('22',SHRFSP[9],RFSP[9],BalanceTrad[9],IPAB[9],Adecuaciones[9],FARAC[9],Deudores[9],Banca[9],PIDIREGAS[9]);
				actualizaItemGrafPrima('23',SHRFSP[10],RFSP[10],BalanceTrad[10],IPAB[10],Adecuaciones[10],FARAC[10],Deudores[10],Banca[10],PIDIREGAS[10]);
				actualizaItemGrafPrima('24',SHRFSP[11],RFSP[11],BalanceTrad[11],IPAB[11],Adecuaciones[11],FARAC[11],Deudores[11],Banca[11],PIDIREGAS[11]);
				actualizaItemGrafPrima('25',SHRFSP[12],RFSP[12],BalanceTrad[12],IPAB[12],Adecuaciones[12],FARAC[12],Deudores[12],Banca[12],PIDIREGAS[12]);
				positionBars();
				positionBars2();

					/*************************  Recargar el gráfico de google ********************/

				var datas = google.visualization.arrayToDataTable([
				  ['Edades', 'H Cuotas SS', 'M Cuotas SS'],
					[edades[0], cuotashom[0], cuotasmuj[0]],
					[edades[1], cuotashom[1], cuotasmuj[1]],
					[edades[2], cuotashom[2], cuotasmuj[2]],
					[edades[3], cuotashom[3], cuotasmuj[3]],
					[edades[4], cuotashom[4], cuotasmuj[4]],
					[edades[5], cuotashom[5], cuotasmuj[5]],
					[edades[6], cuotashom[6], cuotasmuj[6]],
					[edades[7], cuotashom[7], cuotasmuj[7]],
					[edades[8], cuotashom[8], cuotasmuj[8]],
					[edades[9], cuotashom[9], cuotasmuj[9]],
					[edades[10], cuotashom[10], cuotasmuj[10]],
					[edades[11], cuotashom[11], cuotasmuj[11]],
					[edades[12], cuotashom[12], cuotasmuj[12]],
					[edades[13], cuotashom[13], cuotasmuj[13]],
					[edades[14], cuotashom[14], cuotasmuj[14]],
					[edades[15], cuotashom[15], cuotasmuj[15]],
					[edades[16], cuotashom[16], cuotasmuj[16]],
					[edades[17], cuotashom[17], cuotasmuj[17]],
					[edades[18], cuotashom[18], cuotasmuj[18]],
					[edades[19], cuotashom[19], cuotasmuj[19]]
				]);
//				alert(datas);
			var options = {
			  curveType:'function',
			  width: 660, 
			  height: 328,
			  focusTarget: 'category',
			  chartArea:{top:5, bottom:0, width:"68%", height:"78%"},
			  lineWidth: 3,
			  fontSize: 11,
			  colors:['#38919c', '#fc782d','#38919c', '#fc782d'],
			  tooltip: {textStyle: {fontSize: 13}},
			  hAxis:{title: 'Edades',  titleTextStyle: {color: '#333', fontSize: 13}, textStyle: {color: '#686868'}},
			  vAxis:{title: 'Porcentaje de beneficiarios (%)', titleTextStyle: {color: '#333', fontSize: 13}, textStyle: {color: '#686868'}},
			  legend: {position:'right', alignment:'start', textStyle:{color: '#333', fontSize: 12}}
			};

			var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
			chart.draw(datas, options);
				
			var ii=0;
			for (i=0;i<fechas.length;i++) {
				ii=i+1;
				recaudacionGasto[i] = eval($(html).find("Lif"+ii).text());
			}
			var year =0;
			var lif = new Array(
				sumatoria(recaudacionGasto[year],0,45), sumatoria(recaudacionGasto[year],0,19),recaudacionGasto[year][0], 
				recaudacionGasto[year][0], recaudacionGasto[year][1],sumatoria(recaudacionGasto[year],2,12), recaudacionGasto[year][2], 
				sumatoria(recaudacionGasto[year],3,12),recaudacionGasto[year][3], recaudacionGasto[year][4], recaudacionGasto[year][5],
				recaudacionGasto[year][6], recaudacionGasto[year][7], recaudacionGasto[year][8], recaudacionGasto[year][9], recaudacionGasto[year][10],
				recaudacionGasto[year][11], recaudacionGasto[year][12], recaudacionGasto[year][13], recaudacionGasto[year][14], recaudacionGasto[year][14],	
				recaudacionGasto[year][15],recaudacionGasto[year][16], recaudacionGasto[year][17],	recaudacionGasto[year][18], recaudacionGasto[year][19],
				recaudacionGasto[year][20], sumatoria(recaudacionGasto[year],21,25), recaudacionGasto[year][21], recaudacionGasto[year][22], 
				recaudacionGasto[year][23], recaudacionGasto[year][24], recaudacionGasto[year][25], recaudacionGasto[year][26], recaudacionGasto[year][26], 
				sumatoria(recaudacionGasto[year],27,32), recaudacionGasto[year][27], recaudacionGasto[year][28], recaudacionGasto[year][29], 
				recaudacionGasto[year][30], recaudacionGasto[year][31], recaudacionGasto[year][32], sumatoria(recaudacionGasto[year],33,35), 
				recaudacionGasto[year][33], recaudacionGasto[year][34], recaudacionGasto[year][35], sumatoria(recaudacionGasto[year],36,37), 
				recaudacionGasto[year][36], recaudacionGasto[year][37], sumatoria(recaudacionGasto[year],38,43), sumatoria(recaudacionGasto[year],38,39),
				recaudacionGasto[year][38], recaudacionGasto[year][39], sumatoria(recaudacionGasto[year],40,42), recaudacionGasto[year][40], 
				recaudacionGasto[year][41], recaudacionGasto[year][42],recaudacionGasto[year][43], recaudacionGasto[year][44], recaudacionGasto[year][45],
				sumatoria(recaudacionGasto[year],0,45)			
				);
			var valores = lif.length;

			for(var i = 0; i< valores;i++) {
				ii=i+1;
				$('.recaudacionGasto'+ii+'-1').text('$ ' +formato(lif[i],true));	
				porcentaje  = lif[i] /Ingresos[year]*100;
				$('.recaudacionGasto'+ii).text( porcentaje.toFixed(2) + '%');	
			}

			
			},
			beforeSend: function () {
				$('.loading').css('visibility','visible');
				$('.loading').show();

				alert("El proceso de cálculo de esta sección puede durar hasta un par de minutos.");


			},		
			error: function(request,error) {
				console.log(request);
//				alert ( " Can't do because: " + error +'\n'+html);
			}
		});
		

	});



		/*****************  envio de petroleos derechos ************************/	
	$('#ecenarioPetroDerSub').click(function () {		
		var PetroDerechosB =  1;
		PetroDerechosB =  ($('#PetroDerechosB1').is(":checked")?2:($('#PetroDerechosB2').is(":checked")?3:1));
		var precioCrudo =  1;
		precioCrudo =  ($('#escenarioInercial1').is(":checked")?1:($('#escenarioInercial2').is(":checked")?2:3));
		var precioGas =  1;
		precioGas =  ($('#escenario1').is(":checked")?1:($('#escenario2').is(":checked")?2:3));
		

		                      
		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);
		
		var data = 'PetroDerechosB1=' + PetroDerechosB + '&PetroDerechosB2=' + precioCrudo + '&PetroDerechosB3=' + precioGas + '&idSession='+idSession ;

//		alert("data");
		$.ajax({
			url: "petroDerechosStata.php",	
			
			async:false,

			//GET method is used
			type: "GET",

			//pass the data			
			data: data,		
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (html) {	
//					alert(html);
				url = "ieps-petrolero.php";
				$(location).attr('href',url);
			
			},
			beforeSend: function () {

			},		
			error: function(request,error) {
				console.log(request);
//				alert ( " Can't do because: " + error +'\n'+html);
			}
		});
		

	});



		/*****************  envio de petroleos derechos 3 ************************/	
	$('#PetroDerechos3Sub').click(function () {		
		var PetroDerechos3_1 = $('#PetroDerechos3_1').val();
		var PetroDerechos3_2 = $('#PetroDerechos3_2').val();
		var PetroDerechos3_3 = $('#PetroDerechos3_3').val();
		var PetroDerechos3_4 = $('#PetroDerechos3_4').val();
		var PetroDerechos3_5 = $('#PetroDerechos3_5').val();
		var PetroDerechos3_6 = $('#PetroDerechos3_6').val();
		var PetroDerechos3_7 = $('#PetroDerechos3_7').val();
		var PetroDerechos3_8 = $('#PetroDerechos3_8').val();
		var PetroDerechos3_9 = $('#PetroDerechos3_9').val();
		var PetroDerechos3_10 = $('#PetroDerechos3_10').val();
		var PetroDerechos3_11 = $('#PetroDerechos3_11').val();
		var PetroDerechos3_12 = $('#PetroDerechos3_12').val();
		var PetroDerechos3_13 = $('#PetroDerechos3_13').val();
		var PetroDerechos3_14 = $('#PetroDerechos3_14').val();
		var PetroDerechos3_15 = $('#PetroDerechos3_15').val();
		var PetroDerechos3_16 = $('#PetroDerechos3_16').val();
		var PetroDerechos3_17 = $('#PetroDerechos3_17').val();
		var PetroDerechos3_18 = $('#PetroDerechos3_18').val();
		var PetroDerechos3_19 = $('#PetroDerechos3_19').val();
		var PetroDerechos3_20 = $('#PetroDerechos3_20').val();
		var si = ($('#si').is(":checked")?1:0);
		
		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);
		
		var data = 'PetroDerechos3_1=' + PetroDerechos3_1 + '&PetroDerechos3_2=' + PetroDerechos3_2 + '&PetroDerechos3_3=' + PetroDerechos3_3 + '&PetroDerechos3_4=' + PetroDerechos3_4 + '&PetroDerechos3_5=' + PetroDerechos3_5 + '&PetroDerechos3_6=' + PetroDerechos3_6 + '&PetroDerechos3_7=' + PetroDerechos3_7 + '&PetroDerechos3_8=' + PetroDerechos3_8 + '&PetroDerechos3_9=' + PetroDerechos3_9 + '&PetroDerechos3_10=' + PetroDerechos3_10 + '&PetroDerechos3_11=' + PetroDerechos3_11 + '&PetroDerechos3_12=' + PetroDerechos3_12 + '&PetroDerechos3_13=' + PetroDerechos3_13 + '&PetroDerechos3_14=' + PetroDerechos3_14 + '&PetroDerechos3_15=' + PetroDerechos3_15 + '&PetroDerechos3_16=' + PetroDerechos3_16 + '&PetroDerechos3_17=' + PetroDerechos3_17 + '&PetroDerechos3_18=' + PetroDerechos3_18 + '&PetroDerechos3_19=' + PetroDerechos3_19 + '&PetroDerechos3_20=' + PetroDerechos3_20 + '&si=' + si + '&idSession='+idSession ;

		$.ajax({
			url: "petroDerechos3Stata.php",	
			
			async:false,

			//GET method is used
			type: "GET",

			//pass the data			
			data: data,		
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (html) {	
		
				$('.loading').css('visibility','hidden');
				$('.loading').hide();

				fechas = eval($(html).find("fecha").text()); 				
				var distribucion = eval($(html).find("distribucion").text());								
				var SHRFSP = eval($(html).find("SHRFSP").text());
				var RFSP = eval($(html).find("RFSP").text());
				var BalanceTrad = eval($(html).find("BalanceTrad").text());
				var IPAB = eval($(html).find("IPAB").text());
				var Adecuaciones = eval($(html).find("Adecuaciones").text());
				var FARAC = eval($(html).find("FARAC").text());
				var Deudores = eval($(html).find("Deudores").text());
				var Banca = eval($(html).find("Banca").text());
				var PIDIREGAS = eval($(html).find("PIDIREGAS").text());				
				Gini = eval($(html).find("Gini").text());				
				Gini=Gini[0];
				
				Ingresos = eval($(html).find("Ingresos").text());				
				Gastos = eval($(html).find("Gastos").text());				
				Deuda = eval($(html).find("Deuda").text());		

				var derechos14 = eval($(html).find("derechos14").text());


				for(var i =0;i<SHRFSP.length;i++) {
					SHRFSP[i]=-1*Number(SHRFSP[i]);
				} 			
				
				actualizaItemtabla("#derHidIRP1",formato(derechos14[0],true));
				actualizaItemtabla("#derHidIRP2",formato(derechos14[1],true));
				actualizaItemtabla("#derHidIRP3",formato(derechos14[2],true));
				actualizaItemtabla("#derHidIRP4",formato(derechos14[3],true));
				actualizaItemtabla("#derHidIRP5",formato(derechos14[4],true));
				actualizaItemtabla("#derHidIRP6",formato(derechos14[5],true));
				actualizaItemtabla("#derHidIRP7",formato(derechos14[6],true));
				actualizaItemtabla("#derHidIRP8",formato(derechos14[7],true));
				actualizaItemtabla("#derHidIRP9",formato(derechos14[8],true));
				actualizaItemtabla("#derHidIRP10",formato(derechos14[9],true));
				actualizaItemtabla("#derHidIRP11",formato(derechos14[10],true));
				actualizaItemtabla("#derHidIRP12",formato(derechos14[11],true));
				
				demoGauge.set(Gini*100); // función del velocimetro cambia valor
				$('.vel-val').text(Gini);
//				$('#recaudacionProyectada').text(formato(reccuotas,true));
	
				$('#recaudacionMPD').text(formato(Ingresos[0],true));
				$('#gastoMPD').text(formato(Gastos[0],true));
				$('#deudaMPD').text(formato(Deuda[0],true));
	
				/******************  Actualizar el gráfico de barras ***********/
				actualizaItemGrafPrima('13',SHRFSP[0],RFSP[0],BalanceTrad[0],IPAB[0],Adecuaciones[0],FARAC[0],Deudores[0],Banca[0],PIDIREGAS[0]);
				actualizaItemGrafPrima('14',SHRFSP[1],RFSP[1],BalanceTrad[1],IPAB[1],Adecuaciones[1],FARAC[1],Deudores[1],Banca[1],PIDIREGAS[1]);
				actualizaItemGrafPrima('15',SHRFSP[2],RFSP[2],BalanceTrad[2],IPAB[2],Adecuaciones[2],FARAC[2],Deudores[2],Banca[2],PIDIREGAS[2]);
				actualizaItemGrafPrima('16',SHRFSP[3],RFSP[3],BalanceTrad[3],IPAB[3],Adecuaciones[3],FARAC[3],Deudores[3],Banca[3],PIDIREGAS[3]);
				actualizaItemGrafPrima('17',SHRFSP[4],RFSP[4],BalanceTrad[4],IPAB[4],Adecuaciones[4],FARAC[4],Deudores[4],Banca[4],PIDIREGAS[4]);
				actualizaItemGrafPrima('18',SHRFSP[5],RFSP[5],BalanceTrad[5],IPAB[5],Adecuaciones[5],FARAC[5],Deudores[5],Banca[5],PIDIREGAS[5]);
				actualizaItemGrafPrima('19',SHRFSP[6],RFSP[6],BalanceTrad[6],IPAB[6],Adecuaciones[6],FARAC[6],Deudores[6],Banca[6],PIDIREGAS[6]);
				actualizaItemGrafPrima('20',SHRFSP[7],RFSP[7],BalanceTrad[7],IPAB[7],Adecuaciones[7],FARAC[7],Deudores[7],Banca[7],PIDIREGAS[7]);
				actualizaItemGrafPrima('21',SHRFSP[8],RFSP[8],BalanceTrad[8],IPAB[8],Adecuaciones[8],FARAC[8],Deudores[8],Banca[8],PIDIREGAS[8]);
				actualizaItemGrafPrima('22',SHRFSP[9],RFSP[9],BalanceTrad[9],IPAB[9],Adecuaciones[9],FARAC[9],Deudores[9],Banca[9],PIDIREGAS[9]);
				actualizaItemGrafPrima('23',SHRFSP[10],RFSP[10],BalanceTrad[10],IPAB[10],Adecuaciones[10],FARAC[10],Deudores[10],Banca[10],PIDIREGAS[10]);
				actualizaItemGrafPrima('24',SHRFSP[11],RFSP[11],BalanceTrad[11],IPAB[11],Adecuaciones[11],FARAC[11],Deudores[11],Banca[11],PIDIREGAS[11]);
				actualizaItemGrafPrima('25',SHRFSP[12],RFSP[12],BalanceTrad[12],IPAB[12],Adecuaciones[12],FARAC[12],Deudores[12],Banca[12],PIDIREGAS[12]);
				positionBars();
				positionBars2();
			
			var ii=0;
			for (i=0;i<fechas.length;i++) {
				ii=i+1;
				recaudacionGasto[i] = eval($(html).find("Lif"+ii).text());
			}
			var year =0;
			var lif = new Array(
				sumatoria(recaudacionGasto[year],0,45), sumatoria(recaudacionGasto[year],0,19),recaudacionGasto[year][0], 
				recaudacionGasto[year][0], recaudacionGasto[year][1],sumatoria(recaudacionGasto[year],2,12), recaudacionGasto[year][2], 
				sumatoria(recaudacionGasto[year],3,12),recaudacionGasto[year][3], recaudacionGasto[year][4], recaudacionGasto[year][5],
				recaudacionGasto[year][6], recaudacionGasto[year][7], recaudacionGasto[year][8], recaudacionGasto[year][9], recaudacionGasto[year][10],
				recaudacionGasto[year][11], recaudacionGasto[year][12], recaudacionGasto[year][13], recaudacionGasto[year][14], recaudacionGasto[year][14],	
				recaudacionGasto[year][15],recaudacionGasto[year][16], recaudacionGasto[year][17],	recaudacionGasto[year][18], recaudacionGasto[year][19],
				recaudacionGasto[year][20], sumatoria(recaudacionGasto[year],21,25), recaudacionGasto[year][21], recaudacionGasto[year][22], 
				recaudacionGasto[year][23], recaudacionGasto[year][24], recaudacionGasto[year][25], recaudacionGasto[year][26], recaudacionGasto[year][26], 
				sumatoria(recaudacionGasto[year],27,32), recaudacionGasto[year][27], recaudacionGasto[year][28], recaudacionGasto[year][29], 
				recaudacionGasto[year][30], recaudacionGasto[year][31], recaudacionGasto[year][32], sumatoria(recaudacionGasto[year],33,35), 
				recaudacionGasto[year][33], recaudacionGasto[year][34], recaudacionGasto[year][35], sumatoria(recaudacionGasto[year],36,37), 
				recaudacionGasto[year][36], recaudacionGasto[year][37], sumatoria(recaudacionGasto[year],38,43), sumatoria(recaudacionGasto[year],38,39),
				recaudacionGasto[year][38], recaudacionGasto[year][39], sumatoria(recaudacionGasto[year],40,42), recaudacionGasto[year][40], 
				recaudacionGasto[year][41], recaudacionGasto[year][42],recaudacionGasto[year][43], recaudacionGasto[year][44], recaudacionGasto[year][45],
				sumatoria(recaudacionGasto[year],0,45)			
				);
			var valores = lif.length;

			for(var i = 0; i< valores;i++) {
				ii=i+1;
				$('.recaudacionGasto'+ii+'-1').text('$ ' +formato(lif[i],true));	
				porcentaje  = lif[i] /Ingresos[year]*100;
				$('.recaudacionGasto'+ii).text( porcentaje.toFixed(2) + '%');	
			}


//				url = "ingresos-propios-pemex.php";
//				$(location).attr('href',url);
			
			},
			beforeSend: function () {

			},		
			error: function(request,error) {
				console.log(arguments);
				console.log(request);
				alert ( " Can't do because: " + error +'\n'+html);
			}
		});
		

	});




		/*****************  envio de pensiones contributivas ************************/	
	$('#pensionesCSub').click(function () {		
		var PensionCIn1 = $('#PensionCIn1').val();
		var PensionCIn2 = $('#PensionCIn2').val();
		var PensionCIn3 = $('#PensionCIn3').val();
		var PensionCIn4 = $('#PensionCIn4').val();
		var PensionCIn5 = $('#PensionCIn5').val();
		var PensionCIn6 = $('#PensionCIn6').val();
		var PensionCIn7 = $('#PensionCIn7').val();


		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);
		
		var data = 'PensionCIn1=' + PensionCIn1 +'&PensionCIn2=' + PensionCIn2+'&PensionCIn3=' + PensionCIn3+'&PensionCIn4=' + PensionCIn4 + '&PensionCIn5=' + PensionCIn5 + '&PensionCIn6=' + PensionCIn6 + '&PensionCIn7=' + PensionCIn7 + '&idSession='+idSession ;

		$.ajax({
			url: "pensionCStata.php",	
			
			async:false,

			//GET method is used
			type: "GET",

			//pass the data			
			data: data,		
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (html) {	
				$('.loading').css('visibility','hidden');
				$('.loading').hide();

				fechas = eval($(html).find("fecha").text()); 				
				var distribucion = eval($(html).find("distribucion").text());								
				var SHRFSP = eval($(html).find("SHRFSP").text());
				var RFSP = eval($(html).find("RFSP").text());
				var BalanceTrad = eval($(html).find("BalanceTrad").text());
				var IPAB = eval($(html).find("IPAB").text());
				var Adecuaciones = eval($(html).find("Adecuaciones").text());
				var FARAC = eval($(html).find("FARAC").text());
				var Deudores = eval($(html).find("Deudores").text());
				var Banca = eval($(html).find("Banca").text());
				var PIDIREGAS = eval($(html).find("PIDIREGAS").text());				
				Gini = eval($(html).find("Gini").text());				
				Gini=Gini[0];
				
				Ingresos = eval($(html).find("Ingresos").text());				
				Gastos = eval($(html).find("Gastos").text());				
				Deuda = eval($(html).find("Deuda").text());		

				var edades = eval($(html).find("edades").text());
				var gaspen = eval($(html).find("gaspen").text());
				var pibpen = eval($(html).find("pibpen").text());

				var pen_pemexhom = eval($(html).find("pen_pemexhom").text());
				var pen_pemexmuj = eval($(html).find("pen_pemexmuj").text());
				var pen_pemex_1 = eval($(html).find("pen_pemex_1").text());
			 
				var pen_imsshom = eval($(html).find("pen_imsshom").text());
				var pen_imssmuj = eval($(html).find("pen_imssmuj").text());
				var pen_imss_1 = eval($(html).find("pen_imss_1").text());
			 
				var pen_ferronaleshom = eval($(html).find("pen_ferronaleshom").text());
				var pen_ferronalesmuj = eval($(html).find("pen_ferronalesmuj").text());
				var pen_ferronales_1 = eval($(html).find("pen_ferronales_1").text());
			 
				var pen_cfehom = eval($(html).find("pen_cfehom").text());
				var pen_cfemuj = eval($(html).find("pen_cfemuj").text());
				var pen_cfe_1 = eval($(html).find("pen_cfe_1").text());
			 
				var pen_lfchom = eval($(html).find("pen_lfchom").text());
				var pen_lfcmuj = eval($(html).find("pen_lfcmuj").text());
				var pen_lfc_1 = eval($(html).find("pen_lfc_1").text());
			 
				var pen_issstehom = eval($(html).find("pen_issstehom").text());
				var pen_issstemuj = eval($(html).find("pen_issstemuj").text());
				var pen_issste_1 = eval($(html).find("pen_issste_1").text());
			 
				var pen_issfamhom = eval($(html).find("pen_issfamhom").text());
				var pen_issfammuj = eval($(html).find("pen_issfammuj").text());
				var pen_issfam_1 = eval($(html).find("pen_issfam_1").text());
			 
				for(var i =0;i<SHRFSP.length;i++) {
					SHRFSP[i]=-1*Number(SHRFSP[i]); 									
				}

				$('#ecuRGD').html('');
				
				for(var i =0;i<Ingresos.length;i++) {
					$("#ecuRGD").append('<option value='+i+'>'+fechas[i]+'</option>');
				}
				

				demoGauge.set(Gini*100); // función del velocimetro cambia valor
				$('.vel-val').text(Gini);
				$('#recaudacionProyectada').text(formato(gaspen,true));
				$('#pibProyectado').text(pibpen);

				var ii=0;
				for(var i=0;i<pen_issfam_1.length;i++) {
					ii=i+1;
					actualizaItemtabla("#pensionesContributivas"+ii,pen_issfam_1[i]);
				}

				$('#recaudacionMPD').text(formato(Ingresos[0],true));
				$('#gastoMPD').text(formato(Gastos[0],true));
				$('#deudaMPD').text(formato(Deuda[0],true));

				/******************  Actualizar el gráfico de barras ***********/
				actualizaItemGrafPrima('13',SHRFSP[0],RFSP[0],BalanceTrad[0],IPAB[0],Adecuaciones[0],FARAC[0],Deudores[0],Banca[0],PIDIREGAS[0]);
				actualizaItemGrafPrima('14',SHRFSP[1],RFSP[1],BalanceTrad[1],IPAB[1],Adecuaciones[1],FARAC[1],Deudores[1],Banca[1],PIDIREGAS[1]);
				actualizaItemGrafPrima('15',SHRFSP[2],RFSP[2],BalanceTrad[2],IPAB[2],Adecuaciones[2],FARAC[2],Deudores[2],Banca[2],PIDIREGAS[2]);
				actualizaItemGrafPrima('16',SHRFSP[3],RFSP[3],BalanceTrad[3],IPAB[3],Adecuaciones[3],FARAC[3],Deudores[3],Banca[3],PIDIREGAS[3]);
				actualizaItemGrafPrima('17',SHRFSP[4],RFSP[4],BalanceTrad[4],IPAB[4],Adecuaciones[4],FARAC[4],Deudores[4],Banca[4],PIDIREGAS[4]);
				actualizaItemGrafPrima('18',SHRFSP[5],RFSP[5],BalanceTrad[5],IPAB[5],Adecuaciones[5],FARAC[5],Deudores[5],Banca[5],PIDIREGAS[5]);
				actualizaItemGrafPrima('19',SHRFSP[6],RFSP[6],BalanceTrad[6],IPAB[6],Adecuaciones[6],FARAC[6],Deudores[6],Banca[6],PIDIREGAS[6]);
				actualizaItemGrafPrima('20',SHRFSP[7],RFSP[7],BalanceTrad[7],IPAB[7],Adecuaciones[7],FARAC[7],Deudores[7],Banca[7],PIDIREGAS[7]);
				actualizaItemGrafPrima('21',SHRFSP[8],RFSP[8],BalanceTrad[8],IPAB[8],Adecuaciones[8],FARAC[8],Deudores[8],Banca[8],PIDIREGAS[8]);
				actualizaItemGrafPrima('22',SHRFSP[9],RFSP[9],BalanceTrad[9],IPAB[9],Adecuaciones[9],FARAC[9],Deudores[9],Banca[9],PIDIREGAS[9]);
				actualizaItemGrafPrima('23',SHRFSP[10],RFSP[10],BalanceTrad[10],IPAB[10],Adecuaciones[10],FARAC[10],Deudores[10],Banca[10],PIDIREGAS[10]);
				actualizaItemGrafPrima('24',SHRFSP[11],RFSP[11],BalanceTrad[11],IPAB[11],Adecuaciones[11],FARAC[11],Deudores[11],Banca[11],PIDIREGAS[11]);
				actualizaItemGrafPrima('25',SHRFSP[12],RFSP[12],BalanceTrad[12],IPAB[12],Adecuaciones[12],FARAC[12],Deudores[12],Banca[12],PIDIREGAS[12]);
				positionBars();
				positionBars2();

			/*************************  Recargar el gráfico de google ********************/
				
				var datas = google.visualization.arrayToDataTable([
				  ['Edades', 'H Pemex', 'M Pemex', 'H IMSS', 'M IMSS', 'H Ferronales', 'M Ferronales', 'H CFE', 'M CFE', 'H LFC', 'M LFC', 'H ISSSTE', 'M ISSSTE', 'H ISSFAM', 'M ISSFAM'],
[edades[0], pen_pemexhom[0], pen_pemexmuj[0], pen_imsshom[0], pen_imssmuj[0], pen_ferronaleshom[0], pen_ferronalesmuj[0], pen_cfehom[0], pen_cfemuj[0], pen_lfchom[0], pen_lfcmuj[0], pen_issstehom[0], pen_issstemuj[0], pen_issfamhom[0], pen_issfammuj[0]],
[edades[1], pen_pemexhom[1], pen_pemexmuj[1], pen_imsshom[1], pen_imssmuj[1], pen_ferronaleshom[1], pen_ferronalesmuj[1], pen_cfehom[1], pen_cfemuj[1], pen_lfchom[1], pen_lfcmuj[1], pen_issstehom[1], pen_issstemuj[1], pen_issfamhom[1], pen_issfammuj[1]],
[edades[2], pen_pemexhom[2], pen_pemexmuj[2], pen_imsshom[2], pen_imssmuj[2], pen_ferronaleshom[2], pen_ferronalesmuj[2], pen_cfehom[2], pen_cfemuj[2], pen_lfchom[2], pen_lfcmuj[2], pen_issstehom[2], pen_issstemuj[2], pen_issfamhom[2], pen_issfammuj[2]],
[edades[3], pen_pemexhom[3], pen_pemexmuj[3], pen_imsshom[3], pen_imssmuj[3], pen_ferronaleshom[3], pen_ferronalesmuj[3], pen_cfehom[3], pen_cfemuj[3], pen_lfchom[3], pen_lfcmuj[3], pen_issstehom[3], pen_issstemuj[3], pen_issfamhom[3], pen_issfammuj[3]],
[edades[4], pen_pemexhom[4], pen_pemexmuj[4], pen_imsshom[4], pen_imssmuj[4], pen_ferronaleshom[4], pen_ferronalesmuj[4], pen_cfehom[4], pen_cfemuj[4], pen_lfchom[4], pen_lfcmuj[4], pen_issstehom[4], pen_issstemuj[4], pen_issfamhom[4], pen_issfammuj[4]],
[edades[5], pen_pemexhom[5], pen_pemexmuj[5], pen_imsshom[5], pen_imssmuj[5], pen_ferronaleshom[5], pen_ferronalesmuj[5], pen_cfehom[5], pen_cfemuj[5], pen_lfchom[5], pen_lfcmuj[5], pen_issstehom[5], pen_issstemuj[5], pen_issfamhom[5], pen_issfammuj[5]],
[edades[6], pen_pemexhom[6], pen_pemexmuj[6], pen_imsshom[6], pen_imssmuj[6], pen_ferronaleshom[6], pen_ferronalesmuj[6], pen_cfehom[6], pen_cfemuj[6], pen_lfchom[6], pen_lfcmuj[6], pen_issstehom[6], pen_issstemuj[6], pen_issfamhom[6], pen_issfammuj[6]],
[edades[7], pen_pemexhom[7], pen_pemexmuj[7], pen_imsshom[7], pen_imssmuj[7], pen_ferronaleshom[7], pen_ferronalesmuj[7], pen_cfehom[7], pen_cfemuj[7], pen_lfchom[7], pen_lfcmuj[7], pen_issstehom[7], pen_issstemuj[7], pen_issfamhom[7], pen_issfammuj[7]],
[edades[8], pen_pemexhom[8], pen_pemexmuj[8], pen_imsshom[8], pen_imssmuj[8], pen_ferronaleshom[8], pen_ferronalesmuj[8], pen_cfehom[8], pen_cfemuj[8], pen_lfchom[8], pen_lfcmuj[8], pen_issstehom[8], pen_issstemuj[8], pen_issfamhom[8], pen_issfammuj[8]],
[edades[9], pen_pemexhom[9], pen_pemexmuj[9], pen_imsshom[9], pen_imssmuj[9], pen_ferronaleshom[9], pen_ferronalesmuj[9], pen_cfehom[9], pen_cfemuj[9], pen_lfchom[9], pen_lfcmuj[9], pen_issstehom[9], pen_issstemuj[9], pen_issfamhom[9], pen_issfammuj[9]],
[edades[10], pen_pemexhom[10], pen_pemexmuj[10], pen_imsshom[10], pen_imssmuj[10], pen_ferronaleshom[10], pen_ferronalesmuj[10], pen_cfehom[10], pen_cfemuj[10], pen_lfchom[10], pen_lfcmuj[10], pen_issstehom[10], pen_issstemuj[10], pen_issfamhom[10], pen_issfammuj[10]],
[edades[11], pen_pemexhom[11], pen_pemexmuj[11], pen_imsshom[11], pen_imssmuj[11], pen_ferronaleshom[11], pen_ferronalesmuj[11], pen_cfehom[11], pen_cfemuj[11], pen_lfchom[11], pen_lfcmuj[11], pen_issstehom[11], pen_issstemuj[11], pen_issfamhom[11], pen_issfammuj[11]],
[edades[12], pen_pemexhom[12], pen_pemexmuj[12], pen_imsshom[12], pen_imssmuj[12], pen_ferronaleshom[12], pen_ferronalesmuj[12], pen_cfehom[12], pen_cfemuj[12], pen_lfchom[12], pen_lfcmuj[12], pen_issstehom[12], pen_issstemuj[12], pen_issfamhom[12], pen_issfammuj[12]],
[edades[13], pen_pemexhom[13], pen_pemexmuj[13], pen_imsshom[13], pen_imssmuj[13], pen_ferronaleshom[13], pen_ferronalesmuj[13], pen_cfehom[13], pen_cfemuj[13], pen_lfchom[13], pen_lfcmuj[13], pen_issstehom[13], pen_issstemuj[13], pen_issfamhom[13], pen_issfammuj[13]],
[edades[14], pen_pemexhom[14], pen_pemexmuj[14], pen_imsshom[14], pen_imssmuj[14], pen_ferronaleshom[14], pen_ferronalesmuj[14], pen_cfehom[14], pen_cfemuj[14], pen_lfchom[14], pen_lfcmuj[14], pen_issstehom[14], pen_issstemuj[14], pen_issfamhom[14], pen_issfammuj[14]],
[edades[15], pen_pemexhom[15], pen_pemexmuj[15], pen_imsshom[15], pen_imssmuj[15], pen_ferronaleshom[15], pen_ferronalesmuj[15], pen_cfehom[15], pen_cfemuj[15], pen_lfchom[15], pen_lfcmuj[15], pen_issstehom[15], pen_issstemuj[15], pen_issfamhom[15], pen_issfammuj[15]],
[edades[16], pen_pemexhom[16], pen_pemexmuj[16], pen_imsshom[16], pen_imssmuj[16], pen_ferronaleshom[16], pen_ferronalesmuj[16], pen_cfehom[16], pen_cfemuj[16], pen_lfchom[16], pen_lfcmuj[16], pen_issstehom[16], pen_issstemuj[16], pen_issfamhom[16], pen_issfammuj[16]],
[edades[17], pen_pemexhom[17], pen_pemexmuj[17], pen_imsshom[17], pen_imssmuj[17], pen_ferronaleshom[17], pen_ferronalesmuj[17], pen_cfehom[17], pen_cfemuj[17], pen_lfchom[17], pen_lfcmuj[17], pen_issstehom[17], pen_issstemuj[17], pen_issfamhom[17], pen_issfammuj[17]],
[edades[18], pen_pemexhom[18], pen_pemexmuj[18], pen_imsshom[18], pen_imssmuj[18], pen_ferronaleshom[18], pen_ferronalesmuj[18], pen_cfehom[18], pen_cfemuj[18], pen_lfchom[18], pen_lfcmuj[18], pen_issstehom[18], pen_issstemuj[18], pen_issfamhom[18], pen_issfammuj[18]],
[edades[19], pen_pemexhom[19], pen_pemexmuj[19], pen_imsshom[19], pen_imssmuj[19], pen_ferronaleshom[19], pen_ferronalesmuj[19], pen_cfehom[19], pen_cfemuj[19], pen_lfchom[19], pen_lfcmuj[19], pen_issstehom[19], pen_issstemuj[19], pen_issfamhom[19], pen_issfammuj[19]]
				]);
				
			var options = {
			  curveType:'function',
			  width: 660, 
			  height: 328,
			  focusTarget: 'category',
			  chartArea:{top:5, bottom:0, width:"68%", height:"78%"},
			  lineWidth: 3,
			  fontSize: 11,
			  colors:['#f5cd30', '#e8a729', '#e48227', '#e99378', '#e66e4c', '#df4f2d', '#7fbfdb', '#328e9b', '#25656f', '#9cde93', '#83ba7b'],
			  tooltip: {textStyle: {fontSize: 13}},
			  hAxis:{title: 'Edades',  titleTextStyle: {color: '#333', fontSize: 13}, textStyle: {color: '#686868'}},
			  vAxis:{title: 'Porcentaje de beneficiarios (%)', titleTextStyle: {color: '#333', fontSize: 13}, textStyle: {color: '#686868'}},
			  legend: {position:'right', alignment:'start', textStyle:{color: '#333', fontSize: 12}}
			};
	
			var chart = new google.visualization.LineChart(document.getElementById('chart_div')); // descomentar si se quiere agregar la grafica
			chart.draw(datas, options);
				
				
			/****************** Fin de carga de grafica google *************************/		

			},
			beforeSend: function () {
				$('.loading').css('visibility','visible');
				$('.loading').show();
				

			},		
			error: function(request,error) {
				console.log(arguments);
				console.log(request);
			}
		});
		

	});



		/*****************  envio de tarifas electricas ************************/	
	$('#tarifasElectricasSub').click(function () {		

		var ElectricasIn1 = ($('#ElectricasIn1_1').is(":checked")?1:2);;
		var ElectricasIn2 = $('#ElectricasIn2').val();
		var ElectricasIn3 = $('#ElectricasIn3').val();
		var ElectricasIn4 = ($('#ElectricasIn4_1').is(":checked")?1:2);;
		var ElectricasIn5 = $('#ElectricasIn5').val();
		var ElectricasIn6 = $('#ElectricasIn6').val();
		var ElectricasIn7 = $('#ElectricasIn7').val();

		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);
		
		var data = 'ElectricasIn1=' + ElectricasIn1 +'&ElectricasIn2=' + ElectricasIn2+'&ElectricasIn3=' + ElectricasIn3+'&ElectricasIn4=' + ElectricasIn4+'&ElectricasIn5=' + ElectricasIn5 + '&ElectricasIn6=' + ElectricasIn6 + '&ElectricasIn7=' + ElectricasIn7 + '&idSession='+idSession ;
//		alert(data);

		$.ajax({
			url: "tarifasElectricasStata.php",	
			
			async:false,

			//GET method is used
			type: "GET",

			//pass the data			
			data: data,		
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (html) {	
				$('.loading').css('visibility','hidden');
				$('.loading').hide();

				fechas = eval($(html).find("fecha").text()); 				
				var distribucion = eval($(html).find("distribucion").text());								
				var SHRFSP = eval($(html).find("SHRFSP").text());
				var RFSP = eval($(html).find("RFSP").text());
				var BalanceTrad = eval($(html).find("BalanceTrad").text());
				var IPAB = eval($(html).find("IPAB").text());
				var Adecuaciones = eval($(html).find("Adecuaciones").text());
				var FARAC = eval($(html).find("FARAC").text());
				var Deudores = eval($(html).find("Deudores").text());
				var Banca = eval($(html).find("Banca").text());
				var PIDIREGAS = eval($(html).find("PIDIREGAS").text());				
				Gini = eval($(html).find("Gini").text());				
				Gini=Gini[0];

				Ingresos = eval($(html).find("Ingresos").text());				
				Gastos = eval($(html).find("Gastos").text());				
				Deuda = eval($(html).find("Deuda").text());		
				var rectarifas = eval($(html).find("rectarifas").text());
				var pibtarifas = eval($(html).find("pibtarifas").text());
				var tarifas_1 = eval($(html).find("tarifas_1").text());
				var tarifas_2 = eval($(html).find("tarifas_2").text());

				for(var i =0;i<SHRFSP.length;i++) {
					SHRFSP[i]=-1*Number(SHRFSP[i]); 									
				}

				$('#ecuRGD').html('');
				
				for(var i =0;i<Ingresos.length;i++) {
					$("#ecuRGD").append('<option value='+i+'>'+fechas[i]+'</option>');
				}
				

				demoGauge.set(Gini*100); // función del velocimetro cambia valor
				$('.vel-val').text(Gini);
				$('#recaudacionProyectada').text(formato(rectarifas,true));
				$('#pibProyectado').text(pibtarifas);


				for(var i=0;i<tarifas_1.length;i++) {
					actualizaItemtabla("#distribucion"+i,formato(tarifas_1[i],true));
					actualizaItemtablaString("#tarifasElectricas"+i,tarifas_2[i], " %");
				}

				$('#recaudacionMPD').text(formato(Ingresos[0],true));
				$('#gastoMPD').text(formato(Gastos[0],true));
				$('#deudaMPD').text(formato(Deuda[0],true));

				/******************  Actualizar el gráfico de barras ***********/
			
				actualizaItemGrafPrima('13',SHRFSP[0],RFSP[0],BalanceTrad[0],IPAB[0],Adecuaciones[0],FARAC[0],Deudores[0],Banca[0],PIDIREGAS[0]);
				actualizaItemGrafPrima('14',SHRFSP[1],RFSP[1],BalanceTrad[1],IPAB[1],Adecuaciones[1],FARAC[1],Deudores[1],Banca[1],PIDIREGAS[1]);
				actualizaItemGrafPrima('15',SHRFSP[2],RFSP[2],BalanceTrad[2],IPAB[2],Adecuaciones[2],FARAC[2],Deudores[2],Banca[2],PIDIREGAS[2]);
				actualizaItemGrafPrima('16',SHRFSP[3],RFSP[3],BalanceTrad[3],IPAB[3],Adecuaciones[3],FARAC[3],Deudores[3],Banca[3],PIDIREGAS[3]);
				actualizaItemGrafPrima('17',SHRFSP[4],RFSP[4],BalanceTrad[4],IPAB[4],Adecuaciones[4],FARAC[4],Deudores[4],Banca[4],PIDIREGAS[4]);
				actualizaItemGrafPrima('18',SHRFSP[5],RFSP[5],BalanceTrad[5],IPAB[5],Adecuaciones[5],FARAC[5],Deudores[5],Banca[5],PIDIREGAS[5]);
				actualizaItemGrafPrima('19',SHRFSP[6],RFSP[6],BalanceTrad[6],IPAB[6],Adecuaciones[6],FARAC[6],Deudores[6],Banca[6],PIDIREGAS[6]);
				actualizaItemGrafPrima('20',SHRFSP[7],RFSP[7],BalanceTrad[7],IPAB[7],Adecuaciones[7],FARAC[7],Deudores[7],Banca[7],PIDIREGAS[7]);
				actualizaItemGrafPrima('21',SHRFSP[8],RFSP[8],BalanceTrad[8],IPAB[8],Adecuaciones[8],FARAC[8],Deudores[8],Banca[8],PIDIREGAS[8]);
				actualizaItemGrafPrima('22',SHRFSP[9],RFSP[9],BalanceTrad[9],IPAB[9],Adecuaciones[9],FARAC[9],Deudores[9],Banca[9],PIDIREGAS[9]);
				actualizaItemGrafPrima('23',SHRFSP[10],RFSP[10],BalanceTrad[10],IPAB[10],Adecuaciones[10],FARAC[10],Deudores[10],Banca[10],PIDIREGAS[10]);
				actualizaItemGrafPrima('24',SHRFSP[11],RFSP[11],BalanceTrad[11],IPAB[11],Adecuaciones[11],FARAC[11],Deudores[11],Banca[11],PIDIREGAS[11]);
				actualizaItemGrafPrima('25',SHRFSP[12],RFSP[12],BalanceTrad[12],IPAB[12],Adecuaciones[12],FARAC[12],Deudores[12],Banca[12],PIDIREGAS[12]);
				positionBars();
				positionBars2();

			/*************************  Recargar el gráfico de google ********************/
				

			var ii=0;
			for (i=0;i<fechas.length;i++) {
				ii=i+1;
				recaudacionGasto[i] = eval($(html).find("Lif"+ii).text());
			}
			var year =0;
			var lif = new Array(
				sumatoria(recaudacionGasto[year],0,45), sumatoria(recaudacionGasto[year],0,19),recaudacionGasto[year][0], 
				recaudacionGasto[year][0], recaudacionGasto[year][1],sumatoria(recaudacionGasto[year],2,12), recaudacionGasto[year][2], 
				sumatoria(recaudacionGasto[year],3,12),recaudacionGasto[year][3], recaudacionGasto[year][4], recaudacionGasto[year][5],
				recaudacionGasto[year][6], recaudacionGasto[year][7], recaudacionGasto[year][8], recaudacionGasto[year][9], recaudacionGasto[year][10],
				recaudacionGasto[year][11], recaudacionGasto[year][12], recaudacionGasto[year][13], recaudacionGasto[year][14], recaudacionGasto[year][14],	
				recaudacionGasto[year][15],recaudacionGasto[year][16], recaudacionGasto[year][17],	recaudacionGasto[year][18], recaudacionGasto[year][19],
				recaudacionGasto[year][20], sumatoria(recaudacionGasto[year],21,25), recaudacionGasto[year][21], recaudacionGasto[year][22], 
				recaudacionGasto[year][23], recaudacionGasto[year][24], recaudacionGasto[year][25], recaudacionGasto[year][26], recaudacionGasto[year][26], 
				sumatoria(recaudacionGasto[year],27,32), recaudacionGasto[year][27], recaudacionGasto[year][28], recaudacionGasto[year][29], 
				recaudacionGasto[year][30], recaudacionGasto[year][31], recaudacionGasto[year][32], sumatoria(recaudacionGasto[year],33,35), 
				recaudacionGasto[year][33], recaudacionGasto[year][34], recaudacionGasto[year][35], sumatoria(recaudacionGasto[year],36,37), 
				recaudacionGasto[year][36], recaudacionGasto[year][37], sumatoria(recaudacionGasto[year],38,43), sumatoria(recaudacionGasto[year],38,39),
				recaudacionGasto[year][38], recaudacionGasto[year][39], sumatoria(recaudacionGasto[year],40,42), recaudacionGasto[year][40], 
				recaudacionGasto[year][41], recaudacionGasto[year][42],recaudacionGasto[year][43], recaudacionGasto[year][44], recaudacionGasto[year][45],
				sumatoria(recaudacionGasto[year],0,45)			
				);
			var valores = lif.length;

			for(var i = 0; i< valores;i++) {
				ii=i+1;
				$('.recaudacionGasto'+ii+'-1').text('$ ' +formato(lif[i],true));	
				porcentaje  = lif[i] /Ingresos[year]*100;
				$('.recaudacionGasto'+ii).text( porcentaje.toFixed(2) + '%');	
			}
				
				
			/****************** Fin de carga de grafica google *************************/		

			},
			beforeSend: function () {
				$('.loading').css('visibility','visible');
				$('.loading').show();
				

			},		
			error: function(request,error) {
				console.log(arguments);
				console.log(request);
				alert ( " Can't do because: " + error +'\n'+html);
			}
			
		});
		

	});




		/*****************  envio de ieps e iva petrolero ************************/	
	$('#PetroDerechosSub').click(function () {		
		var IEPSPetrolero1 = $('#IEPSPetrolero1').val();
		var IEPSPetrolero2 = $('#IEPSPetrolero2').val();
		var IEPSPetrolero3 = $('#IEPSPetrolero3').val();
		var IEPSPetrolero4 = $('#IEPSPetrolero4').val();
		var IEPSPetrolero5 = $('#IEPSPetrolero5').val();
		var IEPSPetrolero6 = $('#IEPSPetrolero6').val();
		var IEPSPetrolero7 = 1;

		if($('#IEPSPetrolero7_2').is(":checked"))
			IEPSPetrolero7 =2;
		if($('#IEPSPetrolero7_3').is(":checked"))
			IEPSPetrolero7 =3;
		var si = ($('#si').is(":checked")?1:0);

		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);
		
		var data = 'IEPSPetrolero1=' + IEPSPetrolero1 +'&IEPSPetrolero2=' + IEPSPetrolero2+'&IEPSPetrolero3=' + IEPSPetrolero3+'&IEPSPetrolero4=' + IEPSPetrolero4+'&IEPSPetrolero5=' + IEPSPetrolero5+'&IEPSPetrolero6=' + IEPSPetrolero6+'&IEPSPetrolero7=' + IEPSPetrolero7 + '&si=' + si + '&idSession='+idSession ;

		$.ajax({
			url: "iepsPetroleroStata.php",	
			
			async:false,

			//GET method is used
			type: "GET",

			//pass the data			
			data: data,		
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (html) {	
				$('.loading').css('visibility','hidden');
				$('.loading').hide();

				fechas = eval($(html).find("fecha").text()); 				
				var distribucion = eval($(html).find("distribucion").text());								
				var SHRFSP = eval($(html).find("SHRFSP").text());
				var RFSP = eval($(html).find("RFSP").text());
				var BalanceTrad = eval($(html).find("BalanceTrad").text());
				var IPAB = eval($(html).find("IPAB").text());
				var Adecuaciones = eval($(html).find("Adecuaciones").text());
				var FARAC = eval($(html).find("FARAC").text());
				var Deudores = eval($(html).find("Deudores").text());
				var Banca = eval($(html).find("Banca").text());
				var PIDIREGAS = eval($(html).find("PIDIREGAS").text());				
				Gini = eval($(html).find("Gini").text());				
				Gini=Gini[0];

				Ingresos = eval($(html).find("Ingresos").text());				
				Gastos = eval($(html).find("Gastos").text());				
				Deuda = eval($(html).find("Deuda").text());		
				var iepsp_1 = eval($(html).find("iepsp_1").text());
				var iepsp_2 = eval($(html).find("iepsp_2").text());
				var iepsp_3 = eval($(html).find("iepsp_3").text());
				var reciepsp1 = eval($(html).find("reciepsp1").text());
				var reciepsp2 = eval($(html).find("reciepsp2").text());
				var reciepsp3 = eval($(html).find("reciepsp3").text());
				var reciepsp1_1 = eval($(html).find("reciepsp1_1").text());
				var reciepsp2_1 = eval($(html).find("reciepsp2_1").text());
				var reciepsp3_1 = eval($(html).find("reciepsp3_1").text());

				actualizaItemtabla("#iepspRec1",formato(reciepsp1,true));
				actualizaItemtabla("#iepspRec2",formato(reciepsp2,true));
				actualizaItemtabla("#iepspRec3",formato(reciepsp3,true));
				actualizaItemtablaString("#iepspRec_1",reciepsp1_1," %");
				actualizaItemtablaString("#iepspRec_2",reciepsp2_1," %");
				actualizaItemtablaString("#iepspRec_3",reciepsp3_1," %");

				actualizaItemtabla("#recaudacionProyectada",formato(Number(reciepsp1)+Number(reciepsp2)+Number(reciepsp3),true));
				var t = Number(reciepsp1_1)+Number(reciepsp2_1)+Number(reciepsp3_1);
				actualizaItemtablaString("#recaudacionProyectadaPorcentaje",t.toFixed(2) ," %");
				 
				for(var i =0;i<SHRFSP.length;i++) {
					SHRFSP[i]=-1*Number(SHRFSP[i]); 									
				}

				$('#ecuRGD').html('');
				
				for(var i =0;i<Ingresos.length;i++) {
					$("#ecuRGD").append('<option value='+i+'>'+fechas[i]+'</option>');
				}
				

				demoGauge.set(Gini*100); // función del velocimetro cambia valor
				$('.vel-val').text(Gini);
//				$('#recaudacionProyectada').text(formato(gasSalud,true));

				var ii=0;
				for(var i=0;i<iepsp_1.length;i++) {
					ii=i+1;
					actualizaItemtabla("#iepsp_1_"+ii,iepsp_1[i]);
					actualizaItemtabla("#iepsp_2_"+ii,iepsp_2[i]);
					actualizaItemtabla("#iepsp_3_"+ii,iepsp_3[i]);
				}

				$('#recaudacionMPD').text(formato(Ingresos[0],true));
				$('#gastoMPD').text(formato(Gastos[0],true));
				$('#deudaMPD').text(formato(Deuda[0],true));

				/******************  Actualizar el gráfico de barras ***********/
				actualizaItemGrafPrima('13',SHRFSP[0],RFSP[0],BalanceTrad[0],IPAB[0],Adecuaciones[0],FARAC[0],Deudores[0],Banca[0],PIDIREGAS[0]);
				actualizaItemGrafPrima('14',SHRFSP[1],RFSP[1],BalanceTrad[1],IPAB[1],Adecuaciones[1],FARAC[1],Deudores[1],Banca[1],PIDIREGAS[1]);
				actualizaItemGrafPrima('15',SHRFSP[2],RFSP[2],BalanceTrad[2],IPAB[2],Adecuaciones[2],FARAC[2],Deudores[2],Banca[2],PIDIREGAS[2]);
				actualizaItemGrafPrima('16',SHRFSP[3],RFSP[3],BalanceTrad[3],IPAB[3],Adecuaciones[3],FARAC[3],Deudores[3],Banca[3],PIDIREGAS[3]);
				actualizaItemGrafPrima('17',SHRFSP[4],RFSP[4],BalanceTrad[4],IPAB[4],Adecuaciones[4],FARAC[4],Deudores[4],Banca[4],PIDIREGAS[4]);
				actualizaItemGrafPrima('18',SHRFSP[5],RFSP[5],BalanceTrad[5],IPAB[5],Adecuaciones[5],FARAC[5],Deudores[5],Banca[5],PIDIREGAS[5]);
				actualizaItemGrafPrima('19',SHRFSP[6],RFSP[6],BalanceTrad[6],IPAB[6],Adecuaciones[6],FARAC[6],Deudores[6],Banca[6],PIDIREGAS[6]);
				actualizaItemGrafPrima('20',SHRFSP[7],RFSP[7],BalanceTrad[7],IPAB[7],Adecuaciones[7],FARAC[7],Deudores[7],Banca[7],PIDIREGAS[7]);
				actualizaItemGrafPrima('21',SHRFSP[8],RFSP[8],BalanceTrad[8],IPAB[8],Adecuaciones[8],FARAC[8],Deudores[8],Banca[8],PIDIREGAS[8]);
				actualizaItemGrafPrima('22',SHRFSP[9],RFSP[9],BalanceTrad[9],IPAB[9],Adecuaciones[9],FARAC[9],Deudores[9],Banca[9],PIDIREGAS[9]);
				actualizaItemGrafPrima('23',SHRFSP[10],RFSP[10],BalanceTrad[10],IPAB[10],Adecuaciones[10],FARAC[10],Deudores[10],Banca[10],PIDIREGAS[10]);
				actualizaItemGrafPrima('24',SHRFSP[11],RFSP[11],BalanceTrad[11],IPAB[11],Adecuaciones[11],FARAC[11],Deudores[11],Banca[11],PIDIREGAS[11]);
				actualizaItemGrafPrima('25',SHRFSP[12],RFSP[12],BalanceTrad[12],IPAB[12],Adecuaciones[12],FARAC[12],Deudores[12],Banca[12],PIDIREGAS[12]);
				positionBars();
				positionBars2();
 

					/*************************  Recargar el gráfico de google ********************/

			var ii=0;
			for (i=0;i<fechas.length;i++) {
				ii=i+1;
				recaudacionGasto[i] = eval($(html).find("Lif"+ii).text());
			}
			var year =0;
			var lif = new Array(
				sumatoria(recaudacionGasto[year],0,45), sumatoria(recaudacionGasto[year],0,19),recaudacionGasto[year][0], 
				recaudacionGasto[year][0], recaudacionGasto[year][1],sumatoria(recaudacionGasto[year],2,12), recaudacionGasto[year][2], 
				sumatoria(recaudacionGasto[year],3,12),recaudacionGasto[year][3], recaudacionGasto[year][4], recaudacionGasto[year][5],
				recaudacionGasto[year][6], recaudacionGasto[year][7], recaudacionGasto[year][8], recaudacionGasto[year][9], recaudacionGasto[year][10],
				recaudacionGasto[year][11], recaudacionGasto[year][12], recaudacionGasto[year][13], recaudacionGasto[year][14], recaudacionGasto[year][14],	
				recaudacionGasto[year][15],recaudacionGasto[year][16], recaudacionGasto[year][17],	recaudacionGasto[year][18], recaudacionGasto[year][19],
				recaudacionGasto[year][20], sumatoria(recaudacionGasto[year],21,25), recaudacionGasto[year][21], recaudacionGasto[year][22], 
				recaudacionGasto[year][23], recaudacionGasto[year][24], recaudacionGasto[year][25], recaudacionGasto[year][26], recaudacionGasto[year][26], 
				sumatoria(recaudacionGasto[year],27,32), recaudacionGasto[year][27], recaudacionGasto[year][28], recaudacionGasto[year][29], 
				recaudacionGasto[year][30], recaudacionGasto[year][31], recaudacionGasto[year][32], sumatoria(recaudacionGasto[year],33,35), 
				recaudacionGasto[year][33], recaudacionGasto[year][34], recaudacionGasto[year][35], sumatoria(recaudacionGasto[year],36,37), 
				recaudacionGasto[year][36], recaudacionGasto[year][37], sumatoria(recaudacionGasto[year],38,43), sumatoria(recaudacionGasto[year],38,39),
				recaudacionGasto[year][38], recaudacionGasto[year][39], sumatoria(recaudacionGasto[year],40,42), recaudacionGasto[year][40], 
				recaudacionGasto[year][41], recaudacionGasto[year][42],recaudacionGasto[year][43], recaudacionGasto[year][44], recaudacionGasto[year][45],
				sumatoria(recaudacionGasto[year],0,45)			
				);
			var valores = lif.length;

			for(var i = 0; i< valores;i++) {
				ii=i+1;
				$('.recaudacionGasto'+ii+'-1').text('$ ' +formato(lif[i],true));	
				porcentaje  = lif[i] /Ingresos[year]*100;
				$('.recaudacionGasto'+ii).text( porcentaje.toFixed(2) + '%');	
			}
				

	
			/****************** Fin de carga de grafica google *************************/		

			},
			beforeSend: function () {
				$('.loading').css('visibility','visible');
				$('.loading').show();
				

			},		
			error: function(request,error) {
				console.log(arguments);
				console.log(request);
				alert ( " Can't do because: " + error +'\n'+html);
			}
		});
		

	});



		/*****************  envio de salud ************************/	
	$('#saludSub').click(function () {		
		var saludA1 = $('#saludA1').val();
		var saludA2 = $('#saludA2').val();
		var saludA3 = $('#saludA3').val();

		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);
		
		var data = 'saludA1=' + saludA1 +'&saludA2=' + saludA2+'&saludA3=' + saludA3  +'&idSession='+idSession ;

		$.ajax({
			url: "saludStata.php",	
			
			async:false,

			//GET method is used
			type: "GET",

			//pass the data			
			data: data,		
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (html) {	
				$('.loading').css('visibility','hidden');
				$('.loading').hide();

				fechas = eval($(html).find("fecha").text()); 				
				var distribucion = eval($(html).find("distribucion").text());								
				var SHRFSP = eval($(html).find("SHRFSP").text());
				var RFSP = eval($(html).find("RFSP").text());
				var BalanceTrad = eval($(html).find("BalanceTrad").text());
				var IPAB = eval($(html).find("IPAB").text());
				var Adecuaciones = eval($(html).find("Adecuaciones").text());
				var FARAC = eval($(html).find("FARAC").text());
				var Deudores = eval($(html).find("Deudores").text());
				var Banca = eval($(html).find("Banca").text());
				var PIDIREGAS = eval($(html).find("PIDIREGAS").text());				
				Gini = eval($(html).find("Gini").text());				
				Gini=Gini[0];

				Ingresos = eval($(html).find("Ingresos").text());				
				Gastos = eval($(html).find("Gastos").text());				
				Deuda = eval($(html).find("Deuda").text());		
	
				var edades = eval($(html).find("edades").text());
				var saludhom = eval($(html).find("saludhom").text());
				var saludmuj = eval($(html).find("saludmuj").text());
				var saludcss = eval($(html).find("saludcss").text());
				var reccss = eval($(html).find("reccss").text());
				var pibcss = eval($(html).find("pibcss").text());
				var saludssshom = eval($(html).find("saludssshom").text());
				var saludsssmuj = eval($(html).find("saludsssmuj").text());
				var saludsss = eval($(html).find("saludsss").text());
				var recsss = eval($(html).find("recsss").text());
				var pibsss = eval($(html).find("pibsss").text());
				var gasSalud = Number(reccss) + Number(recsss) ;
				var pibSalud = Number(pibcss) + Number(pibsss) ;
//				var gasSalud = Number(recsss) ;
				 
				for(var i =0;i<SHRFSP.length;i++) {
					SHRFSP[i]=-1*Number(SHRFSP[i]); 									
				}

				$('#ecuRGD').html('');
				
				for(var i =0;i<Ingresos.length;i++) {
					$("#ecuRGD").append('<option value='+i+'>'+fechas[i]+'</option>');
				}
				

				demoGauge.set(Gini*100); // función del velocimetro cambia valor
				$('.vel-val').text(Gini);
				$('#recaudacionProyectada').text(formato(gasSalud,true));
				$('#pibProyectado').text(pibSalud);

				var ii=0;
				for(var i=0;i<saludcss.length;i++) {
					ii=i+1;
					actualizaItemtablaString("#saludConSS"+ii,saludcss[i]," %");
					actualizaItemtablaString("#saludSinSS"+ii,saludsss[i]," %");
				}

				$('#recaudacionMPD').text(formato(Ingresos[0],true));
				$('#gastoMPD').text(formato(Gastos[0],true));
				$('#deudaMPD').text(formato(Deuda[0],true));

				/******************  Actualizar el gráfico de barras ***********/
				actualizaItemGrafPrima('13',SHRFSP[0],RFSP[0],BalanceTrad[0],IPAB[0],Adecuaciones[0],FARAC[0],Deudores[0],Banca[0],PIDIREGAS[0]);
				actualizaItemGrafPrima('14',SHRFSP[1],RFSP[1],BalanceTrad[1],IPAB[1],Adecuaciones[1],FARAC[1],Deudores[1],Banca[1],PIDIREGAS[1]);
				actualizaItemGrafPrima('15',SHRFSP[2],RFSP[2],BalanceTrad[2],IPAB[2],Adecuaciones[2],FARAC[2],Deudores[2],Banca[2],PIDIREGAS[2]);
				actualizaItemGrafPrima('16',SHRFSP[3],RFSP[3],BalanceTrad[3],IPAB[3],Adecuaciones[3],FARAC[3],Deudores[3],Banca[3],PIDIREGAS[3]);
				actualizaItemGrafPrima('17',SHRFSP[4],RFSP[4],BalanceTrad[4],IPAB[4],Adecuaciones[4],FARAC[4],Deudores[4],Banca[4],PIDIREGAS[4]);
				actualizaItemGrafPrima('18',SHRFSP[5],RFSP[5],BalanceTrad[5],IPAB[5],Adecuaciones[5],FARAC[5],Deudores[5],Banca[5],PIDIREGAS[5]);
				actualizaItemGrafPrima('19',SHRFSP[6],RFSP[6],BalanceTrad[6],IPAB[6],Adecuaciones[6],FARAC[6],Deudores[6],Banca[6],PIDIREGAS[6]);
				actualizaItemGrafPrima('20',SHRFSP[7],RFSP[7],BalanceTrad[7],IPAB[7],Adecuaciones[7],FARAC[7],Deudores[7],Banca[7],PIDIREGAS[7]);
				actualizaItemGrafPrima('21',SHRFSP[8],RFSP[8],BalanceTrad[8],IPAB[8],Adecuaciones[8],FARAC[8],Deudores[8],Banca[8],PIDIREGAS[8]);
				actualizaItemGrafPrima('22',SHRFSP[9],RFSP[9],BalanceTrad[9],IPAB[9],Adecuaciones[9],FARAC[9],Deudores[9],Banca[9],PIDIREGAS[9]);
				actualizaItemGrafPrima('23',SHRFSP[10],RFSP[10],BalanceTrad[10],IPAB[10],Adecuaciones[10],FARAC[10],Deudores[10],Banca[10],PIDIREGAS[10]);
				actualizaItemGrafPrima('24',SHRFSP[11],RFSP[11],BalanceTrad[11],IPAB[11],Adecuaciones[11],FARAC[11],Deudores[11],Banca[11],PIDIREGAS[11]);
				actualizaItemGrafPrima('25',SHRFSP[12],RFSP[12],BalanceTrad[12],IPAB[12],Adecuaciones[12],FARAC[12],Deudores[12],Banca[12],PIDIREGAS[12]);
				positionBars();
				positionBars2();

					/*************************  Recargar el gráfico de google ********************/

				var datas = google.visualization.arrayToDataTable([
				  ['Edades', 'H Salud', 'M Salud', 'H Salud', 'M Salud'],
					[edades[0], saludhom[0], saludmuj[0], saludssshom[0], saludsssmuj[0]],
					[edades[1], saludhom[1], saludmuj[1], saludssshom[1], saludsssmuj[1]],
					[edades[2], saludhom[2], saludmuj[2], saludssshom[2], saludsssmuj[2]],
					[edades[3], saludhom[3], saludmuj[3], saludssshom[3], saludsssmuj[3]],
					[edades[4], saludhom[4], saludmuj[4], saludssshom[4], saludsssmuj[4]],
					[edades[5], saludhom[5], saludmuj[5], saludssshom[5], saludsssmuj[5]],
					[edades[6], saludhom[6], saludmuj[6], saludssshom[6], saludsssmuj[6]],
					[edades[7], saludhom[7], saludmuj[7], saludssshom[7], saludsssmuj[7]],
					[edades[8], saludhom[8], saludmuj[8], saludssshom[8], saludsssmuj[8]],
					[edades[9], saludhom[9], saludmuj[9], saludssshom[9], saludsssmuj[9]],
					[edades[10], saludhom[10], saludmuj[10], saludssshom[10], saludsssmuj[10]],
					[edades[11], saludhom[11], saludmuj[11], saludssshom[11], saludsssmuj[11]],
					[edades[12], saludhom[12], saludmuj[12], saludssshom[12], saludsssmuj[12]],
					[edades[13], saludhom[13], saludmuj[13], saludssshom[13], saludsssmuj[13]],
					[edades[14], saludhom[14], saludmuj[14], saludssshom[14], saludsssmuj[14]],
					[edades[15], saludhom[15], saludmuj[15], saludssshom[15], saludsssmuj[15]],
					[edades[16], saludhom[16], saludmuj[16], saludssshom[16], saludsssmuj[16]],
					[edades[17], saludhom[17], saludmuj[17], saludssshom[17], saludsssmuj[17]],
					[edades[18], saludhom[18], saludmuj[18], saludssshom[18], saludsssmuj[18]],
					[edades[19], saludhom[19], saludmuj[19], saludssshom[19], saludsssmuj[19]]
				]);
				
			var options = {
			  curveType:'function',
			  width: 660, 
			  height: 328,
			  focusTarget: 'category',
			  chartArea:{top:5, bottom:0, width:"68%", height:"78%"},
			  lineWidth: 3,
			  fontSize: 11,
			  colors:['#38919c', '#fc782d','#38919c', '#fc782d'],
			  tooltip: {textStyle: {fontSize: 13}},
			  hAxis:{title: 'Edades',  titleTextStyle: {color: '#333', fontSize: 13}, textStyle: {color: '#686868'}},
			  vAxis:{title: 'Porcentaje de beneficiarios (%)', titleTextStyle: {color: '#333', fontSize: 13}, textStyle: {color: '#686868'}},
			  legend: {position:'right', alignment:'start', textStyle:{color: '#333', fontSize: 12}}
			};
	
//			var chart = new google.visualization.LineChart(document.getElementById('chart_div')); // descomentar si se quiere agregar la grafica
//			chart.draw(datas, options);
				
				
				
			/****************** Fin de carga de grafica google *************************/		

			},
			beforeSend: function () {
				$('.loading').css('visibility','visible');
				$('.loading').show();
				

			},		
			error: function(request,error) {
				console.log(arguments);
				console.log(request);
				alert ( " Can't do because: " + error +'\n'+html);
			}
		});
		

	});


		/*****************  envio de ietu ************************/	
	$('#ietuSub').click(function () {		
		var ietuA1 = $('#ietuA1').val();
		var ietuA2 = $('#ietuA2').val();
		var ietuA3 = $('#ietuA3').val();
		var ietuA4 = $('#ietuA4').val();
		var ietuA5 = $('#ietuA5').val();

		var ietuB1 = ($('#ietuB1').is(":checked")?1:0);
		var ietuB2 = ($('#ietuB2').is(":checked")?1:0);
		var ietuB3 = ($('#ietuB3').is(":checked")?1:0);
		var ietuB4 = ($('#ietuB4').is(":checked")?1:0);
		var si = ($('#si').is(":checked")?1:0);

		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);
		
		var data = 'ietuA1=' + ietuA1 +'&ietuA2=' + ietuA2+'&ietuA3=' + ietuA3 +'&ietuA4=' + ietuA4 +'&ietuA5=' + ietuA5 +'&ietuB1=' + ietuB1 +'&ietuB2=' + ietuB2 +'&ietuB3=' + ietuB3 +'&ietuB4=' + ietuB4 +'&si=' + si +'&idSession='+idSession ;

		$.ajax({
			url: "ietuStata.php",	
			
			async:false,

			//GET method is used
			type: "GET",

			//pass the data			
			data: data,		
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (html) {	
				$('.loading').css('visibility','hidden');
				$('.loading').hide();
					
				fechas = eval($(html).find("fecha").text()); 				
				var distribucion = eval($(html).find("distribucion").text());								
				var SHRFSP = eval($(html).find("SHRFSP").text());
				var RFSP = eval($(html).find("RFSP").text());
				var BalanceTrad = eval($(html).find("BalanceTrad").text());
				var IPAB = eval($(html).find("IPAB").text());
				var Adecuaciones = eval($(html).find("Adecuaciones").text());
				var FARAC = eval($(html).find("FARAC").text());
				var Deudores = eval($(html).find("Deudores").text());
				var Banca = eval($(html).find("Banca").text());
				var PIDIREGAS = eval($(html).find("PIDIREGAS").text());				
				Gini = eval($(html).find("Gini").text());				
				Gini=Gini[0];

				Ingresos = eval($(html).find("Ingresos").text());				
				Gastos = eval($(html).find("Gastos").text());				
				Deuda = eval($(html).find("Deuda").text());				
				var recietu = eval($(html).find("recietu").text());
				var pibietu = eval($(html).find("pibietu").text());

				var ietusec = eval($(html).find("ietusec").text());
				var ietusecdis = eval($(html).find("ietusecdis").text());
				
				
				 
				for(var i =0;i<SHRFSP.length;i++) {
					SHRFSP[i]=-1*Number(SHRFSP[i]); 									
				}

				$('#ecuRGD').html('');
				
				for(var i =0;i<Ingresos.length;i++) {
					$("#ecuRGD").append('<option value='+i+'>'+fechas[i]+'</option>');
				}
				

				$('#recaudacionMPD').text(formato(Ingresos[0],true));
				$('#gastoMPD').text(formato(Gastos[0],true));
				$('#deudaMPD').text(formato(Deuda[0],true));
				demoGauge.set(Gini*100); // función del velocimetro cambia valor
				$('.vel-val').text(Gini);
				$('#recaudacionProyectada').text(formato(recietu,true));
				$('#pibProyectado').text(pibietu);

				var ii=0;
				for(var i=0;i<ietusecdis.length;i++) {
					ii=i+1;
					actualizaItemtablaString("#ietuIncidenciasR"+ii,ietusecdis[i]," %");
					actualizaItemtabla("#ietuIncidenciasD"+ii,formato(ietusec[i],true));
				}

				
				actualizaItemGrafPrima('13',SHRFSP[0],RFSP[0],BalanceTrad[0],IPAB[0],Adecuaciones[0],FARAC[0],Deudores[0],Banca[0],PIDIREGAS[0]);
				actualizaItemGrafPrima('14',SHRFSP[1],RFSP[1],BalanceTrad[1],IPAB[1],Adecuaciones[1],FARAC[1],Deudores[1],Banca[1],PIDIREGAS[1]);
				actualizaItemGrafPrima('15',SHRFSP[2],RFSP[2],BalanceTrad[2],IPAB[2],Adecuaciones[2],FARAC[2],Deudores[2],Banca[2],PIDIREGAS[2]);
				actualizaItemGrafPrima('16',SHRFSP[3],RFSP[3],BalanceTrad[3],IPAB[3],Adecuaciones[3],FARAC[3],Deudores[3],Banca[3],PIDIREGAS[3]);
				actualizaItemGrafPrima('17',SHRFSP[4],RFSP[4],BalanceTrad[4],IPAB[4],Adecuaciones[4],FARAC[4],Deudores[4],Banca[4],PIDIREGAS[4]);
				actualizaItemGrafPrima('18',SHRFSP[5],RFSP[5],BalanceTrad[5],IPAB[5],Adecuaciones[5],FARAC[5],Deudores[5],Banca[5],PIDIREGAS[5]);
				actualizaItemGrafPrima('19',SHRFSP[6],RFSP[6],BalanceTrad[6],IPAB[6],Adecuaciones[6],FARAC[6],Deudores[6],Banca[6],PIDIREGAS[6]);
				actualizaItemGrafPrima('20',SHRFSP[7],RFSP[7],BalanceTrad[7],IPAB[7],Adecuaciones[7],FARAC[7],Deudores[7],Banca[7],PIDIREGAS[7]);
				actualizaItemGrafPrima('21',SHRFSP[8],RFSP[8],BalanceTrad[8],IPAB[8],Adecuaciones[8],FARAC[8],Deudores[8],Banca[8],PIDIREGAS[8]);
				actualizaItemGrafPrima('22',SHRFSP[9],RFSP[9],BalanceTrad[9],IPAB[9],Adecuaciones[9],FARAC[9],Deudores[9],Banca[9],PIDIREGAS[9]);
				actualizaItemGrafPrima('23',SHRFSP[10],RFSP[10],BalanceTrad[10],IPAB[10],Adecuaciones[10],FARAC[10],Deudores[10],Banca[10],PIDIREGAS[10]);
				actualizaItemGrafPrima('24',SHRFSP[11],RFSP[11],BalanceTrad[11],IPAB[11],Adecuaciones[11],FARAC[11],Deudores[11],Banca[11],PIDIREGAS[11]);
				actualizaItemGrafPrima('25',SHRFSP[12],RFSP[12],BalanceTrad[12],IPAB[12],Adecuaciones[12],FARAC[12],Deudores[12],Banca[12],PIDIREGAS[12]);
				positionBars();
				positionBars2();
				
			/****************** Fin de carga de grafica google *************************/		

			var ii=0;
			for (i=0;i<fechas.length;i++) {
				ii=i+1;
				recaudacionGasto[i] = eval($(html).find("Lif"+ii).text());
			}
			var year =0;
			var lif = new Array(
				sumatoria(recaudacionGasto[year],0,45), sumatoria(recaudacionGasto[year],0,19),recaudacionGasto[year][0], 
				recaudacionGasto[year][0], recaudacionGasto[year][1],sumatoria(recaudacionGasto[year],2,12), recaudacionGasto[year][2], 
				sumatoria(recaudacionGasto[year],3,12),recaudacionGasto[year][3], recaudacionGasto[year][4], recaudacionGasto[year][5],
				recaudacionGasto[year][6], recaudacionGasto[year][7], recaudacionGasto[year][8], recaudacionGasto[year][9], recaudacionGasto[year][10],
				recaudacionGasto[year][11], recaudacionGasto[year][12], recaudacionGasto[year][13], recaudacionGasto[year][14], recaudacionGasto[year][14],	
				recaudacionGasto[year][15],recaudacionGasto[year][16], recaudacionGasto[year][17],	recaudacionGasto[year][18], recaudacionGasto[year][19],
				recaudacionGasto[year][20], sumatoria(recaudacionGasto[year],21,25), recaudacionGasto[year][21], recaudacionGasto[year][22], 
				recaudacionGasto[year][23], recaudacionGasto[year][24], recaudacionGasto[year][25], recaudacionGasto[year][26], recaudacionGasto[year][26], 
				sumatoria(recaudacionGasto[year],27,32), recaudacionGasto[year][27], recaudacionGasto[year][28], recaudacionGasto[year][29], 
				recaudacionGasto[year][30], recaudacionGasto[year][31], recaudacionGasto[year][32], sumatoria(recaudacionGasto[year],33,35), 
				recaudacionGasto[year][33], recaudacionGasto[year][34], recaudacionGasto[year][35], sumatoria(recaudacionGasto[year],36,37), 
				recaudacionGasto[year][36], recaudacionGasto[year][37], sumatoria(recaudacionGasto[year],38,43), sumatoria(recaudacionGasto[year],38,39),
				recaudacionGasto[year][38], recaudacionGasto[year][39], sumatoria(recaudacionGasto[year],40,42), recaudacionGasto[year][40], 
				recaudacionGasto[year][41], recaudacionGasto[year][42],recaudacionGasto[year][43], recaudacionGasto[year][44], recaudacionGasto[year][45],
				sumatoria(recaudacionGasto[year],0,45)			
				);
			var valores = lif.length;

			for(var i = 0; i< valores;i++) {
				ii=i+1;
				$('.recaudacionGasto'+ii+'-1').text('$ ' +formato(lif[i],true));	
				porcentaje  = lif[i] /Ingresos[year]*100;
				$('.recaudacionGasto'+ii).text( porcentaje.toFixed(2) + '%');	
			}
				


			},
			beforeSend: function () {
				$('.loading').css('visibility','visible');
				$('.loading').show();
				

			},		
			error: function(request,error) {
				console.log(arguments);
				console.log(request);
				alert ( " Can't do because: " + error +'\n'+html);
			}
		});
		

	});



		/*****************  envio de otros impuestos ************************/	
	$('#otrosImpuestosSub').click(function () {		
		var otrosImpuestosIn1 = $('#otrosImpuestosIn1').val();
		var otrosImpuestosIn2 = $('#otrosImpuestosIn2').val();
		var otrosImpuestosIn3 = ($('#otrosImpuestosIn3').is(":checked")?1:0);

		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);
		
		var data = 'otrosImpuestosIn1=' + otrosImpuestosIn1 +'&otrosImpuestosIn2=' + otrosImpuestosIn2 +'&otrosImpuestosIn3=' + otrosImpuestosIn3 +'&idSession='+idSession ;

		$.ajax({
			url: "otrosImpuestosStata.php",	
			
			async:false,

			//GET method is used
			type: "GET",

			//pass the data			
			data: data,		
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (html) {	
				$('.loading').css('visibility','hidden');
				fechas = eval($(html).find("fecha").text()); 				
				var distribucion = eval($(html).find("distribucion").text());								
				var SHRFSP = eval($(html).find("SHRFSP").text());
				var RFSP = eval($(html).find("RFSP").text());
				var BalanceTrad = eval($(html).find("BalanceTrad").text());
				var IPAB = eval($(html).find("IPAB").text());
				var Adecuaciones = eval($(html).find("Adecuaciones").text());
				var FARAC = eval($(html).find("FARAC").text());
				var Deudores = eval($(html).find("Deudores").text());
				var Banca = eval($(html).find("Banca").text());
				var PIDIREGAS = eval($(html).find("PIDIREGAS").text());				

				Gini = eval($(html).find("Gini").text());				
				Gini=Gini[0];
				Ingresos = eval($(html).find("Ingresos").text());				
				Gastos = eval($(html).find("Gastos").text());				
				Deuda = eval($(html).find("Deuda").text());				

				for(var i =0;i<SHRFSP.length;i++) {
					SHRFSP[i]=-1*Number(SHRFSP[i]); 									
				}

				$('#ecuRGD').html('');
				
				for(var i =0;i<Ingresos.length;i++) {
					$("#ecuRGD").append('<option value='+i+'>'+fechas[i]+'</option>');
				}
				
				$('#recaudacionMPD').text(formato(Ingresos[0],true));
				$('#gastoMPD').text(formato(Gastos[0],true));
				$('#deudaMPD').text(formato(Deuda[0],true));
	
				demoGauge.set(Gini*100); // función del velocimetro cambia valor
				$('.vel-val').text(Gini);
			
				actualizaItemGrafPrima('13',SHRFSP[0],RFSP[0],BalanceTrad[0],IPAB[0],Adecuaciones[0],FARAC[0],Deudores[0],Banca[0],PIDIREGAS[0]);
				actualizaItemGrafPrima('14',SHRFSP[1],RFSP[1],BalanceTrad[1],IPAB[1],Adecuaciones[1],FARAC[1],Deudores[1],Banca[1],PIDIREGAS[1]);
				actualizaItemGrafPrima('15',SHRFSP[2],RFSP[2],BalanceTrad[2],IPAB[2],Adecuaciones[2],FARAC[2],Deudores[2],Banca[2],PIDIREGAS[2]);
				actualizaItemGrafPrima('16',SHRFSP[3],RFSP[3],BalanceTrad[3],IPAB[3],Adecuaciones[3],FARAC[3],Deudores[3],Banca[3],PIDIREGAS[3]);
				actualizaItemGrafPrima('17',SHRFSP[4],RFSP[4],BalanceTrad[4],IPAB[4],Adecuaciones[4],FARAC[4],Deudores[4],Banca[4],PIDIREGAS[4]);
				actualizaItemGrafPrima('18',SHRFSP[5],RFSP[5],BalanceTrad[5],IPAB[5],Adecuaciones[5],FARAC[5],Deudores[5],Banca[5],PIDIREGAS[5]);
				actualizaItemGrafPrima('19',SHRFSP[6],RFSP[6],BalanceTrad[6],IPAB[6],Adecuaciones[6],FARAC[6],Deudores[6],Banca[6],PIDIREGAS[6]);
				actualizaItemGrafPrima('20',SHRFSP[7],RFSP[7],BalanceTrad[7],IPAB[7],Adecuaciones[7],FARAC[7],Deudores[7],Banca[7],PIDIREGAS[7]);
				actualizaItemGrafPrima('21',SHRFSP[8],RFSP[8],BalanceTrad[8],IPAB[8],Adecuaciones[8],FARAC[8],Deudores[8],Banca[8],PIDIREGAS[8]);
				actualizaItemGrafPrima('22',SHRFSP[9],RFSP[9],BalanceTrad[9],IPAB[9],Adecuaciones[9],FARAC[9],Deudores[9],Banca[9],PIDIREGAS[9]);
				actualizaItemGrafPrima('23',SHRFSP[10],RFSP[10],BalanceTrad[10],IPAB[10],Adecuaciones[10],FARAC[10],Deudores[10],Banca[10],PIDIREGAS[10]);
				actualizaItemGrafPrima('24',SHRFSP[11],RFSP[11],BalanceTrad[11],IPAB[11],Adecuaciones[11],FARAC[11],Deudores[11],Banca[11],PIDIREGAS[11]);
				actualizaItemGrafPrima('25',SHRFSP[12],RFSP[12],BalanceTrad[12],IPAB[12],Adecuaciones[12],FARAC[12],Deudores[12],Banca[12],PIDIREGAS[12]);
				positionBars();
				positionBars2();

			/****************** Fin de carga de grafica google *************************/		

			},
			beforeSend: function () {
				$('.loading').css('visibility','visible');
				
				

			},		
			error: function(request,error) {
				console.log(arguments);
				console.log(request);
				alert ( " Can't do because: " + error +'\n'+html);
			}
		});
		

	});




		/*****************  envio de otros parámetros ************************/	
	$('#otrosParametrosSub').click(function () {		
		var otrosParametrosIn1 = $('#otrosParametrosIn1').val();
		var otrosParametrosIn2 = $('#otrosParametrosIn2').val();
		var otrosParametrosIn3 = $('#otrosParametrosIn3').val();

		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);
		
		var data = 'otrosParametrosIn1=' + otrosParametrosIn1 +'&otrosParametrosIn2=' + otrosParametrosIn2+'&otrosParametrosIn3=' + otrosParametrosIn3 +'&idSession='+idSession ;

		$.ajax({
			url: "otrosParametrosStata.php",	
			
			async:false,

			//GET method is used
			type: "GET",

			//pass the data			
			data: data,		
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (html) {	
				$('.loading').css('visibility','hidden');
				$('.loading').hide();
					
				$('.loading').css('visibility','hidden');
				fechas = eval($(html).find("fecha").text()); 				
				var distribucion = eval($(html).find("distribucion").text());								
				var SHRFSP = eval($(html).find("SHRFSP").text());
				var RFSP = eval($(html).find("RFSP").text());
				var BalanceTrad = eval($(html).find("BalanceTrad").text());
				var IPAB = eval($(html).find("IPAB").text());
				var Adecuaciones = eval($(html).find("Adecuaciones").text());
				var FARAC = eval($(html).find("FARAC").text());
				var Deudores = eval($(html).find("Deudores").text());
				var Banca = eval($(html).find("Banca").text());
				var PIDIREGAS = eval($(html).find("PIDIREGAS").text());				
				Gini = eval($(html).find("Gini").text());				
				Gini=Gini[0];

				Ingresos = eval($(html).find("Ingresos").text());				
				Gastos = eval($(html).find("Gastos").text());				
				Deuda = eval($(html).find("Deuda").text());				
				var recietu = eval($(html).find("recietu").text());				
				
				 
				for(var i =0;i<SHRFSP.length;i++) {
					SHRFSP[i]=-1*Number(SHRFSP[i]); 									
				}

				$('#ecuRGD').html('');
				
				for(var i =0;i<Ingresos.length;i++) {
					$("#ecuRGD").append('<option value='+i+'>'+fechas[i]+'</option>');
				}

				$('#otrosParametrosDisable1').val(otrosParametrosIn1);				
				$('#otrosParametrosDisable2').val(otrosParametrosIn2);				
				$('#otrosParametrosDisable3').val(otrosParametrosIn3);				



				demoGauge.set(Gini*100); // función del velocimetro cambia valor
				$('.vel-val').text(Gini);
				
								/******************  Actualizar el gráfico de barras ***********/
				actualizaItemGrafPrima('13',SHRFSP[0],RFSP[0],BalanceTrad[0],IPAB[0],Adecuaciones[0],FARAC[0],Deudores[0],Banca[0],PIDIREGAS[0]);
				actualizaItemGrafPrima('14',SHRFSP[1],RFSP[1],BalanceTrad[1],IPAB[1],Adecuaciones[1],FARAC[1],Deudores[1],Banca[1],PIDIREGAS[1]);
				actualizaItemGrafPrima('15',SHRFSP[2],RFSP[2],BalanceTrad[2],IPAB[2],Adecuaciones[2],FARAC[2],Deudores[2],Banca[2],PIDIREGAS[2]);
				actualizaItemGrafPrima('16',SHRFSP[3],RFSP[3],BalanceTrad[3],IPAB[3],Adecuaciones[3],FARAC[3],Deudores[3],Banca[3],PIDIREGAS[3]);
				actualizaItemGrafPrima('17',SHRFSP[4],RFSP[4],BalanceTrad[4],IPAB[4],Adecuaciones[4],FARAC[4],Deudores[4],Banca[4],PIDIREGAS[4]);
				actualizaItemGrafPrima('18',SHRFSP[5],RFSP[5],BalanceTrad[5],IPAB[5],Adecuaciones[5],FARAC[5],Deudores[5],Banca[5],PIDIREGAS[5]);
				actualizaItemGrafPrima('19',SHRFSP[6],RFSP[6],BalanceTrad[6],IPAB[6],Adecuaciones[6],FARAC[6],Deudores[6],Banca[6],PIDIREGAS[6]);
				actualizaItemGrafPrima('20',SHRFSP[7],RFSP[7],BalanceTrad[7],IPAB[7],Adecuaciones[7],FARAC[7],Deudores[7],Banca[7],PIDIREGAS[7]);
				actualizaItemGrafPrima('21',SHRFSP[8],RFSP[8],BalanceTrad[8],IPAB[8],Adecuaciones[8],FARAC[8],Deudores[8],Banca[8],PIDIREGAS[8]);
				actualizaItemGrafPrima('22',SHRFSP[9],RFSP[9],BalanceTrad[9],IPAB[9],Adecuaciones[9],FARAC[9],Deudores[9],Banca[9],PIDIREGAS[9]);
				actualizaItemGrafPrima('23',SHRFSP[10],RFSP[10],BalanceTrad[10],IPAB[10],Adecuaciones[10],FARAC[10],Deudores[10],Banca[10],PIDIREGAS[10]);
				actualizaItemGrafPrima('24',SHRFSP[11],RFSP[11],BalanceTrad[11],IPAB[11],Adecuaciones[11],FARAC[11],Deudores[11],Banca[11],PIDIREGAS[11]);
				actualizaItemGrafPrima('25',SHRFSP[12],RFSP[12],BalanceTrad[12],IPAB[12],Adecuaciones[12],FARAC[12],Deudores[12],Banca[12],PIDIREGAS[12]);
				positionBars();
				positionBars2();

			/****************** Fin de carga de grafica google *************************/		

			},
			beforeSend: function () {
				$('.loading').css('visibility','visible');
				$('.loading').show();
				

			},			
			error: function(request,error) {
				console.log(arguments);
				console.log(request);
				alert ( " Can't do because: " + error +'\n'+html);
			}
		});
		

	});





		/*****************  envio de pension no contributivas ************************/	
	$('#PensionNCSub').click(function () {		
		var PensionNCIn1 = $('#PensionNCIn1').val();
		var PensionNCIn2 = $('#PensionNCIn2').val();
		var PensionNCIn3 = $('#PensionNCIn3').val();
		var PensionNCIn4 = $('#PensionNCIn4').val();
		var PensionNCIn5 = $('#PensionNCIn5').val();

		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);
		
		var data = 'PensionNCIn1=' + PensionNCIn1 +'&PensionNCIn2=' + PensionNCIn2+'&PensionNCIn3=' + PensionNCIn3+'&PensionNCIn4=' + PensionNCIn4 +'&PensionNCIn5=' + PensionNCIn5 +'&idSession='+idSession ;

		$.ajax({
			url: "pensionNCStata.php",	
			
			async:false,

			//GET method is used
			type: "GET",

			//pass the data			
			data: data,		
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (html) {	
				$('.loading').css('visibility','hidden');
				
				fechas = eval($(html).find("fecha").text()); 				
				var distribucion = eval($(html).find("distribucion").text());								
				var SHRFSP = eval($(html).find("SHRFSP").text());
				var RFSP = eval($(html).find("RFSP").text());
				var BalanceTrad = eval($(html).find("BalanceTrad").text());
				var IPAB = eval($(html).find("IPAB").text());
				var Adecuaciones = eval($(html).find("Adecuaciones").text());
				var FARAC = eval($(html).find("FARAC").text());
				var Deudores = eval($(html).find("Deudores").text());
				var Banca = eval($(html).find("Banca").text());
				var PIDIREGAS = eval($(html).find("PIDIREGAS").text());				
				
				var edades = eval($(html).find("edades").text()); 
				var pensionhom = eval($(html).find("pensionhom").text()); 
				var pensionmuj = eval($(html).find("pensionmuj").text()); 
				var pensiones = eval($(html).find("pensiones").text()); 

				var pensionesnc_pdm_1 = eval($(html).find("pensionesnc_pdm_1").text()); 


				Gini = eval($(html).find("Gini").text());				
				Gini=Gini[0];
				Ingresos = eval($(html).find("Ingresos").text());				
				Gastos = eval($(html).find("Gastos").text());				
				Deuda = eval($(html).find("Deuda").text());				
				var gaspensiones = eval($(html).find("gaspensiones").text()); 
				var pibpensiones = eval($(html).find("pibpensiones").text()); 


				for(var i =0;i<SHRFSP.length;i++) {
					SHRFSP[i]=-1*Number(SHRFSP[i]); 									
				}


				$('#ecuRGD').html('');
				
				for(var i =0;i<Ingresos.length;i++) {
					$("#ecuRGD").append('<option value='+i+'>'+fechas[i]+'</option>');
				}
				for(var i =0;i<pensiones.length;i++) {
					actualizaItemtablaString("#pensiones"+i,pensiones[i],' %');
					actualizaItemtablaString("#pensiones_pdm"+i,pensionesnc_pdm_1[i],' %');
				}

				$('#recaudacionMPD').text(formato(Ingresos[0],true));
				$('#gastoMPD').text(formato(Gastos[0],true));
				$('#deudaMPD').text(formato(Deuda[0],true));
				$('#recaudacionProyectada').text(formato(gaspensiones,true));
				$('#pibProyectado').text(pibpensiones);

				demoGauge.set(Gini*100); // función del velocimetro cambia valor
				$('.vel-val').text(Gini);


				
				/******************  Actualizar el gráfico de barras ***********/
				actualizaItemGrafPrima('13',SHRFSP[0],RFSP[0],BalanceTrad[0],IPAB[0],Adecuaciones[0],FARAC[0],Deudores[0],Banca[0],PIDIREGAS[0]);
				actualizaItemGrafPrima('14',SHRFSP[1],RFSP[1],BalanceTrad[1],IPAB[1],Adecuaciones[1],FARAC[1],Deudores[1],Banca[1],PIDIREGAS[1]);
				actualizaItemGrafPrima('15',SHRFSP[2],RFSP[2],BalanceTrad[2],IPAB[2],Adecuaciones[2],FARAC[2],Deudores[2],Banca[2],PIDIREGAS[2]);
				actualizaItemGrafPrima('16',SHRFSP[3],RFSP[3],BalanceTrad[3],IPAB[3],Adecuaciones[3],FARAC[3],Deudores[3],Banca[3],PIDIREGAS[3]);
				actualizaItemGrafPrima('17',SHRFSP[4],RFSP[4],BalanceTrad[4],IPAB[4],Adecuaciones[4],FARAC[4],Deudores[4],Banca[4],PIDIREGAS[4]);
				actualizaItemGrafPrima('18',SHRFSP[5],RFSP[5],BalanceTrad[5],IPAB[5],Adecuaciones[5],FARAC[5],Deudores[5],Banca[5],PIDIREGAS[5]);
				actualizaItemGrafPrima('19',SHRFSP[6],RFSP[6],BalanceTrad[6],IPAB[6],Adecuaciones[6],FARAC[6],Deudores[6],Banca[6],PIDIREGAS[6]);
				actualizaItemGrafPrima('20',SHRFSP[7],RFSP[7],BalanceTrad[7],IPAB[7],Adecuaciones[7],FARAC[7],Deudores[7],Banca[7],PIDIREGAS[7]);
				actualizaItemGrafPrima('21',SHRFSP[8],RFSP[8],BalanceTrad[8],IPAB[8],Adecuaciones[8],FARAC[8],Deudores[8],Banca[8],PIDIREGAS[8]);
				actualizaItemGrafPrima('22',SHRFSP[9],RFSP[9],BalanceTrad[9],IPAB[9],Adecuaciones[9],FARAC[9],Deudores[9],Banca[9],PIDIREGAS[9]);
				actualizaItemGrafPrima('23',SHRFSP[10],RFSP[10],BalanceTrad[10],IPAB[10],Adecuaciones[10],FARAC[10],Deudores[10],Banca[10],PIDIREGAS[10]);
				actualizaItemGrafPrima('24',SHRFSP[11],RFSP[11],BalanceTrad[11],IPAB[11],Adecuaciones[11],FARAC[11],Deudores[11],Banca[11],PIDIREGAS[11]);
				actualizaItemGrafPrima('25',SHRFSP[12],RFSP[12],BalanceTrad[12],IPAB[12],Adecuaciones[12],FARAC[12],Deudores[12],Banca[12],PIDIREGAS[12]);
				positionBars();
				positionBars2();

				var pensionesnc_pdmhom = eval($(html).find("pensionesnc_pdmhom").text()); 
				var pensionesnc_pdmmuj = eval($(html).find("pensionesnc_pdmmuj").text()); 
					/*************************  Recargar el gráfico de google ********************/
				var datas = google.visualization.arrayToDataTable([
				  ['Edades', 'Hombres', 'Mujeres'],
					[edades[0], pensionhom[0], pensionmuj[0]],
					[edades[1], pensionhom[1], pensionmuj[1]],
					[edades[2], pensionhom[2], pensionmuj[2]],
					[edades[3], pensionhom[3], pensionmuj[3]],
					[edades[4], pensionhom[4], pensionmuj[4]],
					[edades[5], pensionhom[5], pensionmuj[5]],
					[edades[6], pensionhom[6], pensionmuj[6]],
					[edades[7], pensionhom[7], pensionmuj[7]],
					[edades[8], pensionhom[8], pensionmuj[8]],
					[edades[9], pensionhom[9], pensionmuj[9]],
					[edades[10], pensionhom[10], pensionmuj[10]],
					[edades[11], pensionhom[11], pensionmuj[11]],
					[edades[12], pensionhom[12], pensionmuj[12]],
					[edades[13], pensionhom[13], pensionmuj[13]],
					[edades[14], pensionhom[14], pensionmuj[14]],
					[edades[15], pensionhom[15], pensionmuj[15]],
					[edades[16], pensionhom[16], pensionmuj[16]],
					[edades[17], pensionhom[17], pensionmuj[17]],
					[edades[18], pensionhom[18], pensionmuj[18]],
					[edades[19], pensionhom[19], pensionmuj[19]]
				]);
				
			var options = {
			  curveType:'function',
			  width: 660, 
			  height: 328,
			  focusTarget: 'category',
			  chartArea:{top:5, bottom:0, width:"68%", height:"78%"},
			  lineWidth: 3,
			  fontSize: 11,
			  colors:['#38919c', '#fc782d'],
			  tooltip: {textStyle: {fontSize: 13}},
			  hAxis:{title: 'Edades',  titleTextStyle: {color: '#333', fontSize: 13}, textStyle: {color: '#686868'}},
			  vAxis:{title: 'Porcentaje de beneficiarios (%)', titleTextStyle: {color: '#333', fontSize: 13}, textStyle: {color: '#686868'}},
			  legend: {position:'right', alignment:'start', textStyle:{color: '#333', fontSize: 12}}
			};
	
			var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
			chart.draw(datas, options);
				
				
			/****************** Fin de carga de grafica google *************************/		

			},
			beforeSend: function () {
				$('.loading').css('visibility','visible');
				$('.loading').show();
				
				

			},		
			error: function(request,error) {
				console.log(request);
				alert ( " Can't do because: " + error +'\n');
			}
		});
		

	});



		/*****************  envio de educacion  ************************/	
	$('#educacionSub').click(function () {		
		var edicacionA1 = $('#edicacionA1').val();
		var edicacionA2 = $('#edicacionA2').val();
		var edicacionA3 = $('#edicacionA3').val();
		var edicacionA4 = $('#edicacionA4').val();

		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);
		
		var data = 'edicacionA1=' + edicacionA1 +'&edicacionA2=' + edicacionA2 + '&edicacionA3=' + edicacionA3 + '&edicacionA4=' + edicacionA4 +'&idSession='+idSession ;

		$.ajax({
			url: "educacionStata.php",	
			
			async:false,

			//GET method is used
			type: "GET",

			//pass the data			
			data: data,		
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (html) {	
				$('.loading').css('visibility','hidden');
				$('.loading').hide();

				fechas = eval($(html).find("fecha").text()); 				
				var distribucion = eval($(html).find("distribucion").text());								
				var SHRFSP = eval($(html).find("SHRFSP").text());
				var RFSP = eval($(html).find("RFSP").text());
				var BalanceTrad = eval($(html).find("BalanceTrad").text());
				var IPAB = eval($(html).find("IPAB").text());
				var Adecuaciones = eval($(html).find("Adecuaciones").text());
				var FARAC = eval($(html).find("FARAC").text());
				var Deudores = eval($(html).find("Deudores").text());
				var Banca = eval($(html).find("Banca").text());
				var PIDIREGAS = eval($(html).find("PIDIREGAS").text());				
				
				var edades = eval($(html).find("edades").text()); 
				var contbasicahom = eval($(html).find("contbasicahom").text()); 
				var contbasicamuj = eval($(html).find("contbasicamuj").text()); 
				var contmedsuphom = eval($(html).find("contmedsuphom").text()); 
				var contmedsupmuj = eval($(html).find("contmedsupmuj").text()); 
				var contsuperiorhom = eval($(html).find("contsuperiorhom").text()); 
				var contsuperiormuj = eval($(html).find("contsuperiormuj").text()); 
				var contposgradohom = eval($(html).find("contposgradohom").text()); 
				var contposgradomuj = eval($(html).find("contposgradomuj").text()); 

				var basdis = eval($(html).find("basdis").text()); 
				var medsupdis = eval($(html).find("medsupdis").text()); 
				var superiordis = eval($(html).find("superiordis").text()); 
				var posgradodis = eval($(html).find("posgradodis").text()); 


				Gini = eval($(html).find("Gini").text());				
				Gini=Gini[0];
				Ingresos = eval($(html).find("Ingresos").text());				
				Gastos = eval($(html).find("Gastos").text());				
				Deuda = eval($(html).find("Deuda").text());				
				var gaseducacion = eval($(html).find("gaseducacion").text()); 
				var pibeducacion = eval($(html).find("pibeducacion").text()); 
				for(var i =0;i<SHRFSP.length;i++) {
					SHRFSP[i]=-1*Number(SHRFSP[i]); 									
				}

				$('#ecuRGD').html('');
				
				for(var i =0;i<Ingresos.length;i++) {
					$("#ecuRGD").append('<option value='+i+'>'+fechas[i]+'</option>');
				}
				
				$('#recaudacionMPD').text(formato(Ingresos[0],true));
				$('#gastoMPD').text(formato(Gastos[0],true));
				$('#deudaMPD').text(formato(Deuda[0],true));
				$('#recaudacionProyectada').text(formato(gaseducacion,true));   
				$('#pibProyectado').text(pibeducacion);

				demoGauge.set(Gini*100); // función del velocimetro cambia valor
				$('.vel-val').text(Gini);
				var ii="";
				for(var i=0;i<basdis.length;i++) {
					ii=i+1;
					if(ii<10) {
						ii="0"+ii;
					}
					actualizaItemtablaString("#educacionBasica"+ii,basdis[i],' %');
					actualizaItemtablaString("#educacionMediaSup"+ii,medsupdis[i],' %');
					actualizaItemtablaString("#educacionSuperior"+ii,superiordis[i],' %');
					actualizaItemtablaString("#educacionPosgrado"+ii,posgradodis[i],' %');
				}
				
				actualizaItemGrafPrima('13',SHRFSP[0],RFSP[0],BalanceTrad[0],IPAB[0],Adecuaciones[0],FARAC[0],Deudores[0],Banca[0],PIDIREGAS[0]);
				actualizaItemGrafPrima('14',SHRFSP[1],RFSP[1],BalanceTrad[1],IPAB[1],Adecuaciones[1],FARAC[1],Deudores[1],Banca[1],PIDIREGAS[1]);
				actualizaItemGrafPrima('15',SHRFSP[2],RFSP[2],BalanceTrad[2],IPAB[2],Adecuaciones[2],FARAC[2],Deudores[2],Banca[2],PIDIREGAS[2]);
				actualizaItemGrafPrima('16',SHRFSP[3],RFSP[3],BalanceTrad[3],IPAB[3],Adecuaciones[3],FARAC[3],Deudores[3],Banca[3],PIDIREGAS[3]);
				actualizaItemGrafPrima('17',SHRFSP[4],RFSP[4],BalanceTrad[4],IPAB[4],Adecuaciones[4],FARAC[4],Deudores[4],Banca[4],PIDIREGAS[4]);
				actualizaItemGrafPrima('18',SHRFSP[5],RFSP[5],BalanceTrad[5],IPAB[5],Adecuaciones[5],FARAC[5],Deudores[5],Banca[5],PIDIREGAS[5]);
				actualizaItemGrafPrima('19',SHRFSP[6],RFSP[6],BalanceTrad[6],IPAB[6],Adecuaciones[6],FARAC[6],Deudores[6],Banca[6],PIDIREGAS[6]);
				actualizaItemGrafPrima('20',SHRFSP[7],RFSP[7],BalanceTrad[7],IPAB[7],Adecuaciones[7],FARAC[7],Deudores[7],Banca[7],PIDIREGAS[7]);
				actualizaItemGrafPrima('21',SHRFSP[8],RFSP[8],BalanceTrad[8],IPAB[8],Adecuaciones[8],FARAC[8],Deudores[8],Banca[8],PIDIREGAS[8]);
				actualizaItemGrafPrima('22',SHRFSP[9],RFSP[9],BalanceTrad[9],IPAB[9],Adecuaciones[9],FARAC[9],Deudores[9],Banca[9],PIDIREGAS[9]);
				actualizaItemGrafPrima('23',SHRFSP[10],RFSP[10],BalanceTrad[10],IPAB[10],Adecuaciones[10],FARAC[10],Deudores[10],Banca[10],PIDIREGAS[10]);
				actualizaItemGrafPrima('24',SHRFSP[11],RFSP[11],BalanceTrad[11],IPAB[11],Adecuaciones[11],FARAC[11],Deudores[11],Banca[11],PIDIREGAS[11]);
				actualizaItemGrafPrima('25',SHRFSP[12],RFSP[12],BalanceTrad[12],IPAB[12],Adecuaciones[12],FARAC[12],Deudores[12],Banca[12],PIDIREGAS[12]);
				positionBars();
				positionBars2();

					/*************************  Recargar el gráfico de google ********************/
				var datas = google.visualization.arrayToDataTable([
				  ['Edades', 'H básica', 'M básica', 'H media', 'M media', 'H superior', 'M superior', 'H posgrado', 'M posgrado'],
					[edades[0], contbasicahom[0], contbasicamuj[0], contmedsuphom[0], contmedsupmuj[0], contsuperiorhom[0], contsuperiormuj[0], contposgradohom[0], contposgradomuj[0]],
					[edades[1], contbasicahom[1], contbasicamuj[1], contmedsuphom[1], contmedsupmuj[1], contsuperiorhom[1], contsuperiormuj[1], contposgradohom[1], contposgradomuj[1]],
					[edades[2], contbasicahom[2], contbasicamuj[2], contmedsuphom[2], contmedsupmuj[2], contsuperiorhom[2], contsuperiormuj[2], contposgradohom[2], contposgradomuj[2]],
					[edades[3], contbasicahom[3], contbasicamuj[3], contmedsuphom[3], contmedsupmuj[3], contsuperiorhom[3], contsuperiormuj[3], contposgradohom[0], contposgradomuj[3]],
					[edades[4], contbasicahom[4], contbasicamuj[4], contmedsuphom[4], contmedsupmuj[4], contsuperiorhom[4], contsuperiormuj[4], contposgradohom[0], contposgradomuj[4]],
					[edades[5], contbasicahom[5], contbasicamuj[5], contmedsuphom[5], contmedsupmuj[5], contsuperiorhom[5], contsuperiormuj[5], contposgradohom[0], contposgradomuj[5]],
					[edades[6], contbasicahom[6], contbasicamuj[6], contmedsuphom[6], contmedsupmuj[6], contsuperiorhom[6], contsuperiormuj[6], contposgradohom[0], contposgradomuj[6]],
					[edades[7], contbasicahom[7], contbasicamuj[7], contmedsuphom[7], contmedsupmuj[7], contsuperiorhom[7], contsuperiormuj[7], contposgradohom[0], contposgradomuj[7]],
					[edades[8], contbasicahom[8], contbasicamuj[8], contmedsuphom[8], contmedsupmuj[8], contsuperiorhom[8], contsuperiormuj[8], contposgradohom[0], contposgradomuj[8]],
					[edades[9], contbasicahom[9], contbasicamuj[9], contmedsuphom[9], contmedsupmuj[9], contsuperiorhom[9], contsuperiormuj[9], contposgradohom[0], contposgradomuj[9]],
					[edades[10], contbasicahom[10], contbasicamuj[10], contmedsuphom[10], contmedsupmuj[10], contsuperiorhom[10], contsuperiormuj[10], contposgradohom[10], contposgradomuj[10]],
[edades[11 ], contbasicahom[11], contbasicamuj[11], contmedsuphom[11], contmedsupmuj[11], contsuperiorhom[11], contsuperiormuj[11], contposgradohom[11],  contposgradomuj[11]],
[edades[12 ], contbasicahom[12], contbasicamuj[12], contmedsuphom[12], contmedsupmuj[12], contsuperiorhom[12], contsuperiormuj[12], contposgradohom[12],  contposgradomuj[12]],
[edades[13 ], contbasicahom[13], contbasicamuj[13], contmedsuphom[13], contmedsupmuj[13], contsuperiorhom[13], contsuperiormuj[13], contposgradohom[13],  contposgradomuj[13]],
[edades[14 ], contbasicahom[14], contbasicamuj[14], contmedsuphom[14], contmedsupmuj[14], contsuperiorhom[14], contsuperiormuj[14], contposgradohom[14],  contposgradomuj[14]],
[edades[15 ], contbasicahom[15], contbasicamuj[15], contmedsuphom[15], contmedsupmuj[15], contsuperiorhom[15], contsuperiormuj[15], contposgradohom[15],  contposgradomuj[15]],
[edades[16 ], contbasicahom[16], contbasicamuj[16], contmedsuphom[16], contmedsupmuj[16], contsuperiorhom[16], contsuperiormuj[16], contposgradohom[16],  contposgradomuj[16]],
[edades[17 ], contbasicahom[17], contbasicamuj[17], contmedsuphom[17], contmedsupmuj[17], contsuperiorhom[17], contsuperiormuj[17], contposgradohom[17],  contposgradomuj[17]],
[edades[18 ], contbasicahom[18], contbasicamuj[18], contmedsuphom[18], contmedsupmuj[18], contsuperiorhom[18], contsuperiormuj[18], contposgradohom[18],  contposgradomuj[18]],
[edades[19 ], contbasicahom[19], contbasicamuj[19], contmedsuphom[19], contmedsupmuj[19], contsuperiorhom[19], contsuperiormuj[19], contposgradohom[19],  contposgradomuj[19]]
				]);
				
			var options = {
			  curveType:'function',
			  width: 660, 
			  height: 328,
			  focusTarget: 'category',
			  chartArea:{top:5, bottom:0, width:"68%", height:"78%"},
			  lineWidth: 2,
			  fontSize: 11,
			  colors:['#f5cd30', '#e8a729', '#e48227', '#e99378', '#e66e4c', '#df4f2d', '#7fbfdb', '#328e9b'],
			  tooltip: {textStyle: {fontSize: 13}},
			  hAxis:{title: 'Edades',  titleTextStyle: {color: '#333', fontSize: 13}, textStyle: {color: '#686868'}},
			  vAxis:{title: 'Porcentaje de beneficiarios (%)', titleTextStyle: {color: '#333', fontSize: 13}, textStyle: {color: '#686868'}},
			  legend: {position:'right', alignment:'start', textStyle:{color: '#333', fontSize: 12}}
			};
	
			var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
			chart.draw(datas, options);

			/****************** Fin de carga de grafica google *************************/		

			},
			beforeSend: function () {
				$('.loading').css('visibility','visible');
				$('.loading').show();

			},		
			error: function(request,error) {
				console.log(arguments);
				console.log(request);
				alert ( " Can't do because: " + error +'\n'+html);
			}
		});
		

	});



		/*****************  envio de ieps  ************************/	
	$('#iepsSub').click(function () {		
		var IEPSA1 = $('#IEPSA1').val();
		var IEPSA2 = $('#IEPSA2').val();
		var IEPSA3 = $('#IEPSA3').val();
		var IEPSA4 = $('#IEPSA4').val();
		var IEPSA5 = $('#IEPSA5').val();
		var IEPSA6 = $('#IEPSA6').val();
		var IEPSA7 = $('#IEPSA7').val();
		var IEPSA8 = $('#IEPSA8').val();
		var IEPSA9 = $('#IEPSA9').val();
		var IEPSA10 = $('#IEPSA10').val();
		var IEPSA11 = $('#IEPSA11').val();
		var IEPSA12 = $('#IEPSA12').val();
		var IEPSA13 = $('#IEPSA13').val();

		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);
		
		var data = 'IEPSA1=' + IEPSA1 +'&IEPSA2=' + IEPSA2 + '&IEPSA3=' + IEPSA3 + '&IEPSA4=' + IEPSA4 + '&IEPSA5=' + IEPSA5 + '&IEPSA6=' + IEPSA6 + '&IEPSA7=' + IEPSA7 + '&IEPSA8=' + IEPSA8 + '&IEPSA9=' + IEPSA9 + '&IEPSA10=' + IEPSA10 + '&IEPSA11=' + IEPSA11 + '&IEPSA12=' + IEPSA12+ '&IEPSA13=' + IEPSA13 +'&idSession='+idSession ;

		$.ajax({
			url: "iepsStata.php",	
			
			async:false,

			//GET method is used
			type: "GET",

			//pass the data			
			data: data,		
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (html) {	
				$('.loading').css('visibility','hidden');
				$('.loading').hide();

				
				fechas = eval($(html).find("fecha").text()); 				
				var distribucion = eval($(html).find("distribucion").text());								
				var SHRFSP = eval($(html).find("SHRFSP").text());
				var RFSP = eval($(html).find("RFSP").text());
				var BalanceTrad = eval($(html).find("BalanceTrad").text());
				var IPAB = eval($(html).find("IPAB").text());
				var Adecuaciones = eval($(html).find("Adecuaciones").text());
				var FARAC = eval($(html).find("FARAC").text());
				var Deudores = eval($(html).find("Deudores").text());
				var Banca = eval($(html).find("Banca").text());
				var PIDIREGAS = eval($(html).find("PIDIREGAS").text());				

				Gini = eval($(html).find("Gini").text());				
				Gini=Gini[0];
				Ingresos = eval($(html).find("Ingresos").text());				
				Gastos = eval($(html).find("Gastos").text());				
				Deuda = eval($(html).find("Deuda").text());				

				var edades = eval($(html).find("edades").text());				
				var alcoholhom = eval($(html).find("alcoholhom").text());				
				var alcoholmuj = eval($(html).find("alcoholmuj").text());				
				var iepsadec = eval($(html).find("iepsadec").text());				
				var iepsadis = eval($(html).find("iepsadis").text());				
				var reciepsa = eval($(html).find("reciepsa").text());	
				var pibiepsa = eval($(html).find("pibiepsa").text());	
							
				var cervhom = eval($(html).find("cervhom").text());				
				var cervmuj = eval($(html).find("cervmuj").text());	
				var reciepsc = eval($(html).find("reciepsc").text());	
				var pibiepsc = eval($(html).find("pibiepsc").text());	
				var iepscdec = eval($(html).find("iepscdec").text());				
				var iepscdis = eval($(html).find("iepscdis").text());				
				var sorthom = eval($(html).find("sorthom").text());				
				var sortmuj = eval($(html).find("sortmuj").text());	
				var iepssdec = eval($(html).find("iepssdec").text());	
				var iepssdis = eval($(html).find("iepssdis").text());	
				var reciepss = eval($(html).find("reciepss").text());				
				var pibiepss = eval($(html).find("pibiepss").text());				
				var tabhom = eval($(html).find("tabhom").text());				
				var tabmuj = eval($(html).find("tabmuj").text());				
				var iepstdec = eval($(html).find("iepstdec").text());				
				var iepstdis = eval($(html).find("iepstdis").text());				
				var reciepst = eval($(html).find("reciepst").text());				
				var pibiepst = eval($(html).find("pibiepst").text());				
				var telehom = eval($(html).find("telehom").text());				
				var telemuj = eval($(html).find("telemuj").text());				
				var iepstedec = eval($(html).find("iepstedec").text());				
				var iepstedis = eval($(html).find("iepstedis").text());				
				var reciepste = eval($(html).find("reciepste").text());				
				var pibiepste = eval($(html).find("pibiepste").text());
				
				var bazuhom = eval($(html).find("bazuhom").text());				
				var bazumuj = eval($(html).find("bazumuj").text());				
				var iepsbazudec = eval($(html).find("iepsbazudec").text());				
				var iepsbazudis = eval($(html).find("iepsbazudis").text());				
				var reciepsbazu = eval($(html).find("reciepsbazu").text());				
				var pibiepsbazu = eval($(html).find("pibiepsbazu").text());			
					
				var benehom = eval($(html).find("benehom").text());				
				var benemuj = eval($(html).find("benemuj").text());				
				var iepsbenedec = eval($(html).find("iepsbenedec").text());				
				var iepsbenedis = eval($(html).find("iepsbenedis").text());				
				var reciepsbene = eval($(html).find("reciepsbene").text());				
				var pibiepsbene = eval($(html).find("pibiepsbene").text());				

				var chathom = eval($(html).find("chathom").text());				
				var chatmuj = eval($(html).find("chatmuj").text());				
				var iepschatdec = eval($(html).find("iepschatdec").text());				
				var iepschatdis = eval($(html).find("iepschatdis").text());				
				var reciepschat = eval($(html).find("reciepschat").text());				
				var pibiepschat = eval($(html).find("pibiepschat").text());				
				
				var reciepsTotal = Number(reciepste) + Number(reciepst) + Number(reciepss) + Number(reciepsa) +Number(reciepsc);
				var pibiepsTotal = Number(pibiepste) + Number(pibiepst) + Number(pibiepss) + Number(pibiepsa) +Number(pibiepsc);

				for(var i =0;i<SHRFSP.length;i++) {
					SHRFSP[i]=-1*Number(SHRFSP[i]); 									
				}

				$('#ecuRGD').html('');
				
				for(var i =0;i<Ingresos.length;i++) {
					$("#ecuRGD").append('<option value='+i+'>'+fechas[i]+'</option>');
				}
				
				$('#recaudacionMPD').text(formato(Ingresos[0],true));
				$('#gastoMPD').text(formato(Gastos[0],true));
				$('#deudaMPD').text(formato(Deuda[0],true));
				$('#recaudacionProyectada').text(formato(reciepsTotal,true));
				$('#pibProyectado').text(pibiepsTotal);

				demoGauge.set(Gini*100); // función del velocimetro cambia valor
				$('.vel-val').text(Gini);
				
				var ii=0;
				for(var i=0;i<edades.length;i++) {
					ii=i+1;
					actualizaItemtabla("#"+ii+"Incidencia"+1,formato(iepsadec[i],true));
					actualizaItemtablaString("#"+ii+"Incidencia"+2,iepsadis[i],' %');
					actualizaItemtabla("#"+ii+"Incidencia"+3,formato(iepscdec[i],true));
					actualizaItemtablaString("#"+ii+"Incidencia"+4,iepscdis[i],' %');
					actualizaItemtabla("#"+ii+"Incidencia"+5,formato(iepssdec[i],true));
					actualizaItemtablaString("#"+ii+"Incidencia"+6,iepssdis[i],' %');
					actualizaItemtabla("#"+ii+"Incidencia"+7,formato(iepstdec[i],true));
					actualizaItemtablaString("#"+ii+"Incidencia"+8,iepstdis[i],' %');
					actualizaItemtabla("#"+ii+"Incidencia"+9,formato(iepstedec[i],true));
					actualizaItemtablaString("#"+ii+"Incidencia"+10,iepstedis[i],' %');
					actualizaItemtabla("#"+ii+"Incidencia"+11,formato(iepsbenedec[i],true));
					actualizaItemtablaString("#"+ii+"Incidencia"+12,iepsbenedis[i],' %');
					actualizaItemtabla("#"+ii+"Incidencia"+13,formato(iepsbazudec[i],true));
					actualizaItemtablaString("#"+ii+"Incidencia"+14,iepsbazudis[i],' %');
					actualizaItemtabla("#"+ii+"Incidencia"+15,formato(iepschatdec[i],true));
					actualizaItemtablaString("#"+ii+"Incidencia"+16,iepschatdis[i],' %');
				}
			
				/******************  Actualizar el gráfico de barras ***********/
				actualizaItemGrafPrima('13',SHRFSP[0],RFSP[0],BalanceTrad[0],IPAB[0],Adecuaciones[0],FARAC[0],Deudores[0],Banca[0],PIDIREGAS[0]);
				actualizaItemGrafPrima('14',SHRFSP[1],RFSP[1],BalanceTrad[1],IPAB[1],Adecuaciones[1],FARAC[1],Deudores[1],Banca[1],PIDIREGAS[1]);
				actualizaItemGrafPrima('15',SHRFSP[2],RFSP[2],BalanceTrad[2],IPAB[2],Adecuaciones[2],FARAC[2],Deudores[2],Banca[2],PIDIREGAS[2]);
				actualizaItemGrafPrima('16',SHRFSP[3],RFSP[3],BalanceTrad[3],IPAB[3],Adecuaciones[3],FARAC[3],Deudores[3],Banca[3],PIDIREGAS[3]);
				actualizaItemGrafPrima('17',SHRFSP[4],RFSP[4],BalanceTrad[4],IPAB[4],Adecuaciones[4],FARAC[4],Deudores[4],Banca[4],PIDIREGAS[4]);
				actualizaItemGrafPrima('18',SHRFSP[5],RFSP[5],BalanceTrad[5],IPAB[5],Adecuaciones[5],FARAC[5],Deudores[5],Banca[5],PIDIREGAS[5]);
				actualizaItemGrafPrima('19',SHRFSP[6],RFSP[6],BalanceTrad[6],IPAB[6],Adecuaciones[6],FARAC[6],Deudores[6],Banca[6],PIDIREGAS[6]);
				actualizaItemGrafPrima('20',SHRFSP[7],RFSP[7],BalanceTrad[7],IPAB[7],Adecuaciones[7],FARAC[7],Deudores[7],Banca[7],PIDIREGAS[7]);
				actualizaItemGrafPrima('21',SHRFSP[8],RFSP[8],BalanceTrad[8],IPAB[8],Adecuaciones[8],FARAC[8],Deudores[8],Banca[8],PIDIREGAS[8]);
				actualizaItemGrafPrima('22',SHRFSP[9],RFSP[9],BalanceTrad[9],IPAB[9],Adecuaciones[9],FARAC[9],Deudores[9],Banca[9],PIDIREGAS[9]);
				actualizaItemGrafPrima('23',SHRFSP[10],RFSP[10],BalanceTrad[10],IPAB[10],Adecuaciones[10],FARAC[10],Deudores[10],Banca[10],PIDIREGAS[10]);
				actualizaItemGrafPrima('24',SHRFSP[11],RFSP[11],BalanceTrad[11],IPAB[11],Adecuaciones[11],FARAC[11],Deudores[11],Banca[11],PIDIREGAS[11]);
				actualizaItemGrafPrima('25',SHRFSP[12],RFSP[12],BalanceTrad[12],IPAB[12],Adecuaciones[12],FARAC[12],Deudores[12],Banca[12],PIDIREGAS[12]);
				positionBars();
				positionBars2();
				
				
				var datas = google.visualization.arrayToDataTable([
				  ['Edades', 'H Alcohol', 'M Alcohol', 'H Cerveza', 'M Cerveza', 'H Sorteos', 'M Sorteos', 'H Tabaco', 'M Tabaco', 'H Telecom.', 'M Telecom.' , 'H Beb. Energ', 'M Beb. Energ' , 'H Beb. Azu.', 'M Beb. Azu.' , 'H Alim. Chat.', 'M Alim. Chat.' ],
				[ edades[0], alcoholhom[0], alcoholmuj[0], cervhom[0], cervmuj [0], sorthom[0], sortmuj[0], tabhom[0], tabmuj[0], telehom[0], telemuj[0], bazuhom[0], bazumuj[0], benehom[0], benemuj[0], chathom[0],chatmuj[0] ],
				[ edades[1], alcoholhom[1], alcoholmuj[1], cervhom[1], cervmuj [1], sorthom[1], sortmuj[1], tabhom[1], tabmuj[1], telehom[1], telemuj[1], bazuhom[1], bazumuj[1], benehom[1], benemuj[1], chathom[1],chatmuj[1] ],
				[ edades[2], alcoholhom[2], alcoholmuj[2], cervhom[2], cervmuj [2], sorthom[2], sortmuj[2], tabhom[2], tabmuj[2], telehom[2], telemuj[2], bazuhom[2], bazumuj[2], benehom[2], benemuj[2], chathom[2],chatmuj[2] ],
				[ edades[3], alcoholhom[3], alcoholmuj[3], cervhom[3], cervmuj [3], sorthom[3], sortmuj[3], tabhom[3], tabmuj[3], telehom[3], telemuj[3], bazuhom[3], bazumuj[3], benehom[3], benemuj[3], chathom[3],chatmuj[3] ],
				[ edades[4], alcoholhom[4], alcoholmuj[4], cervhom[4], cervmuj [4], sorthom[4], sortmuj[4], tabhom[4], tabmuj[4], telehom[4], telemuj[4], bazuhom[4], bazumuj[4], benehom[4], benemuj[4], chathom[4],chatmuj[4] ],
				[ edades[5], alcoholhom[5], alcoholmuj[5], cervhom[5], cervmuj [5], sorthom[5], sortmuj[5], tabhom[5], tabmuj[5], telehom[5], telemuj[5], bazuhom[5], bazumuj[5], benehom[5], benemuj[5], chathom[5],chatmuj[5] ],
				[ edades[6], alcoholhom[6], alcoholmuj[6], cervhom[6], cervmuj [6], sorthom[6], sortmuj[6], tabhom[6], tabmuj[6], telehom[6], telemuj[6], bazuhom[6], bazumuj[6], benehom[6], benemuj[6], chathom[6],chatmuj[6] ],
				[ edades[7], alcoholhom[7], alcoholmuj[7], cervhom[7], cervmuj [7], sorthom[7], sortmuj[7], tabhom[7], tabmuj[7], telehom[7], telemuj[7], bazuhom[7], bazumuj[7], benehom[7], benemuj[7], chathom[7],chatmuj[7] ],
				[ edades[8], alcoholhom[8], alcoholmuj[8], cervhom[8], cervmuj [8], sorthom[8], sortmuj[8], tabhom[8], tabmuj[8], telehom[8], telemuj[8], bazuhom[8], bazumuj[8], benehom[8], benemuj[8], chathom[8],chatmuj[8] ],
				[ edades[9], alcoholhom[9], alcoholmuj[9], cervhom[9], cervmuj [9], sorthom[9], sortmuj[9], tabhom[9], tabmuj[9], telehom[9], telemuj[9], bazuhom[9], bazumuj[9], benehom[9], benemuj[9], chathom[9],chatmuj[9] ],
				[ edades[10], alcoholhom[10], alcoholmuj[10], cervhom[10], cervmuj [10], sorthom[10], sortmuj[10], tabhom[10], tabmuj[10], telehom[10], telemuj[10], bazuhom[10], bazumuj[10], benehom[10], benemuj[10], chathom[10],chatmuj[10] ],
				[ edades[11], alcoholhom[11], alcoholmuj[11], cervhom[11], cervmuj [11], sorthom[11], sortmuj[11], tabhom[11], tabmuj[11], telehom[11], telemuj[11], bazuhom[11], bazumuj[11], benehom[11], benemuj[11], chathom[11],chatmuj[11] ],
				[ edades[12], alcoholhom[12], alcoholmuj[12], cervhom[12], cervmuj [12], sorthom[12], sortmuj[12], tabhom[12], tabmuj[12], telehom[12], telemuj[12], bazuhom[12], bazumuj[12], benehom[12], benemuj[12], chathom[12],chatmuj[12] ],
				[ edades[13], alcoholhom[13], alcoholmuj[13], cervhom[13], cervmuj [13], sorthom[13], sortmuj[13], tabhom[13], tabmuj[13], telehom[13], telemuj[13], bazuhom[13], bazumuj[13], benehom[13], benemuj[13], chathom[13],chatmuj[13] ],
				[ edades[14], alcoholhom[14], alcoholmuj[14], cervhom[14], cervmuj [14], sorthom[14], sortmuj[14], tabhom[14], tabmuj[14], telehom[14], telemuj[14], bazuhom[14], bazumuj[14], benehom[14], benemuj[14], chathom[14],chatmuj[14] ],
				[ edades[15], alcoholhom[15], alcoholmuj[15], cervhom[15], cervmuj [15], sorthom[15], sortmuj[15], tabhom[15], tabmuj[15], telehom[15], telemuj[15], bazuhom[15], bazumuj[15], benehom[15], benemuj[15], chathom[15],chatmuj[15] ],
				[ edades[16], alcoholhom[16], alcoholmuj[16], cervhom[16], cervmuj [16], sorthom[16], sortmuj[16], tabhom[16], tabmuj[16], telehom[16], telemuj[16], bazuhom[16], bazumuj[16], benehom[16], benemuj[16], chathom[16],chatmuj[16] ],
				[ edades[17], alcoholhom[17], alcoholmuj[17], cervhom[17], cervmuj [17], sorthom[17], sortmuj[17], tabhom[17], tabmuj[17], telehom[17], telemuj[17], bazuhom[17], bazumuj[17], benehom[17], benemuj[17], chathom[17],chatmuj[17] ],
				[ edades[18], alcoholhom[18], alcoholmuj[18], cervhom[18], cervmuj [18], sorthom[18], sortmuj[18], tabhom[18], tabmuj[18], telehom[18], telemuj[18], bazuhom[18], bazumuj[18], benehom[18], benemuj[18], chathom[18],chatmuj[18] ],
				[ edades[19], alcoholhom[19], alcoholmuj[19], cervhom[19], cervmuj [19], sorthom[19], sortmuj[19], tabhom[19], tabmuj[19], telehom[19], telemuj[19], bazuhom[19], bazumuj[19], benehom[19], benemuj[19], chathom[19],chatmuj[19] ],
				[ edades[20], alcoholhom[20], alcoholmuj[20], cervhom[20], cervmuj [20], sorthom[20], sortmuj[20], tabhom[20], tabmuj[20], telehom[20], telemuj[20], bazuhom[20], bazumuj[20], benehom[20], benemuj[20], chathom[20],chatmuj[20] ] ,
				[ edades[21], alcoholhom[21], alcoholmuj[21], cervhom[21], cervmuj [21], sorthom[21], sortmuj[21], tabhom[21], tabmuj[21], telehom[21], telemuj[21], bazuhom[21], bazumuj[21], benehom[21], benemuj[21], chathom[21],chatmuj[21] ] 
 
				  
				]);
				
				var options = {
				  curveType:'function',
				  width: 900, 
				  height: 440,
				  focusTarget: 'category',
				  chartArea:{top:5, bottom:0, width:"68%", height:"78%"},
				  lineWidth: 3,
				  fontSize: 11,
				  colors:['#f5cd30', '#e8a729', '#e48227', '#e99378', '#e66e4c', '#df4f2d', '#7fbfdb', '#328e9b', '#25656f', '#9cde93', '#83ba7b'],
				  tooltip: {textStyle: {fontSize: 13}},
				  hAxis:{title: 'Edades',  titleTextStyle: {color: '#333', fontSize: 13}, textStyle: {color: '#686868'}},
				  vAxis:{title: 'Contribuyentes promedio', titleTextStyle: {color: '#333', fontSize: 13}, textStyle: {color: '#686868'}},
				  legend: {position:'right', alignment:'start', textStyle:{color: '#333', fontSize: 12}}
				};
		
				var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
				chart.draw(datas, options);

			/****************** Fin de carga de grafica google *************************/		


			var ii=0;
			for (i=0;i<fechas.length;i++) {
				ii=i+1;
				recaudacionGasto[i] = eval($(html).find("Lif"+ii).text());
			}
			var year =0;
			var lif = new Array(
				sumatoria(recaudacionGasto[year],0,45), sumatoria(recaudacionGasto[year],0,19),recaudacionGasto[year][0], 
				recaudacionGasto[year][0], recaudacionGasto[year][1],sumatoria(recaudacionGasto[year],2,12), recaudacionGasto[year][2], 
				sumatoria(recaudacionGasto[year],3,12),recaudacionGasto[year][3], recaudacionGasto[year][4], recaudacionGasto[year][5],
				recaudacionGasto[year][6], recaudacionGasto[year][7], recaudacionGasto[year][8], recaudacionGasto[year][9], recaudacionGasto[year][10],
				recaudacionGasto[year][11], recaudacionGasto[year][12], recaudacionGasto[year][13], recaudacionGasto[year][14], recaudacionGasto[year][14],	
				recaudacionGasto[year][15],recaudacionGasto[year][16], recaudacionGasto[year][17],	recaudacionGasto[year][18], recaudacionGasto[year][19],
				recaudacionGasto[year][20], sumatoria(recaudacionGasto[year],21,25), recaudacionGasto[year][21], recaudacionGasto[year][22], 
				recaudacionGasto[year][23], recaudacionGasto[year][24], recaudacionGasto[year][25], recaudacionGasto[year][26], recaudacionGasto[year][26], 
				sumatoria(recaudacionGasto[year],27,32), recaudacionGasto[year][27], recaudacionGasto[year][28], recaudacionGasto[year][29], 
				recaudacionGasto[year][30], recaudacionGasto[year][31], recaudacionGasto[year][32], sumatoria(recaudacionGasto[year],33,35), 
				recaudacionGasto[year][33], recaudacionGasto[year][34], recaudacionGasto[year][35], sumatoria(recaudacionGasto[year],36,37), 
				recaudacionGasto[year][36], recaudacionGasto[year][37], sumatoria(recaudacionGasto[year],38,43), sumatoria(recaudacionGasto[year],38,39),
				recaudacionGasto[year][38], recaudacionGasto[year][39], sumatoria(recaudacionGasto[year],40,42), recaudacionGasto[year][40], 
				recaudacionGasto[year][41], recaudacionGasto[year][42],recaudacionGasto[year][43], recaudacionGasto[year][44], recaudacionGasto[year][45],
				sumatoria(recaudacionGasto[year],0,45)			
				);
			var valores = lif.length;

			for(var i = 0; i< valores;i++) {
				ii=i+1;
				$('.recaudacionGasto'+ii+'-1').text('$ ' +formato(lif[i],true));	
				porcentaje  = lif[i] /Ingresos[year]*100;
				$('.recaudacionGasto'+ii).text( porcentaje.toFixed(2) + '%');	
			}


			},
			beforeSend: function () {
				$('.loading').css('visibility','visible');
				$('.loading').show();

			},		
			error: function(request,error) {
				console.log(arguments);
				console.log(request);
				alert ( " Can't do because: " + error +'\n'+html);
			}
		});
		

	});


		/*****************  envio de iva ************************/	
	$('#ivaSub').click(function () {		
//		alert('data');
		var ivaA1 = $('#ivaA1').val();
		var ivaA2 = $('#ivaA2').val();
		var ivaA3 = $('#ivaA3').val();
		var ivaCanasta =1;
		if($('#ivaCanasta2').is(":checked"))
			ivaCanasta =2;
		if($('#ivaCanasta3').is(":checked"))
			ivaCanasta =3;

		var ivaLeche =1;
		if($('#ivaLeche2').is(":checked"))
			ivaLeche =2;
		if($('#ivaLeche3').is(":checked"))
			ivaLeche =3;

		var ivaMedicinas =1;
		if($('#ivaMedicinas2').is(":checked"))
			ivaMedicinas =2;
		if($('#ivaMedicinas3').is(":checked"))
			ivaMedicinas =3;

		var ivaJarabe =1;
		if($('#ivaJarabe2').is(":checked"))
			ivaJarabe =2;
		if($('#ivaJarabe3').is(":checked"))
			ivaJarabe =3;

		var ivaTransUrbano =1;
		if($('#ivaTransUrbano2').is(":checked"))
			ivaTransUrbano =2;
		if($('#ivaTransUrbano3').is(":checked"))
			ivaTransUrbano =3;

		var ivaTransForaneo =1;
		if($('#ivaTransForaneo2').is(":checked"))
			ivaTransForaneo =2;
		if($('#ivaTransForaneo3').is(":checked"))
			ivaTransForaneo =3;

		var ivaEduPub =1;
		if($('#ivaEduPub2').is(":checked"))
			ivaEduPub =2;
		if($('#ivaEduPub3').is(":checked"))
			ivaEduPub =3;

		var ivaEduPrib =1;
		if($('#ivaEduPrib2').is(":checked"))
			ivaEduPrib =2;
		if($('#ivaEduPrib3').is(":checked"))
			ivaEduPrib =3;

		var ivaCRCasa =1;
		if($('#ivaCRCasa2').is(":checked"))
			ivaCRCasa =2;
		if($('#ivaCRCasa3').is(":checked"))
			ivaCRCasa =3;

		var ivaAlimentos =1;
		if($('#ivaAlimentos2').is(":checked"))
			ivaAlimentos =2;
		if($('#ivaAlimentos3').is(":checked"))
			ivaAlimentos =3;

		var ivaOtrosAlimentos =1;
		if($('#ivaOtrosAlimentos2').is(":checked"))
			ivaOtrosAlimentos =2;
		if($('#ivaOtrosAlimentos3').is(":checked"))
			ivaOtrosAlimentos =3;

		var ivaAlimentosMascotas =1;
		if($('#ivaAlimentosMascotas2').is(":checked"))
			ivaAlimentosMascotas =2;
		if($('#ivaAlimentosMascotas3').is(":checked"))
			ivaAlimentosMascotas =3;


		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 

		var ivaB1 = $('#ivaB1').val();
		var ivaB2 = $('#ivaB2').val();
		var ivaB3 = $('#ivaB3').val();
		var ivaB4 = $('#ivaB4').val();
		var ivaB5 = $('#ivaB5').val();
		var ivaB6 = $('#ivaB6').val();
		var ivaB7 = $('#ivaB7').val();
		var ivaB8 = $('#ivaB8').val();
		var ivaB9 = $('#ivaB9').val();
		var ivaB10 = $('#ivaB10').val();
		var ivaB11 = $('#ivaB11').val();
		var ivaB12 = $('#ivaB12').val();

		setCookie("idSession",idSession,1);
		
		var data = 'ivaA1=' + ivaA1 +'&ivaA2=' + ivaA2 + '&ivaA3=' + ivaA3 + '&ivaCanasta=' +ivaCanasta + '&ivaLeche=' +  ivaLeche+ '&ivaMedicinas=' +  ivaMedicinas+ '&ivaJarabe=' +  ivaJarabe+ '&ivaTransUrbano=' +  ivaTransUrbano+ '&ivaTransForaneo=' +  ivaTransForaneo+ '&ivaEduPub=' +  ivaEduPub+ '&ivaEduPrib=' +  ivaEduPrib+ '&ivaCRCasa=' +  ivaCRCasa+ '&ivaAlimentos=' +  ivaAlimentos+ '&ivaOtrosAlimentos=' +  ivaOtrosAlimentos+ '&ivaAlimentosMascotas=' +  ivaAlimentosMascotas+'&ivaB1=' + ivaB1 + '&ivaB2=' + ivaB2 + '&ivaB3=' + ivaB3 + '&ivaB4=' + ivaB4 + '&ivaB5=' + ivaB5 + '&ivaB6=' + ivaB6 + '&ivaB7=' + ivaB7 + '&ivaB8=' + ivaB8 + '&ivaB9=' + ivaB9 + '&ivaB10=' + ivaB10 + '&ivaB11=' + ivaB11+ '&ivaB12=' + ivaB12 +'&idSession='+idSession ;
		$.ajax({
			//this is the php file that processes the data and send mail
			url: "ivaStata.php",	
			
			async:false,

			//GET method is used
			type: "GET",

			//pass the data			
			data: data,		
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (html) {	
				$('.loading').css('visibility','hidden');
				$('.loading').hide();

				fechas = eval($(html).find("fecha").text()); 				
				var distribucion = eval($(html).find("distribucion").text());								
				var SHRFSP = eval($(html).find("SHRFSP").text());
				var RFSP = eval($(html).find("RFSP").text());
				var BalanceTrad = eval($(html).find("BalanceTrad").text());
				var IPAB = eval($(html).find("IPAB").text());
				var Adecuaciones = eval($(html).find("Adecuaciones").text());
				var FARAC = eval($(html).find("FARAC").text());
				var Deudores = eval($(html).find("Deudores").text());
				var Banca = eval($(html).find("Banca").text());
				var PIDIREGAS = eval($(html).find("PIDIREGAS").text());				
				
				var edades = eval($(html).find("edades").text()); 
				var perfivahom = eval($(html).find("perfivahom").text()); 
				var perfivamuj = eval($(html).find("perfivamuj").text()); 

				var ivapc = eval($(html).find("ivapc").text()); 
				var distribucion = eval($(html).find("distribucion").text()); 
				var propiva = eval($(html).find("propiva").text()); 


				Gini = eval($(html).find("Gini").text());				
				Gini=Gini[0];
				Ingresos = eval($(html).find("Ingresos").text());				
				Gastos = eval($(html).find("Gastos").text());				
				Deuda = eval($(html).find("Deuda").text());				
				var reciva = eval($(html).find("reciva").text()); 
				var pibiva = eval($(html).find("pibiva").text()); 

				for(var i =0;i<SHRFSP.length;i++) {
					SHRFSP[i]=-1*Number(SHRFSP[i]); 									
				}

				$('#ecuRGD').html('');
				
				for(var i =0;i<Ingresos.length;i++) {
					$("#ecuRGD").append('<option value='+i+'>'+fechas[i]+'</option>');
				}
				
				$('#recaudacionMPD').text(formato(Ingresos[0],true));
				$('#gastoMPD').text(formato(Gastos[0],true));
				$('#deudaMPD').text(formato(Deuda[0],true));
				$('#recaudacionProyectada').text(formato(reciva,true));
				$('#pibProyectado').text(pibiva);

				demoGauge.set(Gini*100); // función del velocimetro cambia valor
				$('.vel-val').text(Gini);

				for(var i=0;i<ivapc.length;i++) {
					actualizaItemtabla("#ivapc"+i,formato(ivapc[i],true));
					actualizaItemtablaString("#distribucion"+i,distribucion[i]," %");
					actualizaItemtablaString("#propiva"+i,propiva[i]," %");
				}
				
				
				/******************  Actualizar el gráfico de barras ***********/
				actualizaItemGrafPrima('13',SHRFSP[0],RFSP[0],BalanceTrad[0],IPAB[0],Adecuaciones[0],FARAC[0],Deudores[0],Banca[0],PIDIREGAS[0]);
				actualizaItemGrafPrima('14',SHRFSP[1],RFSP[1],BalanceTrad[1],IPAB[1],Adecuaciones[1],FARAC[1],Deudores[1],Banca[1],PIDIREGAS[1]);
				actualizaItemGrafPrima('15',SHRFSP[2],RFSP[2],BalanceTrad[2],IPAB[2],Adecuaciones[2],FARAC[2],Deudores[2],Banca[2],PIDIREGAS[2]);
				actualizaItemGrafPrima('16',SHRFSP[3],RFSP[3],BalanceTrad[3],IPAB[3],Adecuaciones[3],FARAC[3],Deudores[3],Banca[3],PIDIREGAS[3]);
				actualizaItemGrafPrima('17',SHRFSP[4],RFSP[4],BalanceTrad[4],IPAB[4],Adecuaciones[4],FARAC[4],Deudores[4],Banca[4],PIDIREGAS[4]);
				actualizaItemGrafPrima('18',SHRFSP[5],RFSP[5],BalanceTrad[5],IPAB[5],Adecuaciones[5],FARAC[5],Deudores[5],Banca[5],PIDIREGAS[5]);
				actualizaItemGrafPrima('19',SHRFSP[6],RFSP[6],BalanceTrad[6],IPAB[6],Adecuaciones[6],FARAC[6],Deudores[6],Banca[6],PIDIREGAS[6]);
				actualizaItemGrafPrima('20',SHRFSP[7],RFSP[7],BalanceTrad[7],IPAB[7],Adecuaciones[7],FARAC[7],Deudores[7],Banca[7],PIDIREGAS[7]);
				actualizaItemGrafPrima('21',SHRFSP[8],RFSP[8],BalanceTrad[8],IPAB[8],Adecuaciones[8],FARAC[8],Deudores[8],Banca[8],PIDIREGAS[8]);
				actualizaItemGrafPrima('22',SHRFSP[9],RFSP[9],BalanceTrad[9],IPAB[9],Adecuaciones[9],FARAC[9],Deudores[9],Banca[9],PIDIREGAS[9]);
				actualizaItemGrafPrima('23',SHRFSP[10],RFSP[10],BalanceTrad[10],IPAB[10],Adecuaciones[10],FARAC[10],Deudores[10],Banca[10],PIDIREGAS[10]);
				actualizaItemGrafPrima('24',SHRFSP[11],RFSP[11],BalanceTrad[11],IPAB[11],Adecuaciones[11],FARAC[11],Deudores[11],Banca[11],PIDIREGAS[11]);
				actualizaItemGrafPrima('25',SHRFSP[12],RFSP[12],BalanceTrad[12],IPAB[12],Adecuaciones[12],FARAC[12],Deudores[12],Banca[12],PIDIREGAS[12]);
				positionBars();
				positionBars2();

					/*************************  Recargar el gráfico de google ********************/
				var datas = google.visualization.arrayToDataTable([
				  ['Edades', 'Hombres', 'Mujeres'],
					[edades[0], perfivahom[0], perfivamuj[0]],
					[edades[1], perfivahom[1], perfivamuj[1]],
					[edades[2], perfivahom[2], perfivamuj[2]],
					[edades[3], perfivahom[3], perfivamuj[3]],
					[edades[4], perfivahom[4], perfivamuj[4]],
					[edades[5], perfivahom[5], perfivamuj[5]],
					[edades[6], perfivahom[6], perfivamuj[6]],
					[edades[7], perfivahom[7], perfivamuj[7]],
					[edades[8], perfivahom[8], perfivamuj[8]],
					[edades[9], perfivahom[9], perfivamuj[9]],
					[edades[10], perfivahom[10], perfivamuj[10]],
					[edades[11], perfivahom[11], perfivamuj[11]],
					[edades[12], perfivahom[12], perfivamuj[12]],
					[edades[13], perfivahom[13], perfivamuj[13]],
					[edades[14], perfivahom[14], perfivamuj[14]],
					[edades[15], perfivahom[15], perfivamuj[15]],
					[edades[16], perfivahom[16], perfivamuj[16]],
					[edades[17], perfivahom[17], perfivamuj[17]],
					[edades[18], perfivahom[18], perfivamuj[18]],
					[edades[19], perfivahom[19], perfivamuj[19]]
				]);
				
			var options = {
			  curveType:'function',
			  width: 660, 
			  height: 328,
			  focusTarget: 'category',
			  chartArea:{top:5, bottom:0, width:"68%", height:"78%"},
			  lineWidth: 3,
			  fontSize: 11,
			  colors:['#38919c', '#fc782d'],
			  tooltip: {textStyle: {fontSize: 13}},
			  hAxis:{title: 'Edades',  titleTextStyle: {color: '#333', fontSize: 13}, textStyle: {color: '#686868'}},
			  vAxis:{title: 'Contribuyentes promedio', titleTextStyle: {color: '#333', fontSize: 13}, textStyle: {color: '#686868'}},
			  legend: {position:'right', alignment:'start', textStyle:{color: '#333', fontSize: 12}}
			};
	
			var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
			chart.draw(datas, options);
				
			/****************** Fin de carga de grafica google *************************/		


			var ii=0;
			for (i=0;i<fechas.length;i++) {
				ii=i+1;
				recaudacionGasto[i] = eval($(html).find("Lif"+ii).text());
			}
			var year =0;
			var lif = new Array(
				sumatoria(recaudacionGasto[year],0,45), sumatoria(recaudacionGasto[year],0,19),recaudacionGasto[year][0], 
				recaudacionGasto[year][0], recaudacionGasto[year][1],sumatoria(recaudacionGasto[year],2,12), recaudacionGasto[year][2], 
				sumatoria(recaudacionGasto[year],3,12),recaudacionGasto[year][3], recaudacionGasto[year][4], recaudacionGasto[year][5],
				recaudacionGasto[year][6], recaudacionGasto[year][7], recaudacionGasto[year][8], recaudacionGasto[year][9], recaudacionGasto[year][10],
				recaudacionGasto[year][11], recaudacionGasto[year][12], recaudacionGasto[year][13], recaudacionGasto[year][14], recaudacionGasto[year][14],	
				recaudacionGasto[year][15],recaudacionGasto[year][16], recaudacionGasto[year][17],	recaudacionGasto[year][18], recaudacionGasto[year][19],
				recaudacionGasto[year][20], sumatoria(recaudacionGasto[year],21,25), recaudacionGasto[year][21], recaudacionGasto[year][22], 
				recaudacionGasto[year][23], recaudacionGasto[year][24], recaudacionGasto[year][25], recaudacionGasto[year][26], recaudacionGasto[year][26], 
				sumatoria(recaudacionGasto[year],27,32), recaudacionGasto[year][27], recaudacionGasto[year][28], recaudacionGasto[year][29], 
				recaudacionGasto[year][30], recaudacionGasto[year][31], recaudacionGasto[year][32], sumatoria(recaudacionGasto[year],33,35), 
				recaudacionGasto[year][33], recaudacionGasto[year][34], recaudacionGasto[year][35], sumatoria(recaudacionGasto[year],36,37), 
				recaudacionGasto[year][36], recaudacionGasto[year][37], sumatoria(recaudacionGasto[year],38,43), sumatoria(recaudacionGasto[year],38,39),
				recaudacionGasto[year][38], recaudacionGasto[year][39], sumatoria(recaudacionGasto[year],40,42), recaudacionGasto[year][40], 
				recaudacionGasto[year][41], recaudacionGasto[year][42],recaudacionGasto[year][43], recaudacionGasto[year][44], recaudacionGasto[year][45],
				sumatoria(recaudacionGasto[year],0,45)			
				);
			var valores = lif.length;

			for(var i = 0; i< valores;i++) {
				ii=i+1;
				$('.recaudacionGasto'+ii+'-1').text('$ ' +formato(lif[i],true));	
				porcentaje  = lif[i] /Ingresos[year]*100;
				$('.recaudacionGasto'+ii).text( porcentaje.toFixed(2) + '%');	
			}


			},
			beforeSend: function () {

				$('.loading').css('visibility','visible');
				$('.loading').show();
				
				alert("El proceso de cálculo de I.V.A. puede durar hasta un minuto.");
				

//	                alert(makeid());
			},		
			error: function(request,error) {
				console.log(arguments);
				console.log(request);
				alert ( " Can't do because: " + error +'\n'+html);
			}
		});
		
		//cancel the submit button default behaviours

	});


		/*****************  envio de isr morales	 ************************/	
	$('#isrMoralesSub').click(function () {		
		var isrMoralesA1 = $('#isrMoralesA1');
		var isrMoralesA2 = $('#isrMoralesA2');
		var isrMoralesA3 = $('#isrMoralesA3');
		var isrMoralesA4 = $('#isrMoralesA4');
//		alert($('#isrMoralesC1').is(":checked") +" "+ $('#isrMoralesC2').is(":checked")+" "+$('#isrMoralesC3').is(":checked")+" "+$('#isrMoralesC4').is(":checked"));
		var isrMoralesC1 = ($('#isrMoralesC1').is(":checked")?1:0);
		var isrMoralesC2 = ($('#isrMoralesC2').is(":checked")?1:0);
		var isrMoralesC3 = ($('#isrMoralesC3').is(":checked")?1:0);
		var isrMoralesC4 = ($('#isrMoralesC4').is(":checked")?1:0);
		var si = ($('#si').is(":checked")?1:0);

//		alert('Cookie: '+getCookie("idSession"));
		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);
		
		var data = 'isrMoralesA1=' + isrMoralesA1.val() + '&isrMoralesA2=' + isrMoralesA2.val() + '&isrMoralesA3=' + isrMoralesA3.val() + '&isrMoralesA4=' + isrMoralesA4.val() + '&isrMoralesC1=' + isrMoralesC1 + '&isrMoralesC2=' + isrMoralesC2 + '&isrMoralesC3=' + isrMoralesC3 + '&isrMoralesC4=' + isrMoralesC4+ '&si=' + si +'&idSession='+idSession ;

		//start the ajax
		$.ajax({
			//this is the php file that processes the data and send mail
			url: "isrPmorales.php",	
			
			async:false,

			//GET method is used
			type: "GET",

			//pass the data			
			data: data,		
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (html) {	
//				alert('se recibio\n' + html);
				$('.loading').css('visibility','hidden');
				$('.loading').hide();
				

				fechas = eval($(html).find("fecha").text()); 				
				var distribucion = eval($(html).find("distribucion").text());								
				var SHRFSP = eval($(html).find("SHRFSP").text());
				var RFSP = eval($(html).find("RFSP").text());
				var BalanceTrad = eval($(html).find("BalanceTrad").text());
				var IPAB = eval($(html).find("IPAB").text());
				var Adecuaciones = eval($(html).find("Adecuaciones").text());
				var FARAC = eval($(html).find("FARAC").text());
				var Deudores = eval($(html).find("Deudores").text());
				var Banca = eval($(html).find("Banca").text());
				var PIDIREGAS = eval($(html).find("PIDIREGAS").text());				
				Gini = eval($(html).find("Gini").text());				
				Gini=Gini[0];
				Ingresos = eval($(html).find("Ingresos").text());				
				Gastos = eval($(html).find("Gastos").text());				
				Deuda = eval($(html).find("Deuda").text());				
				var recisr = eval($(html).find("recisrpm").text()); 
				var pibisr_pm = eval($(html).find("pibisr_pm").text()); 

				var edades = eval($(html).find("edades").text()); 
				var perfisrmhom = eval($(html).find("perfisrmhom").text()); 
				var perfisrmmuj = eval($(html).find("perfisrmmuj").text()); 

				var isrsecdis = eval($(html).find("isrsecdis").text()); 
				var isrsec = eval($(html).find("isrsec").text()); 

				for(var i =0;i<SHRFSP.length;i++) {
					SHRFSP[i]=-1*Number(SHRFSP[i]); 									
				}

				$('#ecuRGD').html('');
				
				for(var i =0;i<Ingresos.length;i++) {
					$("#ecuRGD").append('<option value='+i+'>'+fechas[i]+'</option>');
				}
				
				$('#recaudacionMPD').text(formato(Ingresos[0],true));
				$('#gastoMPD').text(formato(Gastos[0],true));
				$('#deudaMPD').text(formato(Deuda[0],true));
				$('#recaudacionProyectada').text(formato(recisr,true));
				$('#pibProyectado').text(pibisr_pm);

				demoGauge.set(Gini*100); // función del velocimetro cambia valor
				$('.vel-val').text(Gini);


				/******************  Actualizar el gráfico de barras ***********/
				actualizaItemGrafPrima('13',SHRFSP[0],RFSP[0],BalanceTrad[0],IPAB[0],Adecuaciones[0],FARAC[0],Deudores[0],Banca[0],PIDIREGAS[0]);
				actualizaItemGrafPrima('14',SHRFSP[1],RFSP[1],BalanceTrad[1],IPAB[1],Adecuaciones[1],FARAC[1],Deudores[1],Banca[1],PIDIREGAS[1]);
				actualizaItemGrafPrima('15',SHRFSP[2],RFSP[2],BalanceTrad[2],IPAB[2],Adecuaciones[2],FARAC[2],Deudores[2],Banca[2],PIDIREGAS[2]);
				actualizaItemGrafPrima('16',SHRFSP[3],RFSP[3],BalanceTrad[3],IPAB[3],Adecuaciones[3],FARAC[3],Deudores[3],Banca[3],PIDIREGAS[3]);
				actualizaItemGrafPrima('17',SHRFSP[4],RFSP[4],BalanceTrad[4],IPAB[4],Adecuaciones[4],FARAC[4],Deudores[4],Banca[4],PIDIREGAS[4]);
				actualizaItemGrafPrima('18',SHRFSP[5],RFSP[5],BalanceTrad[5],IPAB[5],Adecuaciones[5],FARAC[5],Deudores[5],Banca[5],PIDIREGAS[5]);
				actualizaItemGrafPrima('19',SHRFSP[6],RFSP[6],BalanceTrad[6],IPAB[6],Adecuaciones[6],FARAC[6],Deudores[6],Banca[6],PIDIREGAS[6]);
				actualizaItemGrafPrima('20',SHRFSP[7],RFSP[7],BalanceTrad[7],IPAB[7],Adecuaciones[7],FARAC[7],Deudores[7],Banca[7],PIDIREGAS[7]);
				actualizaItemGrafPrima('21',SHRFSP[8],RFSP[8],BalanceTrad[8],IPAB[8],Adecuaciones[8],FARAC[8],Deudores[8],Banca[8],PIDIREGAS[8]);
				actualizaItemGrafPrima('22',SHRFSP[9],RFSP[9],BalanceTrad[9],IPAB[9],Adecuaciones[9],FARAC[9],Deudores[9],Banca[9],PIDIREGAS[9]);
				actualizaItemGrafPrima('23',SHRFSP[10],RFSP[10],BalanceTrad[10],IPAB[10],Adecuaciones[10],FARAC[10],Deudores[10],Banca[10],PIDIREGAS[10]);
				actualizaItemGrafPrima('24',SHRFSP[11],RFSP[11],BalanceTrad[11],IPAB[11],Adecuaciones[11],FARAC[11],Deudores[11],Banca[11],PIDIREGAS[11]);
				actualizaItemGrafPrima('25',SHRFSP[12],RFSP[12],BalanceTrad[12],IPAB[12],Adecuaciones[12],FARAC[12],Deudores[12],Banca[12],PIDIREGAS[12]);
				positionBars();
				positionBars2();

				var ii=0;
				for(var i=0;i<isrsecdis.length;i++) {
					ii=i+1;
					actualizaItemtablaString("#isrPMIncidenciasR"+ii,isrsecdis[i]," %");
					actualizaItemtabla("#isrPMIncidenciasD"+ii,formato(isrsec[i],true));
				}
			/*********  Fin a la actualizacion de tabla ********/
					/*************************  Recargar el gráfico de google ********************/
			/****************** Fin de carga de grafica google *************************/		

			var ii=0;
			for (i=0;i<fechas.length;i++) {
				ii=i+1;
				recaudacionGasto[i] = eval($(html).find("Lif"+ii).text());
			}
			var year =0;
			var lif = new Array(
				sumatoria(recaudacionGasto[year],0,45), sumatoria(recaudacionGasto[year],0,19),recaudacionGasto[year][0], 
				recaudacionGasto[year][0], recaudacionGasto[year][1],sumatoria(recaudacionGasto[year],2,12), recaudacionGasto[year][2], 
				sumatoria(recaudacionGasto[year],3,12),recaudacionGasto[year][3], recaudacionGasto[year][4], recaudacionGasto[year][5],
				recaudacionGasto[year][6], recaudacionGasto[year][7], recaudacionGasto[year][8], recaudacionGasto[year][9], recaudacionGasto[year][10],
				recaudacionGasto[year][11], recaudacionGasto[year][12], recaudacionGasto[year][13], recaudacionGasto[year][14], recaudacionGasto[year][14],	
				recaudacionGasto[year][15],recaudacionGasto[year][16], recaudacionGasto[year][17],	recaudacionGasto[year][18], recaudacionGasto[year][19],
				recaudacionGasto[year][20], sumatoria(recaudacionGasto[year],21,25), recaudacionGasto[year][21], recaudacionGasto[year][22], 
				recaudacionGasto[year][23], recaudacionGasto[year][24], recaudacionGasto[year][25], recaudacionGasto[year][26], recaudacionGasto[year][26], 
				sumatoria(recaudacionGasto[year],27,32), recaudacionGasto[year][27], recaudacionGasto[year][28], recaudacionGasto[year][29], 
				recaudacionGasto[year][30], recaudacionGasto[year][31], recaudacionGasto[year][32], sumatoria(recaudacionGasto[year],33,35), 
				recaudacionGasto[year][33], recaudacionGasto[year][34], recaudacionGasto[year][35], sumatoria(recaudacionGasto[year],36,37), 
				recaudacionGasto[year][36], recaudacionGasto[year][37], sumatoria(recaudacionGasto[year],38,43), sumatoria(recaudacionGasto[year],38,39),
				recaudacionGasto[year][38], recaudacionGasto[year][39], sumatoria(recaudacionGasto[year],40,42), recaudacionGasto[year][40], 
				recaudacionGasto[year][41], recaudacionGasto[year][42],recaudacionGasto[year][43], recaudacionGasto[year][44], recaudacionGasto[year][45],
				sumatoria(recaudacionGasto[year],0,45)			
				);
			var valores = lif.length;

			for(var i = 0; i< valores;i++) {
				ii=i+1;
				$('.recaudacionGasto'+ii+'-1').text('$ ' +formato(lif[i],true));	
				porcentaje  = lif[i] /Ingresos[year]*100;
				$('.recaudacionGasto'+ii).text( porcentaje.toFixed(2) + '%');	
			}


			},
			beforeSend: function () {
//				alert("se ejecuta antes de mandar");
				$('.loading').css('visibility','visible');
				$('.loading').show();
				
				
				

//	                alert(makeid());
			},		
			error: function(request,error) {
				console.log(arguments);
				console.log(request);
				alert ( " Can't do because: " + error +'\n'+html);
			}
		});
		
		//cancel the submit button default behaviours
		return false;
	});	


	/*****************  envio de isr ************************/	
	$('#envio2').click(function () {		
		//Get the data from all the fields

		//Simple validation to make sure user entered something
		//If error found, add hightlight class to the text field

		var ISR1x4 = $('#ISR1x4');
		var ISR2x4 = $('#ISR2x4');
		var ISR3x4 = $('#ISR3x4');
		var ISR4x4 = $('#ISR4x4');
		var ISR5x4 = $('#ISR5x4');
		var ISR6x4 = $('#ISR6x4');
		var ISR7x4 = $('#ISR7x4');
		var ISR8x4 = $('#ISR8x4');
		var ISR9x4 = $('#ISR9x4');

		var ISRB1x3 = $('#ISRB1x3');
		var ISRB2x3 = $('#ISRB2x3');
		var ISRB3x3 = $('#ISRB3x3');
		var ISRB4x3 = $('#ISRB4x3');
		var ISRB5x3 = $('#ISRB5x3');
		var ISRB6x3 = $('#ISRB6x3');
		var ISRB7x3 = $('#ISRB7x3');
		var ISRB8x3 = $('#ISRB8x3');
		var ISRB9x3 = $('#ISRB9x3');
		var ISRB10x3 = $('#ISRB10x3');
		var ISRB11x3 = $('#ISRB11x3');
		var ISRB12x3 = $('#ISRB12x3');
		
		var ISRE1x2 = $('#ISRE1x2');
		var ISRE2x2 = $('#ISRE2x2');
		var ISRE3x2 = $('#ISRE3x2');
		var ISRE4x2 = $('#ISRE4x2');
		var ISRE5x2 = $('#ISRE5x2');
		var ISRE6x2 = $('#ISRE6x2');
		var ISRE7x2 = $('#ISRE7x2');
		var ISRE8x2 = $('#ISRE8x2');

		var ISROP1x1 = $('#ISROP1x1');
		var ISROP1x2 = $('#ISROP1x2');
		var deducciones = ($('#deducciones').is(":checked")?1:0);


		//organize the data properly /// arreglar lo de existencia de cookie no genere una nueva
		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);
		
		var data = 'ISR1x4=' + ISR1x4.val() + '&ISR2x4=' + ISR2x4.val() + '&ISR3x4=' + ISR3x4.val() + '&ISR4x4=' + ISR4x4.val() + '&ISR5x4=' + ISR5x4.val() + '&ISR6x4=' + ISR6x4.val() + '&ISR7x4=' + ISR7x4.val() + '&ISR8x4=' + ISR8x4.val() + '&ISR9x4=' + ISR9x4.val() + '&ISRB1x3=' + ISRB1x3.val() + '&ISRB2x3=' + ISRB2x3.val() + '&ISRB3x3=' + ISRB3x3.val() + '&ISRB4x3=' + ISRB4x3.val() + '&ISRB5x3=' + ISRB5x3.val() + '&ISRB6x3=' + ISRB6x3.val() + '&ISRB7x3=' + ISRB7x3.val() + '&ISRB8x3=' + ISRB8x3.val() + '&ISRB9x3=' + ISRB9x3.val() + '&ISRB10x3=' + ISRB10x3.val() + '&ISRB11x3=' + ISRB11x3.val() + '&ISRB12x3=' + ISRB12x3.val() + '&ISRE1x2=' + ISRE1x2.val() + '&ISRE2x2=' + ISRE2x2.val() + '&ISRE3x2=' + ISRE3x2.val() + '&ISRE4x2=' + ISRE4x2.val() + '&ISRE5x2=' + ISRE5x2.val() + '&ISRE6x2=' + ISRE6x2.val()  + '&ISRE7x2=' + ISRE7x2.val()  + '&ISRE8x2=' + ISRE8x2.val()  + '&ISROP1x1=' + ISROP1x1.val()  + '&ISROP1x2=' + ISROP1x2.val() +'&deducciones=' + deducciones +'&idSession='+idSession ;
						

		//start the ajax
		$.ajax({
			//this is the php file that processes the data and send mail
			url: "isr.php",	
			
			async:false,

			//GET method is used
			type: "GET",

			//pass the data			
			data: data,		
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (html) {	
//					alert(html);
					
					if(html != 1) {	// regresa 1 en caso de error 1/false


					$('.loading').css('visibility','hidden');
				
					fechas = eval($(html).find("fecha").text()); 				
					var distribucion = eval($(html).find("distribucion").text());								
					var SHRFSP = eval($(html).find("SHRFSP").text());
					var RFSP = eval($(html).find("RFSP").text());
					var BalanceTrad = eval($(html).find("BalanceTrad").text());
					var IPAB = eval($(html).find("IPAB").text());
					var Adecuaciones = eval($(html).find("Adecuaciones").text());
					var FARAC = eval($(html).find("FARAC").text());
					var Deudores = eval($(html).find("Deudores").text());
					var Banca = eval($(html).find("Banca").text());
					var PIDIREGAS = eval($(html).find("PIDIREGAS").text());				
					var Pobres = eval($(html).find("Pobres").text());				
					var Nopobres = eval($(html).find("Nopobres").text());				
					Gini = eval($(html).find("Gini").text());				
					Gini=Gini[0];
					Ingresos = eval($(html).find("Ingresos").text());				
					Gastos = eval($(html).find("Gastos").text());				
					Deuda = eval($(html).find("Deuda").text());				

					var isrpc = eval($(html).find("isrpc").text());					
					var te=eval($(html).find("te").text());
					
					var edades=eval($(html).find("edades").text());
					var perfisrfhom=eval($(html).find("perfisrfhom").text());
					var perfisrfmuj=eval($(html).find("perfisrfmuj").text());
					var recisr = eval($(html).find("recisr").text()); 
					var pibisr = eval($(html).find("pibisr").text()); 

					
					for(var i =0;i<SHRFSP.length;i++) {
						SHRFSP[i]=-1*Number(SHRFSP[i]); 									
					}
	
					$('#ecuRGD').html('');
					
					for(var i =0;i<Ingresos.length;i++) {
						$("#ecuRGD").append('<option value='+i+'>'+fechas[i]+'</option>');
					}
					$('#recaudacionMPD').text(formato(Ingresos[0],true));
					$('#gastoMPD').text(formato(Gastos[0],true));
					$('#deudaMPD').text(formato(Deuda[0],true));
					$('#recaudacionProyectada').text(formato(recisr,true));
					$('#pibProyectado').text(pibisr);

	
					/******************  Actualizar el gráfico de barras ***********/
					actualizaItemGrafPrima('13',SHRFSP[0],RFSP[0],BalanceTrad[0],IPAB[0],Adecuaciones[0],FARAC[0],Deudores[0],Banca[0],PIDIREGAS[0]);
					actualizaItemGrafPrima('14',SHRFSP[1],RFSP[1],BalanceTrad[1],IPAB[1],Adecuaciones[1],FARAC[1],Deudores[1],Banca[1],PIDIREGAS[1]);
					actualizaItemGrafPrima('15',SHRFSP[2],RFSP[2],BalanceTrad[2],IPAB[2],Adecuaciones[2],FARAC[2],Deudores[2],Banca[2],PIDIREGAS[2]);
					actualizaItemGrafPrima('16',SHRFSP[3],RFSP[3],BalanceTrad[3],IPAB[3],Adecuaciones[3],FARAC[3],Deudores[3],Banca[3],PIDIREGAS[3]);
					actualizaItemGrafPrima('17',SHRFSP[4],RFSP[4],BalanceTrad[4],IPAB[4],Adecuaciones[4],FARAC[4],Deudores[4],Banca[4],PIDIREGAS[4]);
					actualizaItemGrafPrima('18',SHRFSP[5],RFSP[5],BalanceTrad[5],IPAB[5],Adecuaciones[5],FARAC[5],Deudores[5],Banca[5],PIDIREGAS[5]);
					actualizaItemGrafPrima('19',SHRFSP[6],RFSP[6],BalanceTrad[6],IPAB[6],Adecuaciones[6],FARAC[6],Deudores[6],Banca[6],PIDIREGAS[6]);
					actualizaItemGrafPrima('20',SHRFSP[7],RFSP[7],BalanceTrad[7],IPAB[7],Adecuaciones[7],FARAC[7],Deudores[7],Banca[7],PIDIREGAS[7]);
					actualizaItemGrafPrima('21',SHRFSP[8],RFSP[8],BalanceTrad[8],IPAB[8],Adecuaciones[8],FARAC[8],Deudores[8],Banca[8],PIDIREGAS[8]);
					actualizaItemGrafPrima('22',SHRFSP[9],RFSP[9],BalanceTrad[9],IPAB[9],Adecuaciones[9],FARAC[9],Deudores[9],Banca[9],PIDIREGAS[9]);
					actualizaItemGrafPrima('23',SHRFSP[10],RFSP[10],BalanceTrad[10],IPAB[10],Adecuaciones[10],FARAC[10],Deudores[10],Banca[10],PIDIREGAS[10]);
					actualizaItemGrafPrima('24',SHRFSP[11],RFSP[11],BalanceTrad[11],IPAB[11],Adecuaciones[11],FARAC[11],Deudores[11],Banca[11],PIDIREGAS[11]);
					actualizaItemGrafPrima('25',SHRFSP[12],RFSP[12],BalanceTrad[12],IPAB[12],Adecuaciones[12],FARAC[12],Deudores[12],Banca[12],PIDIREGAS[12]);
					positionBars();
					positionBars2();

					
					/*************************  Recargar el gráfico de velocimetro *********************/
						var datas = google.visualization.arrayToDataTable([
	  ['Edades', 'Hombres', 'Mujeres'],
        [edades[0], perfisrfhom[0], perfisrfmuj[0]],
        [edades[1], perfisrfhom[1], perfisrfmuj[1]],
        [edades[2], perfisrfhom[2], perfisrfmuj[2]],
        [edades[3], perfisrfhom[3], perfisrfmuj[3]],
        [edades[4], perfisrfhom[4], perfisrfmuj[4]],
        [edades[5], perfisrfhom[5], perfisrfmuj[5]],
        [edades[6], perfisrfhom[6], perfisrfmuj[6]],
        [edades[7], perfisrfhom[7], perfisrfmuj[7]],
        [edades[8], perfisrfhom[8], perfisrfmuj[8]],
        [edades[9], perfisrfhom[9], perfisrfmuj[9]],
        [edades[10], perfisrfhom[10], perfisrfmuj[10]],
        [edades[11], perfisrfhom[11], perfisrfmuj[11]],
        [edades[12], perfisrfhom[12], perfisrfmuj[12]],
        [edades[13], perfisrfhom[13], perfisrfmuj[13]],
        [edades[14], perfisrfhom[14], perfisrfmuj[14]],
        [edades[15], perfisrfhom[15], perfisrfmuj[15]],
        [edades[16], perfisrfhom[16], perfisrfmuj[16]],
        [edades[17], perfisrfhom[17], perfisrfmuj[17]],
        [edades[18], perfisrfhom[18], perfisrfmuj[18]],
        [edades[19], perfisrfhom[19], perfisrfmuj[19]]
	]);
	
	var options = {
	  curveType:'function',
	  width: 660, 
	  height: 328,
	  focusTarget: 'category',
	  chartArea:{top:5, bottom:0, width:"68%", height:"78%"},
	  lineWidth: 3,
	  fontSize: 11,
	  colors:['#38919c', '#fc782d'],
	  tooltip: {textStyle: {fontSize: 13}},
	  hAxis:{title: 'Edades',  titleTextStyle: {color: '#333', fontSize: 13}, textStyle: {color: '#686868'}},
	  vAxis:{title: 'Contribuyentes promedio', titleTextStyle: {color: '#333', fontSize: 13}, textStyle: {color: '#686868'}},
	  legend: {position:'right', alignment:'start', textStyle:{color: '#333', fontSize: 12}}
	};
	
		var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
		chart.draw(datas, options);
						
		/*************************  Recargar el gráfico de velocimetro **********************/
				demoGauge.set(Gini*100); // función del velocimetro cambia valor
				$('.vel-val').text(Gini);


				for(var i=0;i<isrpc.length;i++) {
					actualizaItemtabla("#isrpc"+i,formato(isrpc[i],true));
					actualizaItemtablaString("#distribucion"+i,distribucion[i]," %");
					actualizaItemtablaString("#te"+i,te[i]," %");
				}

			var ii=0;
			for (i=0;i<fechas.length;i++) {
				ii=i+1;
				recaudacionGasto[i] = eval($(html).find("Lif"+ii).text());
			}
			var year =0;
			var lif = new Array(
				sumatoria(recaudacionGasto[year],0,44), sumatoria(recaudacionGasto[year],0,19),recaudacionGasto[year][0], 
				recaudacionGasto[year][0], recaudacionGasto[year][1],sumatoria(recaudacionGasto[year],2,12), recaudacionGasto[year][2], 
				sumatoria(recaudacionGasto[year],3,11),recaudacionGasto[year][3], recaudacionGasto[year][4], recaudacionGasto[year][5], 
				recaudacionGasto[year][6], recaudacionGasto[year][7], recaudacionGasto[year][8], recaudacionGasto[year][9], recaudacionGasto[year][10],
				recaudacionGasto[year][11], recaudacionGasto[year][12], recaudacionGasto[year][13], recaudacionGasto[year][13], recaudacionGasto[year][14],
				recaudacionGasto[year][15], recaudacionGasto[year][16],	recaudacionGasto[year][17], recaudacionGasto[year][18], recaudacionGasto[year][19], 
				sumatoria(recaudacionGasto[year],20,24), recaudacionGasto[year][20], recaudacionGasto[year][21], recaudacionGasto[year][22], 
				recaudacionGasto[year][23], recaudacionGasto[year][24], recaudacionGasto[year][25], recaudacionGasto[year][25], 
				sumatoria(recaudacionGasto[year],26,31), recaudacionGasto[year][26], recaudacionGasto[year][27], recaudacionGasto[year][28], 
				recaudacionGasto[year][29], recaudacionGasto[year][30], recaudacionGasto[year][31], sumatoria(recaudacionGasto[year],32,34), 
				recaudacionGasto[year][32], recaudacionGasto[year][33], recaudacionGasto[year][34], sumatoria(recaudacionGasto[year],35,36), 
				recaudacionGasto[year][35], recaudacionGasto[year][36], sumatoria(recaudacionGasto[year],37,42), sumatoria(recaudacionGasto[year],37,38),
				recaudacionGasto[year][37], recaudacionGasto[year][38], sumatoria(recaudacionGasto[year],39,41), recaudacionGasto[year][39], 
				recaudacionGasto[year][40], recaudacionGasto[year][41],recaudacionGasto[year][42], recaudacionGasto[year][43], recaudacionGasto[year][44],
				sumatoria(recaudacionGasto[year],0,44)			
				);
			var valores = lif.length;

			for(var i = 0; i< valores;i++) {
				ii=i+1;
				$('.recaudacionGasto'+ii+'-1').text('$ ' +formato(lif[i],true));	
				porcentaje  = lif[i] /Ingresos[year]*100;
				$('.recaudacionGasto'+ii).text( porcentaje.toFixed(2) + '%');	
			}
							
					
				} 
			},
			beforeSend: function () {
	//			alert("pruebas antes de enviar");
				$('.loading').show(0);
				//$('.loading').fadeIn();
				$('.loading').css('visibility','visible');
				
				alert("El proceso de cálculo de I.S.R. de personas físicas puede durar hasta un minuto.");


//	                alert(makeid());
			},		
			error: function(request,error) {
				console.log(arguments);
				console.log(request);
				alert ( " Can't do because: " + error );
			}
		});
		
		//cancel the submit button default behaviours
		return false;
//		return true;
	});	
	
	
	
	$('.inputIsrNeg').blur(function () {		
		
		var ISR1x = $(this);
		var m = ISR1x.val();
		var n = m.replace(/^\s+|\s+$/g, '');
		var bSub = document.getElementById('envio2');

		if (esnumeroConNeg(n)) {
			ISR1x.removeClass('errorInput');
			var i=true;
			$(".inputIsr").each(function() {
				if(!esnumeroConNeg($(this).val())) {
					i=false; 
				}
			});
			if(i) $('input[type=submit]').css("visibility","visible");
		} else {
			ISR1x.addClass('errorInput');
			$('input[type=submit]').css("visibility","hidden");
		}

				
	});

	
	$('.inputIsr').blur(function () {		
		
		var ISR1x = $(this);
		var m = ISR1x.val();
		var n = m.replace(/^\s+|\s+$/g, '');
		var bSub = document.getElementById('envio2');

		if (esnumero(n)) {
			ISR1x.removeClass('errorInput');
			var i=true;
			$(".inputIsr").each(function() {
				if(!esnumero($(this).val())) {
					i=false; 
				}
			});
			if(i) $('input[type=submit]').css("visibility","visible");
		} else {
			ISR1x.addClass('errorInput');
			$('input[type=submit]').css("visibility","hidden");
		}

				
	});
	
	$('.isrIngresos').blur(function () {		
		var ISRB1x = $(this);
		switch (ISRB1x.attr('id')) {
			case $('#ISRB1x3').attr('id'):
				if(!entreIntervalo($('#ISRB2x3').val(),ISRB1x.val(),"100000"))	{
					$('#tablaisrbCaption').text("Corrija el valor de la tabla su valor no es valido:" +ISRB1x.val() +
					"\nSu valor debe ser mayor a "+$('#ISRB2x3').val());
					$('#tablaisrbCaption').css("display","block");
					$('#tablaisrbCaption').css("visibility","visible");
				} else {
					$('#tablaisrbCaption').css("display","none");
					$('#tablaisrbCaption').css("visibility","hidden");
				}
			break;
			case $('#ISRB2x3').attr('id'):
				if(!entreIntervalo($('#ISRB3x3').val(),ISRB1x.val(),$('#ISRB1x3').val()))	{
					$('#tablaisrbCaption').text("Corrija el valor de la tabla su valor no es valido:" +ISRB1x.val() +
					"\nSu valor debe encontrarse en el intervalo [ "+$('#ISRB3x3').val()+" , "+$('#ISRB1x3').val()+" ]");
					$('#tablaisrbCaption').css("display","block");
					$('#tablaisrbCaption').css("visibility","visible");
				} else {
					$('#tablaisrbCaption').css("display","none");
					$('#tablaisrbCaption').css("visibility","hidden");
				}
			break;
			case $('#ISRB3x3').attr('id'):
				if(!entreIntervalo($('#ISRB4x3').val(),ISRB1x.val(),$('#ISRB2x3').val()))	{
					$('#tablaisrbCaption').text("Corrija el valor de la tabla su valor no es valido:" +ISRB1x.val() +
					"\nSu valor debe encontrarse en el intervalo [ "+$('#ISRB4x3').val()+" , "+$('#ISRB2x3').val()+" ]");
					$('#tablaisrbCaption').css("display","block");
					$('#tablaisrbCaption').css("visibility","visible");
				} else {
					$('#tablaisrbCaption').css("display","none");
					$('#tablaisrbCaption').css("visibility","hidden");
				}
			break;
			case $('#ISRB4x3').attr('id'):
				if(!entreIntervalo($('#ISRB5x3').val(),ISRB1x.val(),$('#ISRB3x3').val()))	{
					$('#tablaisrbCaption').text("Corrija el valor de la tabla su valor no es valido:" +ISRB1x.val() +
					"\nSu valor debe encontrarse en el intervalo [ "+$('#ISRB5x3').val()+" , "+$('#ISRB3x3').val()+" ]");
					$('#tablaisrbCaption').css("display","block");
					$('#tablaisrbCaption').css("visibility","visible");
				} else {
					$('#tablaisrbCaption').css("display","none");
					$('#tablaisrbCaption').css("visibility","hidden");
				}
			break;
			case $('#ISRB5x3').attr('id'):
				if(!entreIntervalo($('#ISRB6x3').val(),ISRB1x.val(),$('#ISRB4x3').val()))	{
					$('#tablaisrbCaption').text("Corrija el valor de la tabla su valor no es valido:" +ISRB1x.val() +
					"\nSu valor debe encontrarse en el intervalo [ "+$('#ISRB6x3').val()+" , "+$('#ISRB4x3').val()+" ]");
					$('#tablaisrbCaption').css("display","block");
					$('#tablaisrbCaption').css("visibility","visible");
				} else {
					$('#tablaisrbCaption').css("display","none");
					$('#tablaisrbCaption').css("visibility","hidden");
				}
			break;
			case $('#ISRB6x3').attr('id'):
				if(!entreIntervalo($('#ISRB7x3').val(),ISRB1x.val(),$('#ISRB5x3').val()))	{
					$('#tablaisrbCaption').text("Corrija el valor de la tabla su valor no es valido:" +ISRB1x.val() +
					"\nSu valor debe encontrarse en el intervalo [ "+$('#ISRB7x3').val()+" , "+$('#ISRB5x3').val()+" ]");
					$('#tablaisrbCaption').css("display","block");
					$('#tablaisrbCaption').css("visibility","visible");
				} else {
					$('#tablaisrbCaption').css("display","none");
					$('#tablaisrbCaption').css("visibility","hidden");
				}
			break;
			case $('#ISRB7x3').attr('id'):
				if(!entreIntervalo($('#ISRB8x3').val(),ISRB1x.val(),$('#ISRB6x3').val()))	{
					$('#tablaisrbCaption').text("Corrija el valor de la tabla su valor no es valido:" +ISRB1x.val() +
					"\nSu valor debe encontrarse en el intervalo [ "+$('#ISRB8x3').val()+" , "+$('#ISRB6x3').val()+" ]");
					$('#tablaisrbCaption').css("display","block");
					$('#tablaisrbCaption').css("visibility","visible");
				} else {
					$('#tablaisrbCaption').css("display","none");
					$('#tablaisrbCaption').css("visibility","hidden");
				}
			break;
			case $('#ISRB8x3').attr('id'):
				if(!entreIntervalo($('#ISRB9x3').val(),ISRB1x.val(),$('#ISRB7x3').val()))	{
					$('#tablaisrbCaption').text("Corrija el valor de la tabla su valor no es valido:" +ISRB1x.val() +
					"\nSu valor debe encontrarse en el intervalo [ "+$('#ISRB9x3').val()+" , "+$('#ISRB7x3').val()+" ]");
					$('#tablaisrbCaption').css("display","block");
					$('#tablaisrbCaption').css("visibility","visible");
				} else {
					$('#tablaisrbCaption').css("display","none");
					$('#tablaisrbCaption').css("visibility","hidden");
				}
			break;
			case $('#ISRB9x3').attr('id'):
				if(!entreIntervalo($('#ISRB10x3').val(),ISRB1x.val(),$('#ISRB8x3').val()))	{
					$('#tablaisrbCaption').text("Corrija el valor de la tabla su valor no es valido:" +ISRB1x.val() +
					"\nSu valor debe encontrarse en el intervalo [ "+$('#ISRB10x3').val()+" , "+$('#ISRB8x3').val()+" ]");
					$('#tablaisrbCaption').css("display","block");
					$('#tablaisrbCaption').css("visibility","visible");
				} else {
					$('#tablaisrbCaption').css("display","none");
					$('#tablaisrbCaption').css("visibility","hidden");
				}
			break;
			case $('#ISRB10x3').attr('id'):
				if(!entreIntervalo($('#ISRB11x3').val(),ISRB1x.val(),$('#ISRB9x3').val()))	{
					$('#tablaisrbCaption').text("Corrija el valor de la tabla su valor no es valido:" +ISRB1x.val() +
					"\nSu valor debe encontrarse en el intervalo [ "+$('#ISRB11x3').val()+" , "+$('#ISRB9x3').val()+" ]");
					$('#tablaisrbCaption').css("display","block");
					$('#tablaisrbCaption').css("visibility","visible");
				} else {
					$('#tablaisrbCaption').css("display","none");
					$('#tablaisrbCaption').css("visibility","hidden");
				}
			break;
			case $('#ISRB11x3').attr('id'):
				if(!entreIntervalo("0",ISRB1x.val(),$('#ISRB10x3').val()))	{
					$('#tablaisrbCaption').text("Corrija el valor de la tabla su valor no es valido:" +ISRB1x.val() +
					"\nSu valor debe ser menor a "+$('#ISRB10x3').val());
					$('#tablaisrbCaption').css("display","block");
					$('#tablaisrbCaption').css("visibility","visible");
				} else {
					$('#tablaisrbCaption').css("display","none");
					$('#tablaisrbCaption').css("visibility","hidden");
				}
			break;
			default:				
		}
		
	});
	
	$('.isr_input').blur(function () {		
		var ISR1x = $(this);
//		alert(ISR1x.attr('id'));
		switch (ISR1x.attr('id')) {
			case $('#ISR1x4').attr('id'):
				var B1=Number($('#ISR1x1').val().replace(/,/g,''));
				var C1=Number($('#ISR1x2').val().replace(/,/g,''));
				var D1=Number($('#ISR1x3').val().replace(/,/g,''));
				var E1=Number($('#ISR1x4').val().replace(/,/g,''));
				var D2=(C1-B1)*E1/100+D1;
				$('#ISR2x3').val(D2.toFixed(2));
				$('#ISR2x4').blur();
				$('#ISR3x4').blur();
				$('#ISR4x4').blur();
				$('#ISR5x4').blur();
				$('#ISR6x4').blur();
				$('#ISR7x4').blur();
				
				if(!entreIntervalo("0",ISR1x.val(),$('#ISR2x4').val()))	{
					$('#tablaisrCaption').text("Corrija el valor de la tabla isr su valor no es valido:" +ISR1x.val() +
					"\nSu valor debe encontrarse en el intervalo [ 0 , "+$('#ISR2x4').val()+" ]");
					$('#tablaisrCaption').css("display","block");
					$('#tablaisrCaption').css("visibility","visible");
				} else {
					$('#tablaisrCaption').css("display","none");
					$('#tablaisrCaption').css("visibility","hidden");
				}
			break;
			case $('#ISR2x4').attr('id'):
				var B1=Number($('#ISR2x1').val().replace(/,/g,''));
				var C1=Number($('#ISR2x2').val().replace(/,/g,''));
				var D1=Number($('#ISR2x3').val().replace(/,/g,''));
				var E1=Number($('#ISR2x4').val().replace(/,/g,''));
				var D2=(C1-B1)*E1/100+D1;
				$('#ISR3x3').val(D2.toFixed(2));
				$('#ISR3x4').blur();
				$('#ISR4x4').blur();
				$('#ISR5x4').blur();
				$('#ISR6x4').blur();
				$('#ISR7x4').blur();

				if(!entreIntervalo($('#ISR1x4').val(),ISR1x.val(),$('#ISR3x4').val()))	{
					$('#tablaisrCaption').text("Corrija el valor de la tabla isr su valor no es valido:" +ISR1x.val() +
					"\nSu valor debe encontrarse en el intervalo [ " + $('#ISR1x4').val() + " , " + $('#ISR3x4').val() + " ]");
					$('#tablaisrCaption').css("visibility","visible");
				} else {
					$('#tablaisrCaption').css("visibility","hidden");
				}
			break;
			case $('#ISR3x4').attr('id'):
				var B1=Number($('#ISR3x1').val().replace(/,/g,''));
				var C1=Number($('#ISR3x2').val().replace(/,/g,''));
				var D1=Number($('#ISR3x3').val().replace(/,/g,''));
				var E1=Number($('#ISR3x4').val().replace(/,/g,''));
				var D2=(C1-B1)*E1/100+D1;
				$('#ISR4x3').val(D2.toFixed(2));
				$('#ISR4x4').blur();
				$('#ISR5x4').blur();
				$('#ISR6x4').blur();
				$('#ISR7x4').blur();

				if(!entreIntervalo($('#ISR2x4').val(),ISR1x.val(),$('#ISR4x4').val()))	{
					$('#tablaisrCaption').text("Corrija el valor de la tabla isr su valor no es valido:" +ISR1x.val() +
					"\nSu valor debe encontrarse en el intervalo [ " + $('#ISR2x4').val() + " , " + $('#ISR4x4').val() + " ]");
					$('#tablaisrCaption').css("visibility","visible");
				} else {
					$('#tablaisrCaption').css("visibility","hidden");
				}
			break;
			case $('#ISR4x4').attr('id'):
				var B1=Number($('#ISR4x1').val().replace(/,/g,''));
				var C1=Number($('#ISR4x2').val().replace(/,/g,''));
				var D1=Number($('#ISR4x3').val().replace(/,/g,''));
				var E1=Number($('#ISR4x4').val().replace(/,/g,''));
				var D2=(C1-B1)*E1/100+D1;
				$('#ISR5x3').val(D2.toFixed(2));
				$('#ISR5x4').blur();
				$('#ISR6x4').blur();
				$('#ISR7x4').blur();

				if(!entreIntervalo($('#ISR3x4').val(),ISR1x.val(),$('#ISR5x4').val()))	{
					$('#tablaisrCaption').text("Corrija el valor de la tabla isr su valor no es valido:" +ISR1x.val() +
					"\nSu valor debe encontrarse en el intervalo [ " + $('#ISR3x4').val() + " , " + $('#ISR5x4').val() + " ]");
					$('#tablaisrCaption').css("visibility","visible");
				} else {
					$('#tablaisrCaption').css("visibility","hidden");
				}
			break;
			case $('#ISR5x4').attr('id'):
				var B1=Number($('#ISR5x1').val().replace(/,/g,''));
				var C1=Number($('#ISR5x2').val().replace(/,/g,''));
				var D1=Number($('#ISR5x3').val().replace(/,/g,''));
				var E1=Number($('#ISR5x4').val().replace(/,/g,''));
				var D2=(C1-B1)*E1/100+D1;
				$('#ISR6x3').val(D2.toFixed(2));
				$('#ISR6x4').blur();
				$('#ISR7x4').blur();

				if(!entreIntervalo($('#ISR4x4').val(),ISR1x.val(),$('#ISR6x4').val()))	{
					$('#tablaisrCaption').text("Corrija el valor de la tabla isr su valor no es valido:" +ISR1x.val() +
					"\nSu valor debe encontrarse en el intervalo [ " + $('#ISR4x4').val() +" , "+ $('#ISR6x4').val() +" ]");
					$('#tablaisrCaption').css("visibility","visible");
				} else {
					$('#tablaisrCaption').css("visibility","hidden");
				}
			break;
			case $('#ISR6x4').attr('id'):
				var B1=Number($('#ISR6x1').val().replace(/,/g,''));
				var C1=Number($('#ISR6x2').val().replace(/,/g,''));
				var D1=Number($('#ISR6x3').val().replace(/,/g,''));
				var E1=Number($('#ISR6x4').val().replace(/,/g,''));
				var D2=(C1-B1)*E1/100+D1;
				$('#ISR7x3').val(D2.toFixed(2));
				$('#ISR7x4').blur();

				if(!entreIntervalo($('#ISR5x4').val(),ISR1x.val(),$('#ISR7x4').val()))	{
					$('#tablaisrCaption').text("Corrija el valor de la tabla isr su valor no es valido:" +ISR1x.val() +
					"\nSu valor debe encontrarse en el intervalo [ " + $('#ISR5x4').val() +" , "+$('#ISR7x4').val()+" ] ");
					$('#tablaisrCaption').css("visibility","visible");
				} else {
					$('#tablaisrCaption').css("visibility","hidden");
				}
			break;
			case $('#ISR7x4').attr('id'):
				var B1=Number($('#ISR7x1').val().replace(/,/g,''));
				var C1=Number($('#ISR7x2').val().replace(/,/g,''));
				var D1=Number($('#ISR7x3').val().replace(/,/g,''));
				var E1=Number($('#ISR7x4').val().replace(/,/g,''));
				var D2=(C1-B1)*E1/100+D1;
				$('#ISR8x3').val(D2.toFixed(2));

				if(!entreIntervalo($('#ISR6x4').val(),ISR1x.val(),$('#ISR8x4').val()))	{
					$('#tablaisrCaption').text("Corrija el valor de la tabla isr su valor no es valido:" +ISR1x.val() +
					"\nSu valor debe encontrarse en el intervalo [ " + $('#ISR6x4').val()+" , "+$('#ISR8x4').val()+" ] ");
					$('#tablaisrCaption').css("visibility","visible");
				} else {
					$('#tablaisrCaption').css("visibility","hidden");
				}
			break;
			case $('#ISR8x4').attr('id'):
				var B1=Number($('#ISR8x1').val().replace(/,/g,''));
				var C1=Number($('#ISR8x2').val().replace(/,/g,''));
				var D1=Number($('#ISR8x3').val().replace(/,/g,''));
				var E1=Number($('#ISR8x4').val().replace(/,/g,''));
				var D2=(C1-B1)*E1/100+D1;
				$('#ISR9x3').val(D2.toFixed(2));

				if(!entreIntervalo($('#ISR1x4').val(),ISR1x.val(),$('#ISR9x4').val()))	{
					$('#tablaisrCaption').text("Corrija el valor de la tabla isr su valor no es valido:" +ISR1x.val() +
					"\nSu valor debe ser mayor a [" +$('#ISR7x4').val());
					$('#tablaisrCaption').css("visibility","visible");
				} else {
					$('#tablaisrCaption').css("visibility","hidden");
				}
			break;
			case $('#ISR9x4').attr('id'):

				if(!entreIntervalo($('#ISR1x4').val(),ISR1x.val(),"10000"))	{
					$('#tablaisrCaption').text("Corrija el valor de la tabla isr su valor no es valido:" +ISR1x.val() +
					"\nSu valor debe ser mayor a [" +$('#ISR8x4').val());
					$('#tablaisrCaption').css("visibility","visible");
				} else {
					$('#tablaisrCaption').css("visibility","hidden");
				}
			break;
			default:
				
		}

				
	});
	
	$('#ecuRGD').change(function () {	
//		alert($('#ecuRGD').val());
		$('#deudaMPD').text(formato(Deuda[$('#ecuRGD').val()],true));
//		$('#deudaMPD').html( formato($('#deudaMPD').html(), true));
		$('#gastoMPD').text(formato(Gastos[$('#ecuRGD').val()],true));
		$('#recaudacionMPD').text(formato(Ingresos[$('#ecuRGD').val()],true));
		$('#gastoLabYear').text(fechas[$('#ecuRGD').val()]);
		$('#recaudacionLabYear').text(fechas[$('#ecuRGD').val()]);
		$('#gastoLabYear').text(fechas[$('#ecuRGD').val()]);
		
	});
	
	$('#selectAmp1').change(function () {
		var porcentaje = 0;
		var year = $('#selectAmp1').val();
		var ii =0;
		
		var lif = new Array(
				sumatoria(recaudacionGasto[year],0,45), sumatoria(recaudacionGasto[year],0,19),recaudacionGasto[year][0], 
				recaudacionGasto[year][0], recaudacionGasto[year][1],sumatoria(recaudacionGasto[year],2,12), recaudacionGasto[year][2], 
				sumatoria(recaudacionGasto[year],3,12),recaudacionGasto[year][3], recaudacionGasto[year][4], recaudacionGasto[year][5],
				recaudacionGasto[year][6], recaudacionGasto[year][7], recaudacionGasto[year][8], recaudacionGasto[year][9], recaudacionGasto[year][10],
				recaudacionGasto[year][11], recaudacionGasto[year][12], recaudacionGasto[year][13], recaudacionGasto[year][14], recaudacionGasto[year][14],	
				recaudacionGasto[year][15],recaudacionGasto[year][16], recaudacionGasto[year][17],	recaudacionGasto[year][18], recaudacionGasto[year][19],
				recaudacionGasto[year][20], sumatoria(recaudacionGasto[year],21,25), recaudacionGasto[year][21], recaudacionGasto[year][22], 
				recaudacionGasto[year][23], recaudacionGasto[year][24], recaudacionGasto[year][25], recaudacionGasto[year][26], recaudacionGasto[year][26], 
				sumatoria(recaudacionGasto[year],27,32), recaudacionGasto[year][27], recaudacionGasto[year][28], recaudacionGasto[year][29], 
				recaudacionGasto[year][30], recaudacionGasto[year][31], recaudacionGasto[year][32], sumatoria(recaudacionGasto[year],33,35), 
				recaudacionGasto[year][33], recaudacionGasto[year][34], recaudacionGasto[year][35], sumatoria(recaudacionGasto[year],36,37), 
				recaudacionGasto[year][36], recaudacionGasto[year][37], sumatoria(recaudacionGasto[year],38,43), sumatoria(recaudacionGasto[year],38,39),
				recaudacionGasto[year][38], recaudacionGasto[year][39], sumatoria(recaudacionGasto[year],40,42), recaudacionGasto[year][40], 
				recaudacionGasto[year][41], recaudacionGasto[year][42],recaudacionGasto[year][43], recaudacionGasto[year][44], recaudacionGasto[year][45],
				sumatoria(recaudacionGasto[year],0,45)			
			);
		var valores = lif.length;
		for(var i = 0; i< valores;i++) {
			ii=i+1;
//			$('.recaudacionGasto'+ii+'-1').text('$ ' +formato(recaudacionGasto[year][i],true));	
//			porcentaje  = recaudacionGasto[year][i] /Ingresos[year];
//			$('.recaudacionGasto'+ii).text( porcentaje.toFixed(2) + '%');	
			$('.recaudacionGasto'+ii+'-1').text('$ ' +formato(lif[i],true));	
			porcentaje  = lif[i] /Ingresos[year]*100;
			$('.recaudacionGasto'+ii).text( porcentaje.toFixed(2) + '%');	
			$('#valor'+ii).css("width", porcentaje.toFixed(2) );	
		}
	});



	$('.tasaIEPS').change(function () {	
//		=D27-D24-D25-D20-D18-D17-D16-D15
		$('#tasaIEPSR1').text(Number($('#tasaIEPS6').val())-Number($('#tasaIEPSR2').text()) - Number($('#tasaIEPS5').val()) - Number($('#tasaIEPS4').val()) -Number($('#tasaIEPS3').val()) -Number($('#tasaIEPS2').val()) -Number($('#tasaIEPS1').val()) -Number($('#tasaIEPS0').val()) );
		
	});


	$('.tasaIEPSIVA').change(function () {	
//		=(tasaIEPS5-tasaIEPS6)*0.16
		$('#tasaIEPSR2').text(Number($('#tasaIEPS6').val())*0.16-Number($('#tasaIEPS5').val()) * 0.16);
	});
/*
	$('.lifilif').click( function () {
		var lif ="ilif";
		if ($(this).attr("id").match(/.*ILif14.* /) ) lif ="lif";
		$.ajax({
			url: "inputLif.php?lif="+lif, // cambiar por php
			async:false,
			success: function (xml) {
				switch ($(this).id) {
					case "ivaLif14" || "ivaILif14" :
						var IVAIn=eval($(xml).find("IVAIn").text());
						var input = new Array("ivaA1", "ivaA2", "ivaA3", "ivaCanasta", "ivaLeche", "ivaMedicinas", "ivaJarabe", "ivaTransUrbano", "ivaTransForaneo", "ivaEduPub", "ivaEduPrib", "ivaCRCasa", "ivaAlimentos", "ivaOtrosAlimentos",  "ivaB1", "ivaB2", "ivaB3", "ivaB4", "ivaB5", "ivaB6", "ivaB7", "ivaB8", "ivaB9", "ivaB10", "ivaB11");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],IVAIn[i],$("form"));
						}

						break;
					default:
						break;
				} // fin switch		

			} // fin success
			
		}); // fin ajax


	});
*/

	$('#ivaLif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=lif",
			async:false,
			success: function (xml) {
						var IVAIn=eval($(xml).find("IVAIn").text());
//						var input = new Array("ivaA1", "ivaA2", "ivaA3", "ivaCanasta", "ivaLeche", "ivaMedicinas", "ivaJarabe", "ivaTransUrbano", "ivaTransForaneo", "ivaEduPub", "ivaEduPrib", "ivaCRCasa", "ivaAlimentos", "ivaOtrosAlimentos",  "ivaB1", "ivaB2", "ivaB3", "ivaB4", "ivaB5", "ivaB6", "ivaB7", "ivaB8", "ivaB9", "ivaB10", "ivaB11", "ivaB12");
						var input = new Array("ivaA1", "ivaA2", "ivaA3", "ivaCanasta", "ivaLeche", "ivaMedicinas", "ivaJarabe", "ivaTransUrbano", "ivaTransForaneo", "ivaEduPub", "ivaEduPrib", "ivaCRCasa", "ivaAlimentos", "ivaOtrosAlimentos", "ivaAlimentosMascotas",  "ivaB1", "ivaB2", "ivaB3", "ivaB4", "ivaB5", "ivaB6", "ivaB7", "ivaB8", "ivaB9", "ivaB10", "ivaB11", "ivaB12");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],IVAIn[i],$("form"));
						}
			} // fin success
		}); // fin ajax
	});

	$('#ivaILif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=ilif",
			async:false,
			success: function (xml) {
						var IVAIn=eval($(xml).find("IVAIn").text());
						var input = new Array("ivaA1", "ivaA2", "ivaA3", "ivaCanasta", "ivaLeche", "ivaMedicinas", "ivaJarabe", "ivaTransUrbano", "ivaTransForaneo", "ivaEduPub", "ivaEduPrib", "ivaCRCasa", "ivaAlimentos", "ivaOtrosAlimentos", "ivaAlimentosMascotas",  "ivaB1", "ivaB2", "ivaB3", "ivaB4", "ivaB5", "ivaB6", "ivaB7", "ivaB8", "ivaB9", "ivaB10", "ivaB11", "ivaB12");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],IVAIn[i],$("form"));
						}
			} // fin success
		}); // fin ajax
	});

	$('#isrFisicasLif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=lif",
			async:false,
			success: function (xml) {
				ISR=eval($(xml).find("ISR").text());
				ISRE=eval($(xml).find("ISRE").text());
				ISRPB=eval($(xml).find("ISRB").text());
				ISROP=eval($(xml).find("ISROP").text());
				var input = new Array("ISR1x4","ISR2x4","ISR3x4","ISR4x4","ISR5x4","ISR6x4","ISR7x4","ISR8x4","ISR9x4");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],ISR[i],$("form"));
				}
				var input = new Array("ISRB1x3", "ISRB2x3", "ISRB3x3", "ISRB4x3", "ISRB5x3", "ISRB6x3", "ISRB7x3", "ISRB8x3", "ISRB9x3", "ISRB10x3", "ISRB11x3","ISRB12x3");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],ISRPB[i],$("form"));
				}
				var input = new Array("ISRE1x2","ISRE2x2","ISRE3x2","ISRE4x2","ISRE5x2","ISRE6x2","ISRE7x2","ISRE8x2","deducciones");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],ISRE[i],$("form"));
				}
				var input = new Array("ISROP1x1","ISROP1x2");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],ISROP[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#isrFisicasILif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=ilif",
			async:false,
			success: function (xml) {
				ISR=eval($(xml).find("ISR").text());
				ISRE=eval($(xml).find("ISRE").text());
				ISRPB=eval($(xml).find("ISRB").text());
				ISROP=eval($(xml).find("ISROP").text());
				var input = new Array("ISR1x4","ISR2x4","ISR3x4","ISR4x4","ISR5x4","ISR6x4","ISR7x4","ISR8x4","ISR9x4");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],ISR[i],$("form"));
				}
				var input = new Array("ISRB1x3", "ISRB2x3", "ISRB3x3", "ISRB4x3", "ISRB5x3", "ISRB6x3", "ISRB7x3", "ISRB8x3", "ISRB9x3", "ISRB10x3", "ISRB11x3","ISRB12x3");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],ISRPB[i],$("form"));
				}
				var input = new Array("ISRE1x2","ISRE2x2","ISRE3x2","ISRE4x2","ISRE5x2","ISRE6x2","ISRE7x2","ISRE8x2","deducciones");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],ISRE[i],$("form"));
				}
				var input = new Array("ISROP1x1","ISROP1x2");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],ISROP[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#isrMoralesLif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=lif",
			async:false,
			success: function (xml) {
				ISRPMIn=eval($(xml).find("ISRPMIn").text());
				var input = new Array("isrMoralesA1","isrMoralesA2","isrMoralesA3","isrMoralesA4",
										"isrMoralesC1","isrMoralesC2","isrMoralesC3","isrMoralesC4","si");
				for(i = 0; i < ISRPMIn.length;i++) {
					asigna(input[i],ISRPMIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#isrMoralesILif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=ilif",
			async:false,
			success: function (xml) {
				ISRPMIn=eval($(xml).find("ISRPMIn").text());
				var input = new Array("isrMoralesA1","isrMoralesA2","isrMoralesA3","isrMoralesA4",
										"isrMoralesC1","isrMoralesC2","isrMoralesC3","isrMoralesC4","si");
				for(i = 0; i < ISRPMIn.length;i++) {
					asigna(input[i],ISRPMIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#seguridadSocialLif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=lif",
			async:false,
			success: function (xml) {
				seguridadSocialIn=eval($(xml).find("seguridadSocialIn").text());
				var input = new Array("seguridadSocialIn1","seguridadSocialIn2","seguridadSocialIn3","seguridadSocialIn4","seguridadSocialIn5","seguridadSocialIn6","seguridadSocialIn7","seguridadSocialIn8","seguridadSocialIn9","seguridadSocialIn10","seguridadSocialIn11","seguridadSocialIn12","seguridadSocialIn13","seguridadSocialIn14","seguridadSocialIn15","seguridadSocialIn16","seguridadSocialIn17","seguridadSocialIn18","seguridadSocialIn19","seguridadSocialIn20","seguridadSocialIn21","seguridadSocialIn22","seguridadSocialIn23","seguridadSocialIn24","seguridadSocialIn25","seguridadSocialIn26","seguridadSocialIn27","seguridadSocialIn28","seguridadSocialIn29","seguridadSocialIn30","seguridadSocialIn31","seguridadSocialIn32","seguridadSocialIn33","seguridadSocialIn34");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],seguridadSocialIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#seguridadSocialILif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=ilif",
			async:false,
			success: function (xml) {
				seguridadSocialIn=eval($(xml).find("seguridadSocialIn").text());
				var input = new Array("seguridadSocialIn1","seguridadSocialIn2","seguridadSocialIn3","seguridadSocialIn4","seguridadSocialIn5","seguridadSocialIn6","seguridadSocialIn7","seguridadSocialIn8","seguridadSocialIn9","seguridadSocialIn10","seguridadSocialIn11","seguridadSocialIn12","seguridadSocialIn13","seguridadSocialIn14","seguridadSocialIn15","seguridadSocialIn16","seguridadSocialIn17","seguridadSocialIn18","seguridadSocialIn19","seguridadSocialIn20","seguridadSocialIn21","seguridadSocialIn22","seguridadSocialIn23","seguridadSocialIn24","seguridadSocialIn25","seguridadSocialIn26","seguridadSocialIn27","seguridadSocialIn28","seguridadSocialIn29","seguridadSocialIn30","seguridadSocialIn31","seguridadSocialIn32","seguridadSocialIn33","seguridadSocialIn34");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],seguridadSocialIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#iepsLif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=lif",
			async:false,
			success: function (xml) {
				IEPSIn=eval($(xml).find("IEPSIn").text());
				var input = new Array("IEPSA1","IEPSA2","IEPSA3","IEPSA4","IEPSA5","IEPSA6","IEPSA7","IEPSA8","IEPSA9","IEPSA10","IEPSA11","IEPSA12","IEPSA13");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],IEPSIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#iepsILif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=ilif",
			async:false,
			success: function (xml) {
				IEPSIn=eval($(xml).find("IEPSIn").text());
				var input = new Array("IEPSA1","IEPSA2","IEPSA3","IEPSA4","IEPSA5","IEPSA6","IEPSA7","IEPSA8","IEPSA9","IEPSA10","IEPSA11","IEPSA12","IEPSA13");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],IEPSIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#ietuLif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=lif",
			async:false,
			success: function (xml) {
				IETUIn=eval($(xml).find("IETUIn").text());
				var input = new Array("ietuA1","ietuA2","ietuA3","ietuA4","ietuA5","ietuB1","ietuB2","ietuB3","ietuB4","si");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],IETUIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#ietuILif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=ilif",
			async:false,
			success: function (xml) {
				IETUIn=eval($(xml).find("IETUIn").text());
				var input = new Array("ietuA1","ietuA2","ietuA3","ietuA4","ietuA5","ietuB1","ietuB2","ietuB3","ietuB4","si");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],IETUIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#tarifasElectricasLif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=lif",
			async:false,
			success: function (xml) {
				ElectricasIn=eval($(xml).find("ElectricasIn").text());
				var input = new Array("ElectricasIn1_", "ElectricasIn2", "ElectricasIn3", "ElectricasIn4_", "ElectricasIn5", "ElectricasIn6", "ElectricasIn7");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],ElectricasIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#tarifasElectricasILif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=ilif",
			async:false,
			success: function (xml) {
				ElectricasIn=eval($(xml).find("ElectricasIn").text());
				var input = new Array("ElectricasIn1_", "ElectricasIn2", "ElectricasIn3", "ElectricasIn4_", "ElectricasIn5", "ElectricasIn6", "ElectricasIn7");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],ElectricasIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#educacionLif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=lif",
			async:false,
			success: function (xml) {
				EdudacionIn=eval($(xml).find("EdudacionIn").text());
				var input = new Array("edicacionA1", "edicacionA2", "edicacionA3", "edicacionA4");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],EdudacionIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#educacionILif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=ilif",
			async:false,
			success: function (xml) {
				EdudacionIn=eval($(xml).find("EdudacionIn").text());
				var input = new Array("edicacionA1", "edicacionA2", "edicacionA3", "edicacionA4");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],EdudacionIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#saludLif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=lif",
			async:false,
			success: function (xml) {
				SaludIn=eval($(xml).find("SaludIn").text());
				var input = new Array("saludA1", "saludA2", "saludA3");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],SaludIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#saludILif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=ilif",
			async:false,
			success: function (xml) {
				SaludIn=eval($(xml).find("SaludIn").text());
				var input = new Array("saludA1", "saludA2", "saludA3");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],SaludIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#pensionesCLif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=lif",
			async:false,
			success: function (xml) {
				PensionCIn=eval($(xml).find("PensionCIn").text());
				var input = new Array("PensionCIn1","PensionCIn2","PensionCIn3","PensionCIn4","PensionCIn5","PensionCIn6","PensionCIn7");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],PensionCIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#pensionesCILif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=ilif",
			async:false,
			success: function (xml) {
				PensionCIn=eval($(xml).find("PensionCIn").text());
				var input = new Array("PensionCIn1","PensionCIn2","PensionCIn3","PensionCIn4","PensionCIn5","PensionCIn6","PensionCIn7");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],PensionCIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#PensionNCLif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=lif",
			async:false,
			success: function (xml) {
				PensionNCIn=eval($(xml).find("PensionNCIn").text());
				var input = new Array("PensionNCIn1", "PensionNCIn2", "PensionNCIn3","PensionNCIn4");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],PensionNCIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#PensionNCILif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=ilif",
			async:false,
			success: function (xml) {
				PensionNCIn=eval($(xml).find("PensionNCIn").text());
				var input = new Array("PensionNCIn1", "PensionNCIn2", "PensionNCIn3","PensionNCIn4");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],PensionNCIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#otrosParametrosLif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=lif",
			async:false,
			success: function (xml) {
				otrosParametrosIn=eval($(xml).find("otrosParametrosIn").text());
				var input = new Array("otrosParametrosIn1", "otrosParametrosIn2", "otrosParametrosIn3");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],otrosParametrosIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#otrosParametrosILif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=ilif",
			async:false,
			success: function (xml) {
				otrosParametrosIn=eval($(xml).find("otrosParametrosIn").text());
				var input = new Array("otrosParametrosIn1", "otrosParametrosIn2", "otrosParametrosIn3");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],otrosParametrosIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

	$('#ecenarioPetroDerLif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=lif",
			async:false,
			success: function (xml) {
				PetroDerechosBIn=eval($(xml).find("PetroDerechosBIn").text());
				var input = new Array("PetroDerechosB", "escenarioInercial", "precioGas");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],PetroDerechosBIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});
	
	$('#ecenarioPetroDerILif14').click( function () {
		$.ajax({
			url: "inputLif.php?lif=ilif",
			async:false,
			success: function (xml) {
				PetroDerechosBIn=eval($(xml).find("PetroDerechosBIn").text());
				var input = new Array("PetroDerechosB", "escenarioInercial", "precioGas");
				for(i = 0; i < input.length;i++) {
					asigna(input[i],PetroDerechosBIn[i],$("form"));
				}
			} // fin success
		}); // fin ajax
	});

/************************************        seccion de resets    *************************************************************/
	
	$("*").bind("reset", function() {
		var bandera =true;
		$.ajax({
			url: "inputsaved.php", // cambiar por php
			async:false,
			success: function (xml) {
				switch ($("input:reset").attr("id")) {
					case "isrMoralesRst" :
						ISRPMIn=eval($(xml).find("ISRPMIn").text());
						var input = new Array("isrMoralesA1","isrMoralesA2","isrMoralesA3","isrMoralesA4",
												"isrMoralesC1","isrMoralesC2","isrMoralesC3","isrMoralesC4","si");
						for(i = 0; i < ISRPMIn.length;i++) {
							asigna(input[i],ISRPMIn[i],$("form"));
						}
						bandera = false;
						break;
					case "isrFisicasRst" :
						ISR=eval($(xml).find("ISR").text());
						ISRE=eval($(xml).find("ISRE").text());
						ISRPB=eval($(xml).find("ISRB").text());
						ISROP=eval($(xml).find("ISROP").text());
						var input = new Array("ISR1x4","ISR2x4","ISR3x4","ISR4x4","ISR5x4","ISR6x4","ISR7x4","ISR8x4","ISR9x4");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],ISR[i],$("form"));
						}
						var input = new Array("ISRB1x3", "ISRB2x3", "ISRB3x3", "ISRB4x3", "ISRB5x3", "ISRB6x3", "ISRB7x3", "ISRB8x3", "ISRB9x3", "ISRB10x3", "ISRB11x3","ISRB12x3");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],ISRPB[i],$("form"));
						}
						var input = new Array("ISRE1x2","ISRE2x2","ISRE3x2","ISRE4x2","ISRE5x2","ISRE6x2","ISRE7x2","ISRE8x2","deducciones");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],ISRE[i],$("form"));
						}
						var input = new Array("ISROP1x1","ISROP1x2");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],ISROP[i],$("form"));
						}
						
						bandera = false;
						break;
					case "ivaRst" :
						IVAIn=eval($(xml).find("IVAIn").text());
						var input = new Array("ivaA1", "ivaA2", "ivaA3", "ivaCanasta", "ivaLeche", "ivaMedicinas", "ivaJarabe", "ivaTransUrbano", "ivaTransForaneo", "ivaEduPub", "ivaEduPrib", "ivaCRCasa", "ivaAlimentos", "ivaOtrosAlimentos", "ivaAlimentosMascotas",  "ivaB1", "ivaB2", "ivaB3", "ivaB4", "ivaB5", "ivaB6", "ivaB7", "ivaB8", "ivaB9", "ivaB10", "ivaB11", "ivaB12");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],IVAIn[i],$("form"));
						}
						bandera = false;
						break;
					case "seguridadSocialRst" :
						seguridadSocialIn=eval($(xml).find("seguridadSocialIn").text());
						var input = new Array("seguridadSocialIn1","seguridadSocialIn2","seguridadSocialIn3","seguridadSocialIn4","seguridadSocialIn5","seguridadSocialIn6","seguridadSocialIn7","seguridadSocialIn8","seguridadSocialIn9","seguridadSocialIn10","seguridadSocialIn11","seguridadSocialIn12","seguridadSocialIn13","seguridadSocialIn14","seguridadSocialIn15","seguridadSocialIn16","seguridadSocialIn17","seguridadSocialIn18","seguridadSocialIn19","seguridadSocialIn20","seguridadSocialIn21","seguridadSocialIn22","seguridadSocialIn23","seguridadSocialIn24","seguridadSocialIn25","seguridadSocialIn26","seguridadSocialIn27","seguridadSocialIn28","seguridadSocialIn29","seguridadSocialIn30","seguridadSocialIn31","seguridadSocialIn32","seguridadSocialIn33","seguridadSocialIn34");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],seguridadSocialIn[i],$("form"));
						}
						bandera = false;
						break;
					case "iepsRst" :
						IEPSIn=eval($(xml).find("IEPSIn").text());
						var input = new Array("IEPSA1","IEPSA2","IEPSA3","IEPSA4","IEPSA5","IEPSA6","IEPSA7","IEPSA8","IEPSA9","IEPSA10","IEPSA11","IEPSA12","IEPSA13");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],IEPSIn[i],$("form"));
						}
						bandera = false;
						break;
					case "ietuRst" :
						IETUIn=eval($(xml).find("IETUIn").text());
						var input = new Array("ietuA1","ietuA2","ietuA3","ietuA4","ietuA5","ietuB1","ietuB2","ietuB3","ietuB4","si");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],IETUIn[i],$("form"));
						}
						bandera = false;
						break;
					case "tarifasElectricasRts" :
						ElectricasIn=eval($(xml).find("ElectricasIn").text());
						var input = new Array("ElectricasIn1_", "ElectricasIn2", "ElectricasIn3", "ElectricasIn4_", "ElectricasIn5", "ElectricasIn6", "ElectricasIn7");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],ElectricasIn[i],$("form"));
						}
						bandera = false;
						break;
					case "educacionRst" :
						EdudacionIn=eval($(xml).find("EdudacionIn").text());
						var input = new Array("edicacionA1", "edicacionA2", "edicacionA3", "edicacionA4");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],EdudacionIn[i],$("form"));
						}
						bandera = false;
						break;
					case "saludRst" :
						SaludIn=eval($(xml).find("SaludIn").text());
						var input = new Array("saludA1", "saludA2", "saludA3");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],SaludIn[i],$("form"));
						}
						bandera = false;
						break;
					case "pensionesCRst" :
						PensionCIn=eval($(xml).find("PensionCIn").text());
						var input = new Array("PensionCIn1","PensionCIn2","PensionCIn3","PensionCIn4","PensionCIn5","PensionCIn6","PensionCIn7");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],PensionCIn[i],$("form"));
						}
						bandera = false;
						break;
					case "PensionNCRst" :
						PensionNCIn=eval($(xml).find("PensionNCIn").text());
						var input = new Array("PensionNCIn1", "PensionNCIn2", "PensionNCIn3","PensionNCIn4");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],PensionNCIn[i],$("form"));
						}
						bandera = false;
						break;
					case "otrosParametrosRst" :
						otrosParametrosIn=eval($(xml).find("otrosParametrosIn").text());
						var input = new Array("otrosParametrosIn1", "otrosParametrosIn2", "otrosParametrosIn3");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],otrosParametrosIn[i],$("form"));
						}
						bandera = false;
						break;
					case "ecenarioPetroDerRst" :
						PetroDerechosBIn=eval($(xml).find("PetroDerechosBIn").text());
						var input = new Array("PetroDerechosB", "escenarioInercial", "precioGas");
						for(i = 0; i < input.length;i++) {
							asigna(input[i],PetroDerechosBIn[i],$("form"));
						}
						bandera = false;
						break;
						
					default:
						break;
				} // fin switch		
		    } // fin success
			
		}); // fin ajax

		return bandera;
	});
		
});	



function asigna(idCampo, valor, formulario) {

	if($(formulario).find("#"+idCampo).is('[type=text]'))
		$(formulario).find("#"+idCampo).val(valor);
	else if($(formulario).find("#"+idCampo).is("[type=checkbox]"))
		(valor==1?$(formulario).find("#"+idCampo).prop('checked',true):$(formulario).find("#"+idCampo).removeAttr("checked"));
	else if($(formulario).find("#"+idCampo+valor).is("[type=radio]")) {

			$("#" +idCampo+valor).prop('checked', true);	
	}
}





$(function(){
	$('.numeric').numeric({ cents: true});
	$('.currency').numeric({prefix:'$ ', cents: true});
});

//PLUGIN
(function($) {
	$.fn.numeric = function(options) {
		var _options = $.extend({
			prefix: '',
			cents: false,
		}, options);
		
		var format = function(cnt, cents) {
			cnt = cnt.toString().replace(/\$|\u20AC|\,/g,'');
			if (isNaN(cnt))
				return 0;	
			var sgn = (cnt == (cnt = Math.abs(cnt)));
			cnt = Math.floor(cnt * 100 + 0.5);
			var cvs = cnt % 100;
			cnt = Math.floor(cnt / 100).toString();
			if (cvs < 10)
			cvs = '0' + cvs;
			for (var i = 0; i < Math.floor((cnt.length - (1 + i)) / 3); i++)
				cnt = cnt.substring(0, cnt.length - (4 * i + 3)) + ',' + cnt.substring(cnt.length - (4 * i + 3));
			
			return (((sgn) ? '' : '-') + cnt) + ( cents ?  '.' + cvs : '');
		};
		
		var keypress = function(e) {
			var i = 0;
			var val = this.value;
			if ((i = val.indexOf('.')) != -1) {
				if (e.which!=8 && e.which!=0 && (e.which<48 || e.which>57))
					return false;
			} else {
				if (e.which!=8 && e.which!=190 && e.which != 46 && e.which!=0 && (e.which<48 || e.which>57)) 
					return false;
			}
			return true;
		};
		
		return this.each(function(i, e) {
			var self = $(this);
			if (self.is(':input')) {
				$(this).blur(function() {
					this.value = _options.prefix + format(this.value, _options.cents);	
				}).keypress(keypress);
				
				this.value = _options.prefix + format(this.value, _options.cents);
			} else {
				self.html(_options.prefix + format(self.html(), _options.cents));
			}
			
		});
	};
}(jQuery));
