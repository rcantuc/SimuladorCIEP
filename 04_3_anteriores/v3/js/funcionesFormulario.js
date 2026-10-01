// JavaScript Document

function dselecradio(radioNombre)
{
		$('#'+radioNombre+'1').prop('checked', false);
		$('#'+radioNombre+'3').prop('checked', false);
}

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


(function() {
  /**
   * Decimal adjustment of a number.
   *
   * @param {String}  type  The type of adjustment.
   * @param {Number}  value The number.
   * @param {Integer} exp   The exponent (the 10 logarithm of the adjustment base).
   * @returns {Number} The adjusted value.
   */
  function decimalAdjust(type, value, exp) {
    // If the exp is undefined or zero...
    if (typeof exp === 'undefined' || +exp === 0) {
      return Math[type](value);
    }
    value = +value;
    exp = +exp;
    // If the value is not a number or the exp is not an integer...
    if (isNaN(value) || !(typeof exp === 'number' && exp % 1 === 0)) {
      return NaN;
    }
    // Shift
    value = value.toString().split('e');
    value = Math[type](+(value[0] + 'e' + (value[1] ? (+value[1] - exp) : -exp)));
    // Shift back
    value = value.toString().split('e');
    return +(value[0] + 'e' + (value[1] ? (+value[1] + exp) : exp));
  }

  // Decimal round
  if (!Math.round10) {
    Math.round10 = function(value, exp) {
      return decimalAdjust('round', value, exp);
    };
  }
  // Decimal floor
  if (!Math.floor10) {
    Math.floor10 = function(value, exp) {
      return decimalAdjust('floor', value, exp);
    };
  }
  // Decimal ceil
  if (!Math.ceil10) {
    Math.ceil10 = function(value, exp) {
      return decimalAdjust('ceil', value, exp);
    };
  }
})();

$(document).ready(function() {
	
/********************  Funciones globales  ******************************/

	var actualizaItemGraf = function(num, valor) {
		$('#barI'+num).attr('bar-value',valor);
//		$('#barII'+num).attr('bar-value',valor);
		$('#bar_shrfsp'+num).text(valor);					
	}
	var actualizaItemGraf2 = function(num, valor) {
//		$('#barI'+num).attr('bar-value',valor);
		$('#barII'+num).attr('bar-value',valor);
		$('#bar_shrfspII'+num).text(valor);					
	}


	var cambiosGlobales = function(html) {

		var ingbruto_decil=eval($(html).find("ingbruto_decil").text()); 
		var ingresos_decil=eval($(html).find("ingresos_decil").text()); 
		var gastos_decil=eval($(html).find("gastos_decil").text()); 
		var ingneto_decil=eval($(html).find("ingneto_decil").text()); 
		var incid_global_decil=eval($(html).find("incid_global_decil").text()); 

		var ingbruto_sexo=eval($(html).find("ingbruto_sexo").text()); 
		var ingresos_sexo=eval($(html).find("ingresos_sexo").text()); 
		var gastos_sexo=eval($(html).find("gastos_sexo").text()); 
		var ingneto_sexo=eval($(html).find("ingneto_sexo").text()); 
		var incid_global_sexo=eval($(html).find("incid_global_sexo").text()); 

		var ingbruto_edad=eval($(html).find("ingbruto_edad").text()); 
		var ingresos_edad=eval($(html).find("ingresos_edad").text()); 
		var gastos_edad=eval($(html).find("gastos_edad").text()); 
		var ingneto_edad=eval($(html).find("ingneto_edad").text()); 
		var incid_global_edad=eval($(html).find("incid_global_edad").text()); 

		var shrfsp=eval($(html).find("shrfsp").text()); 
		var shrfsp_pc=eval($(html).find("shrfsp_pc").text()); 

		var deuda_2015=eval($(html).find("deuda_2015").text()); 
		var deuda_2030=eval($(html).find("deuda_2030").text()); 
		var deuda_2015_pib=eval($(html).find("deuda_2015_pib").text()); 
		var deuda_2030_pib=eval($(html).find("deuda_2030_pib").text()); 

		var tamanio0=eval($(html).find("tamanio0").text()); 
		var tamanio1=eval($(html).find("tamanio1").text()); 

		var gini=eval($(html).find("gini").text()); 

		var PEF=eval($(html).find("PEF").text()); 
		var LIF=eval($(html).find("LIF").text()); 

		for(var i=0;i<ingbruto_decil.length;i++) { 
			$('#INGTOT'+i).html(ingbruto_decil[i]);
			$('#INGRESOS'+i).html(ingresos_decil[i]);
			$('#GASTOS'+i).html(gastos_decil[i]);
			$('#INGNETO'+i).html(ingneto_decil[i]);
			$('#INCDTOT'+i).html(incid_global_decil[i]);
		}

		for(var i=0;i<ingbruto_sexo.length;i++) { 
			$('#Sexo_INGTOT'+i).html(ingbruto_sexo[i]);
			$('#Sexo_INGRESOS'+i).html(ingresos_sexo[i]);
			$('#Sexo_GASTOS'+i).html(gastos_sexo[i]);
			$('#Sexo_INGNETO'+i).html(ingneto_sexo[i]);
			$('#Sexo_INCDTOT'+i).html(incid_global_sexo[i]);
		}

		for(var i=0;i<ingbruto_edad.length;i++) { 
			$('#Edad_INGTOT'+i).html(ingbruto_edad[i]);
			$('#Edad_INGRESOS'+i).html(ingresos_edad[i]);
			$('#Edad_GASTOS'+i).html(gastos_edad[i]);
			$('#Edad_INGNETO'+i).html(ingneto_edad[i]);
			$('#Edad_INCDTOT'+i).html(incid_global_edad[i]);
		}



		/******************  Actualizar el gráfico de barras ***********/
		for(var i=0;i<shrfsp.length;i++) {
			var anio=2000+2*i; 
			actualizaItemGraf(anio,shrfsp[i]);
		}
		positionBars();
		for(var i=0;i<shrfsp_pc.length;i++) {
			var anio=2000+2*i; 
			actualizaItemGraf2(anio,shrfsp_pc[i]);
		}
		positionBars2();
		/******************  Fin de gráfico de barras ***********/
		for(var i=0;i<deuda_2015.length;i++) {
			$('#deuda_2015'+i).html(deuda_2015[i]);
			$('#deuda_2030'+i).html(deuda_2030[i]);
			$('#deuda_2015_pib'+i).html(deuda_2015_pib[i]);
			$('#deuda_2030_pib'+i).html(deuda_2030_pib[i]);
		}

		for(var i=0;i<tamanio0.length;i++) {
			$('#tamanioI'+i).html(tamanio0[i]+" a&ntilde;os");
			$('#tamanioII'+i).html(tamanio1[i]+ " a&ntilde;os");
		}

      $("#slider1").slider({
       	value:gini[0]*100,
   	   slide: function(event, ui) {
				update(2,ui.value); //changed
			}
      });
	   $("#slider2").slider({
	   	value:gini[1]*100,
    	   slide: function(event, ui) {
      		update(2,ui.value); //changed
    	   }
      });
      $("#amount").val(Math.round10(gini[0], -3));
		$("#duration").val(Math.round10(gini[1], -3));
    	$("#amount-label").text(Math.round10(gini[0], -3));
      $("#duration-label").text(Math.round10(gini[1], -3));
         
      update();

		if (window.google && google.visualization && google.visualization.arrayToDataTable) { // MUSEO (2026-10-01): con loader.js la API carga asíncrona; si aún no está, los treemaps los dibuja el callback de la página
var data = google.visualization.arrayToDataTable([
          ['Location', 'Parent', 'Market trade volume (size)', 'Market increase/decrease (color)'],
          ['LIF',    			null,				0, 			0],
          ['Impuestos',   		'LIF',			0, 			0],
          ['Cuotas',    		'LIF',             	0, 			0],
          ['Aprovechamientos',	'LIF',             	0, 			0],
          ['Ventas',    		'LIF',             	0, 			0],
          ['Transferencias',    'LIF',             	0, 			0],
          ['< 1% de la LIF',    'LIF',             	0, 			0],
          ['ISR (físicas)',		'Impuestos',		LIF[0], 		LIF[0]],
          ['ISR (morales)',		'Impuestos',   	LIF[1], 		LIF[1]],
          ['IVA',				'Impuestos',        		LIF[2], 		LIF[2]],
          ['< 1% LIF (I)',		'Impuestos',			LIF[3], 		LIF[3]],
          ['Seguro Social',		'Cuotas',      	LIF[4], 		LIF[4]],
          ['Otros',     		'Aprovechamientos', 	LIF[5], 		LIF[5]],
          ['< 1% LIF (A)',		'Aprovechamientos', 	LIF[6], 		LIF[6]],
          ['CFE',  				'Ventas',         	LIF[7], 		LIF[7]],
          ['ISSSTE',    		'Ventas',           	LIF[8], 		LIF[8]],
          ['PEMEX',      		'Ventas',           	LIF[9], 		LIF[9]],
          ['< 1% LIF (V)',  	'Ventas', 				LIF[10], 	LIF[10]],
          ['FMP',     			'Transferencias', 	LIF[11], 	LIF[11]],
          ['< 1% LIF (<)',     	'< 1% de la LIF', LIF[12], 	LIF[12]],
        ]);


        tree = new google.visualization.TreeMap(document.getElementById('chart_cuadros1'));

        tree.draw(data, {
          minColor: '#00acd2',
          midColor: '#7c5785',
          maxColor: '#fb0037',
          headerHeight: 20,
		  headerColor: '#bbeb92',
          fontColor: 'black',
          showScale: true
        });
	 

        var data = google.visualization.arrayToDataTable([
          ['Location', 'Parent', 'Market trade volume (size)', 'Market increase/decrease (color)'],
          ['PEF',    			null,               0, 			0],
          ['Agropecuaria, Silvicultura, Pesca y Caza',   		'PEF',             	0, 			0],
          ['Asuntos de Orden Público y de Seguridad Interior',    		'PEF',             	0, 			0],
          ['Ciencia, Tecnología e Innovación',	'PEF',             	0, 			0],
          ['Combustibles y Energía',    		'PEF',             	0, 			0],
          ['Educación',    'PEF',             	0, 			0],
          ['Justicia',    'PEF',             	0, 			0],
          ['Protección Social',    'PEF',             	0, 			0],
          ['Salud',    'PEF',             	0, 			0],
          ['Seguridad Nacional',    'PEF',             	0, 			0],
          ['Transacciones/Costo Financiero de la Deuda',    'PEF',             	0, 			0],
          ['Transferencias, Participaciones y Aportaciones',    'PEF',             	0, 			0],
          ['Transporte',    'PEF',             	0, 			0],
          ['Vivienda',    'PEF',             	0, 			0],
          ['< 1% del PEF',    'PEF',             	0, 			0],
          ['Agropecuaria',		'Agropecuaria, Silvicultura, Pesca y Caza',        				PEF[0], PEF[0]],
          ['< 1% del PEF (A)',		'Agropecuaria, Silvicultura, Pesca y Caza',					PEF[1], PEF[1]],
          ['< 1% del PEF (B)',				'Asuntos de Orden Público y de Seguridad Interior',PEF[2], PEF[2]],
          ['< 1% del PEF (C)',		'Ciencia, Tecnología e Innovación',								PEF[3], PEF[3]],
          ['Electricidad',		'Combustibles y Energía',          										PEF[4], PEF[4]],
          ['Petróleo y Gas Natural',     		'Combustibles y Energía', 								PEF[5], PEF[5]],
          ['< 1% del PEF (D)',		'Combustibles y Energía', 											PEF[6], PEF[6]],
          ['Básica',  				'Educación',           													PEF[7], PEF[7]],
          ['Media Superior',    		'Educación',           												PEF[8], PEF[8]],
          ['Superior',      		'Educación',           													PEF[9], PEF[9]],
          ['< 1% del PEF (E)',  	'Educación',           													PEF[10], PEF[10]],
          ['Impartición de Justicia',     			'Justicia',   										PEF[11], PEF[11]],
          ['< 1% del PEF (F)',     	'Justicia',   															PEF[12], PEF[12]],
          ['Edad Avanzada',     			'Protección Social',   											PEF[13], PEF[13]],
          ['Otros Grupos Vulnerables',     	'Protección Social',   									PEF[14], PEF[14]],
          ['< 1% del PEF (G)',     			'Protección Social',   										PEF[15], PEF[15]],
          ['Prestación de Servicios de Salud a la Persona',     	'Salud',   						PEF[16], PEF[16]],
          ['Protección Social en Salud',     			'Salud',   										PEF[17], PEF[17]],
          ['< 1% del PEF (H)',     	'Salud',   																PEF[18], PEF[18]],
          ['Defensa',     	'Seguridad Nacional',   														PEF[19], PEF[19]],
          ['< 1% del PEF (I)',     			'Seguridad Nacional',   									PEF[20], PEF[20]],
          ['Deuda Pública Externa',     	'Transacciones/Costo Financiero de la Deuda',   	PEF[21], PEF[21]],
          ['Deuda Pública Interna',     			'Transacciones/Costo Financiero de la Deuda',PEF[22], PEF[22]],
          ['Participaciones entre Diferentes Niveles y Órdenes de Gobierno',     			'Transferencias, Participaciones y Aportaciones',PEF[23], PEF[23]],
          ['Transporte por Carretera',     			'Transporte',   									PEF[24], PEF[24]],
          ['< 1% del PEF (J)',     			'Transporte',   												PEF[25], PEF[25]],
          ['Desarrollo Regional',     			'Vivienda',   												PEF[26], PEF[26]],
          ['< 1% del PEF (K)',     			'Vivienda',   													PEF[27], PEF[27]],
          ['< 1% del PEF (L)',     			'< 1% del PEF',   											PEF[28], PEF[28]],
        ]);

        tree1 = new google.visualization.TreeMap(document.getElementById('chart_cuadros2'));


        tree1.draw(data, {
          minColor: '#00acd2',
          midColor: '#7c5785',
          maxColor: '#fb0037',
          headerHeight: 20,
		  headerColor: '#bbeb92',
          fontColor: 'black',
          showScale: true
        });
        }


	}
	
	
	var idSession=makeid(); 
	if(getCookie("idSession")!=null) {
		idSession=getCookie("idSession");
	} 
	
	$.ajax({
		//this is the php file that processes the data and send mail
		url: "defaultStata.xml", dataType: "xml", // MUSEO (2026-10-01): respuesta estática; el original llamaba defaultStata.php	
		
		async:false,
		//GET method is used
		type: "GET",
		//pass the data			
		data: "idSession="+idSession,		
				
		//Do not cache the page
		cache: false,
				
		//success
		success: function (html) {	
	
	
						var iva3_I1 = eval($(html).find("iva2_I1").text()); 
					var iva3_I2 = eval($(html).find("iva2_I2").text()); 
					var iva3_I3 = eval($(html).find("iva2_I3").text()); 
					var iva3_V = eval($(html).find("iva2_V").text()); 

					var iva3_PH = eval($(html).find("iva2_PH").text()); 
					var iva3_CH = eval($(html).find("iva2_CH").text()); 
					var iva3_PM = eval($(html).find("iva2_PM").text()); 
					var iva3_CM = eval($(html).find("iva2_CM").text()); 
 
					var iva3_PROY = eval($(html).find("iva2_PROY").text()); 
					var iva3_shcp_PROY = eval($(html).find("iva2_shcp_PROY").text()); 
 

					cambiosGlobales(html);

					for(var i=0;i<iva3_I1.length;i++) { 
						$('#iva3_I1_'+i).html(iva3_I1[i]);
						$('#iva3_I2_'+i).html(iva3_I2[i]);
						$('#iva3_I3_'+i).html(iva3_I3[i]);
					}
					
					for(var i=0;i<iva3_I1.length;i++) { 
						$('#iva3_V_'+i).html(iva3_V[i]);
					}




        var lineChartData1 = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [iva3_PH[0], iva3_PH[1], iva3_PH[2], iva3_PH[3], iva3_PH[4], iva3_PH[5], iva3_PH[6], iva3_PH[7], iva3_PH[8], iva3_PH[9], iva3_PH[10], iva3_PH[11], iva3_PH[12], iva3_PH[13], iva3_PH[14], iva3_PH[15], iva3_PH[16], iva3_PH[17], iva3_PH[18], iva3_PH[19], iva3_PH[20], iva3_PH[21], iva3_PH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [iva3_PM[0], iva3_PM[1], iva3_PM[2], iva3_PM[3], iva3_PM[4], iva3_PM[5], iva3_PM[6], iva3_PM[7], iva3_PM[8], iva3_PM[9], iva3_PM[10], iva3_PM[11], iva3_PM[12], iva3_PM[13], iva3_PM[14], iva3_PM[15], iva3_PM[16], iva3_PM[17], iva3_PM[18], iva3_PM[19], iva3_PM[20], iva3_PM[21], iva3_PM[22]]
                }
            ]

        }

        var lineChartData1b = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [iva3_CH[0], iva3_CH[1], iva3_CH[2], iva3_CH[3], iva3_CH[4], iva3_CH[5], iva3_CH[6], iva3_CH[7], iva3_CH[8], iva3_CH[9], iva3_CH[10], iva3_CH[11], iva3_CH[12], iva3_CH[13], iva3_CH[14], iva3_CH[15], iva3_CH[16], iva3_CH[17], iva3_CH[18], iva3_CH[19], iva3_CH[20], iva3_CH[21], iva3_CH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [iva3_CM[0], iva3_CM[1], iva3_CM[2], iva3_CM[3], iva3_CM[4], iva3_CM[5], iva3_CM[6], iva3_CM[7], iva3_CM[8], iva3_CM[9], iva3_CM[10], iva3_CM[11], iva3_CM[12], iva3_CM[13], iva3_CM[14], iva3_CM[15], iva3_CM[16], iva3_CM[17], iva3_CM[18], iva3_CM[19], iva3_CM[20], iva3_CM[21], iva3_CM[22]]
                }
            ]

        }



        var ctxPerfilesMenu1 = document.getElementById("canvas-perfiles-menu1").getContext("2d");
        ctxPerfilesMenu1.clearRect(0, 0, ctxPerfilesMenu1.width, ctxPerfilesMenu1.height);
          window.myLinePerfilesMenu1 = new Chart(ctxPerfilesMenu1).Line(lineChartData1, {
            responsive: false
        });

        $( "#bnt-line-1" ).click(function() {
          var ctxPerfilesMenu1 = document.getElementById("canvas-perfiles-menu1").getContext("2d");
          ctxPerfilesMenu1.clearRect(0, 0, ctxPerfilesMenu1.width, ctxPerfilesMenu1.height);
          window.myLinePerfilesMenu1 = new Chart(ctxPerfilesMenu1).Line(lineChartData1, {
            responsive: false
          });
        });
       
       
        $( "#bnt-line-1b" ).click(function() {
          var ctxPerfilesMenu1b = document.getElementById("canvas-perfiles-menu1b").getContext("2d");
          window.myLinePerfilesMenu1b = new Chart(ctxPerfilesMenu1b).Line(lineChartData1b, {
            responsive: false
          });
        });

 

    var canvas = document.getElementById('canvas-proyeccion-menu1'),
    ctxProyeccionMenu1 = canvas.getContext('2d'),
    startingData = {
            labels : [1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,
            2017,2018,2019,2020,2021,2022,2023,2024,2025,2026,2027,2028,2029,2030],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "SHCP",
                    fillColor : "rgba(206,206,206,0.2)",
                    strokeColor : "rgba(206,206,206,1)",
                    pointColor : "rgba(206,206,206,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(206,206,206,1)",
                    data : [iva3_shcp_PROY[0], iva3_shcp_PROY[1], iva3_shcp_PROY[2], iva3_shcp_PROY[3], iva3_shcp_PROY[4], iva3_shcp_PROY[5],
                    iva3_shcp_PROY[6], iva3_shcp_PROY[7], iva3_shcp_PROY[8], iva3_shcp_PROY[9], iva3_shcp_PROY[10], iva3_shcp_PROY[11], 
                    iva3_shcp_PROY[12], iva3_shcp_PROY[13], iva3_shcp_PROY[14], iva3_shcp_PROY[15], iva3_shcp_PROY[16], iva3_shcp_PROY[17], 
                    iva3_shcp_PROY[18], iva3_shcp_PROY[19], iva3_shcp_PROY[20], iva3_shcp_PROY[21] , iva3_shcp_PROY[22] ]
                },
                {
                    label: "Proyeccion",
                    fillColor : "rgba(229, 95, 95, 0.2)",
                    strokeColor : "rgba(229, 95, 95, 1)",
                    pointColor : "rgba(229, 95, 95, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(229, 95, 95, 1)",
                    data : [iva3_PROY[0], iva3_PROY[1], iva3_PROY[2], iva3_PROY[3], iva3_PROY[4], iva3_PROY[5], iva3_PROY[6], iva3_PROY[7], 
                    iva3_PROY[8], iva3_PROY[9], iva3_PROY[10], iva3_PROY[11], iva3_PROY[12], iva3_PROY[13], iva3_PROY[14], iva3_PROY[15], 
                    iva3_PROY[16], iva3_PROY[17], iva3_PROY[18], iva3_PROY[19], iva3_PROY[20], iva3_PROY[21], iva3_PROY[22], iva3_PROY[23],
                    iva3_PROY[24], iva3_PROY[25], iva3_PROY[26], iva3_PROY[27], iva3_PROY[28], iva3_PROY[29], iva3_PROY[30],
                    iva3_PROY[31], iva3_PROY[32], iva3_PROY[33], iva3_PROY[34], iva3_PROY[35], iva3_PROY[36], iva3_PROY[37] ]
                }
      ]
    };
    var myChartProyeccionMenu1 = new Chart(ctxProyeccionMenu1).Line(startingData, {animationSteps: 15});




					var isr3_I1 = eval($(html).find("isr3_I1").text()); 
					var isr3_I2 = eval($(html).find("isr3_I2").text()); 
					var isr3_I3 = eval($(html).find("isr3_I3").text()); 
					var isr3_V = eval($(html).find("isr3_V").text()); 
					var isr3_PH = eval($(html).find("isr3_PH").text()); 
					var isr3_CH = eval($(html).find("isr3_CH").text()); 
					var isr3_PM = eval($(html).find("isr3_PM").text()); 
					var isr3_CM = eval($(html).find("isr3_CM").text()); 
					var isr3_PROY = eval($(html).find("isr3_PROY").text()); 
					var isr3_shcp_PROY = eval($(html).find("isr3_shcp_PROY").text()); 


					for(var i=0;i<isr3_I1.length;i++) { 
						$('#isr3_I1_'+i).html(isr3_I1[i]);
						$('#isr3_I2_'+i).html(isr3_I2[i]);
						$('#isr3_I3_'+i).html(isr3_I3[i]);
					}
					
					for(var i=0;i<isr3_V.length;i++) { 
						$('#isr3_V_'+i).html(isr3_V[i]);
					}




        var lineChartData2 = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [isr3_PH[0], isr3_PH[1], isr3_PH[2], isr3_PH[3], isr3_PH[4], isr3_PH[5], isr3_PH[6], isr3_PH[7], isr3_PH[8], isr3_PH[9], isr3_PH[10], isr3_PH[11], isr3_PH[12], isr3_PH[13], isr3_PH[14], isr3_PH[15], isr3_PH[16], isr3_PH[17], isr3_PH[18], isr3_PH[19], isr3_PH[20], isr3_PH[21], isr3_PH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [isr3_PM[0], isr3_PM[1], isr3_PM[2], isr3_PM[3], isr3_PM[4], isr3_PM[5], isr3_PM[6], isr3_PM[7], isr3_PM[8], isr3_PM[9], isr3_PM[10], isr3_PM[11], isr3_PM[12], isr3_PM[13], isr3_PM[14], isr3_PM[15], isr3_PM[16], isr3_PM[17], isr3_PM[18], isr3_PM[19], isr3_PM[20], isr3_PM[21], isr3_PM[22]]
                }
            ]

        }


        var lineChartData2b = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [isr3_CH[0], isr3_CH[1], isr3_CH[2], isr3_CH[3], isr3_CH[4], isr3_CH[5], isr3_CH[6], isr3_CH[7], isr3_CH[8], isr3_CH[9], isr3_CH[10], isr3_CH[11], isr3_CH[12], isr3_CH[13], isr3_CH[14], isr3_CH[15], isr3_CH[16], isr3_CH[17], isr3_CH[18], isr3_CH[19], isr3_CH[20], isr3_CH[21], isr3_CH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [isr3_CM[0], isr3_CM[1], isr3_CM[2], isr3_CM[3], isr3_CM[4], isr3_CM[5], isr3_CM[6], isr3_CM[7], isr3_CM[8], isr3_CM[9], isr3_CM[10], isr3_CM[11], isr3_CM[12], isr3_CM[13], isr3_CM[14], isr3_CM[15], isr3_CM[16], isr3_CM[17], isr3_CM[18], isr3_CM[19], isr3_CM[20], isr3_CM[21], isr3_CM[22]]
                }
            ]

        }


        var ctxPerfilesMenu2 = document.getElementById("canvas-perfiles-menu2").getContext("2d");
          window.myLinePerfilesMenu2 = new Chart(ctxPerfilesMenu2).Line(lineChartData2, {
            responsive: false
        });
        $( "#bnt-line-2" ).click(function() {
          var ctxPerfilesMenu2 = document.getElementById("canvas-perfiles-menu2").getContext("2d");
          window.myLinePerfilesMenu2 = new Chart(ctxPerfilesMenu2).Line(lineChartData2, {
            responsive: false
          });
        });
       
       
        $( "#bnt-line-2b" ).click(function() {
          var ctxPerfilesMenu2b = document.getElementById("canvas-perfiles-menu2b").getContext("2d");
          window.myLinePerfilesMenu2b = new Chart(ctxPerfilesMenu2b).Line(lineChartData2b, {
            responsive: false
          });
        });

    var canvas = document.getElementById('canvas-proyeccion-menu2'),
    ctxProyeccionMenu2 = canvas.getContext('2d'),
    startingData = {
            labels : [1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,
            2017,2018,2019,2020,2021,2022,2023,2024,2025,2026,2027,2028,2029,2030],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(206,206,206,0.2)",
                    strokeColor : "rgba(206,206,206,1)",
                    pointColor : "rgba(206,206,206,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(206,206,206,1)",
                    data : [null,null,null,null,null,null,null,null,null,isr3_shcp_PROY[0], isr3_shcp_PROY[1], isr3_shcp_PROY[2], isr3_shcp_PROY[3], isr3_shcp_PROY[4], isr3_shcp_PROY[5],
                    isr3_shcp_PROY[6], isr3_shcp_PROY[7], isr3_shcp_PROY[8], isr3_shcp_PROY[9], isr3_shcp_PROY[10], isr3_shcp_PROY[11], 
                    isr3_shcp_PROY[12], isr3_shcp_PROY[13] ]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(229, 95, 95, 0.2)",
                    strokeColor : "rgba(229, 95, 95, 1)",
                    pointColor : "rgba(229, 95, 95, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(229, 95, 95, 1)",
                    data : [isr3_PROY[0], isr3_PROY[1], isr3_PROY[2], isr3_PROY[3], isr3_PROY[4], isr3_PROY[5], isr3_PROY[6], isr3_PROY[7], 
                    isr3_PROY[8], isr3_PROY[9], isr3_PROY[10], isr3_PROY[11], isr3_PROY[12], isr3_PROY[13], isr3_PROY[14], isr3_PROY[15], 
                    isr3_PROY[16], isr3_PROY[17], isr3_PROY[18], isr3_PROY[19], isr3_PROY[20], isr3_PROY[21], isr3_PROY[22], isr3_PROY[23],
                    isr3_PROY[24], isr3_PROY[25], isr3_PROY[26], isr3_PROY[27], isr3_PROY[28], isr3_PROY[29], isr3_PROY[30],
                    isr3_PROY[31], isr3_PROY[32], isr3_PROY[33], isr3_PROY[34], isr3_PROY[35], isr3_PROY[36], isr3_PROY[37] ]
                }
      ]
    };
    var myChartProyeccionMenu2 = new Chart(ctxProyeccionMenu2).Line(startingData, {animationSteps: 15});


					var salud_imss_issste_I1 = eval($(html).find("cuotasT2_I1").text()); 
					var salud_imss_issste_I2 = eval($(html).find("cuotasT2_I2").text()); 
					var salud_imss_issste_I3 = eval($(html).find("cuotasT2_I3").text()); 
					var salud_imss_issste_V = eval($(html).find("cuotasT2_V").text()); 
					var salud_imss_issste_PH = eval($(html).find("cuotasT2_PH").text()); 
					var salud_imss_issste_CH = eval($(html).find("cuotasT2_CH").text()); 
					var salud_imss_issste_PM = eval($(html).find("cuotasT2_PM").text()); 
					var salud_imss_issste_CM = eval($(html).find("cuotasT2_CM").text()); 
 					var salud_imss_issste_PROY = eval($(html).find("cuotasT2_PROY").text()); 
					var salud_imss_issste_shcp_PROY = eval($(html).find("cuotasT2_shcp_PROY").text()); 


					for(var i=0;i<salud_imss_issste_I1.length;i++) { 
						$('#salud_imss_issste_I1_'+i).html(salud_imss_issste_I1[i]);
						$('#salud_imss_issste_I2_'+i).html(salud_imss_issste_I2[i]);
						$('#salud_imss_issste_I3_'+i).html(salud_imss_issste_I3[i]);
					}
					
					for(var i=0;i<salud_imss_issste_V.length;i++) { 
						$('#salud_imss_issste_V_'+i).html(salud_imss_issste_V[i]);
					}




        var lineChartData4 = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [salud_imss_issste_PH[0], salud_imss_issste_PH[1], salud_imss_issste_PH[2], salud_imss_issste_PH[3], salud_imss_issste_PH[4], salud_imss_issste_PH[5], salud_imss_issste_PH[6], salud_imss_issste_PH[7], salud_imss_issste_PH[8], salud_imss_issste_PH[9], salud_imss_issste_PH[10], salud_imss_issste_PH[11], salud_imss_issste_PH[12], salud_imss_issste_PH[13], salud_imss_issste_PH[14], salud_imss_issste_PH[15], salud_imss_issste_PH[16], salud_imss_issste_PH[17], salud_imss_issste_PH[18], salud_imss_issste_PH[19], salud_imss_issste_PH[20], salud_imss_issste_PH[21], salud_imss_issste_PH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [salud_imss_issste_PM[0], salud_imss_issste_PM[1], salud_imss_issste_PM[2], salud_imss_issste_PM[3], salud_imss_issste_PM[4], salud_imss_issste_PM[5], salud_imss_issste_PM[6], salud_imss_issste_PM[7], salud_imss_issste_PM[8], salud_imss_issste_PM[9], salud_imss_issste_PM[10], salud_imss_issste_PM[11], salud_imss_issste_PM[12], salud_imss_issste_PM[13], salud_imss_issste_PM[14], salud_imss_issste_PM[15], salud_imss_issste_PM[16], salud_imss_issste_PM[17], salud_imss_issste_PM[18], salud_imss_issste_PM[19], salud_imss_issste_PM[20], salud_imss_issste_PM[21], salud_imss_issste_PM[22]]
                }
            ]

        }


        var lineChartData4b = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [salud_imss_issste_CH[0], salud_imss_issste_CH[1], salud_imss_issste_CH[2], salud_imss_issste_CH[3], salud_imss_issste_CH[4], salud_imss_issste_CH[5], salud_imss_issste_CH[6], salud_imss_issste_CH[7], salud_imss_issste_CH[8], salud_imss_issste_CH[9], salud_imss_issste_CH[10], salud_imss_issste_CH[11], salud_imss_issste_CH[12], salud_imss_issste_CH[13], salud_imss_issste_CH[14], salud_imss_issste_CH[15], salud_imss_issste_CH[16], salud_imss_issste_CH[17], salud_imss_issste_CH[18], salud_imss_issste_CH[19], salud_imss_issste_CH[20], salud_imss_issste_CH[21], salud_imss_issste_CH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [salud_imss_issste_CM[0], salud_imss_issste_CM[1], salud_imss_issste_CM[2], salud_imss_issste_CM[3], salud_imss_issste_CM[4], salud_imss_issste_CM[5], salud_imss_issste_CM[6], salud_imss_issste_CM[7], salud_imss_issste_CM[8], salud_imss_issste_CM[9], salud_imss_issste_CM[10], salud_imss_issste_CM[11], salud_imss_issste_CM[12], salud_imss_issste_CM[13], salud_imss_issste_CM[14], salud_imss_issste_CM[15], salud_imss_issste_CM[16], salud_imss_issste_CM[17], salud_imss_issste_CM[18], salud_imss_issste_CM[19], salud_imss_issste_CM[20], salud_imss_issste_CM[21], salud_imss_issste_CM[22]]
                }
            ]

        }

        var canvCls = document.getElementById("canvas-perfiles-menu4").getContext("2d");
        canvCls.clearRect(0, 0, canvCls.width, canvCls.height);
        canvCls = document.getElementById("canvas-perfiles-menu4b").getContext("2d");
        canvCls.clearRect(0, 0, canvCls.width, canvCls.height);

        var ctxPerfilesMenu4 = document.getElementById("canvas-perfiles-menu4").getContext("2d");
          window.myLinePerfilesMenu4 = new Chart(ctxPerfilesMenu4).Line(lineChartData4, {
            responsive: false
        });
        $( "#bnt-line-4" ).click(function() {
          var ctxPerfilesMenu4 = document.getElementById("canvas-perfiles-menu4").getContext("2d");
          ctxPerfilesMenu4.clearRect(0, 0, ctxPerfilesMenu4.width, ctxPerfilesMenu4.height);
          window.myLinePerfilesMenu4 = new Chart(ctxPerfilesMenu4).Line(lineChartData4, {
            responsive: false
          });
        });
       
       
        $( "#bnt-line-4b" ).click(function() {
          var ctxPerfilesMenu4b = document.getElementById("canvas-perfiles-menu4b").getContext("2d");
          ctxPerfilesMenu4b.clearRect(0, 0, ctxPerfilesMenu4b.width, ctxPerfilesMenu4b.height);
          window.myLinePerfilesMenu4b = new Chart(ctxPerfilesMenu4b).Line(lineChartData4b, {
            responsive: false
          });
        });

    var canvas = document.getElementById('canvas-proyeccion-menu4'),
    ctxProyeccionMenu4 = canvas.getContext('2d'),
    startingData = {
            labels : [1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,
            2017,2018,2019,2020,2021,2022,2023,2024,2025,2026,2027,2028,2029,2030],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(206,206,206,0.2)",
                    strokeColor : "rgba(206,206,206,1)",
                    pointColor : "rgba(206,206,206,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(206,206,206,1)",
                    data : [null,null,null,null,null,null,null,null,null,null,null,null,null,null,salud_imss_issste_shcp_PROY[0], salud_imss_issste_shcp_PROY[1], salud_imss_issste_shcp_PROY[2], salud_imss_issste_shcp_PROY[3], salud_imss_issste_shcp_PROY[4], salud_imss_issste_shcp_PROY[5],
                    salud_imss_issste_shcp_PROY[6], salud_imss_issste_shcp_PROY[7], salud_imss_issste_shcp_PROY[8] ]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(229, 95, 95, 0.2)",
                    strokeColor : "rgba(229, 95, 95, 1)",
                    pointColor : "rgba(229, 95, 95, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(229, 95, 95, 1)",
                    data : [salud_imss_issste_PROY[0], salud_imss_issste_PROY[1], salud_imss_issste_PROY[2], salud_imss_issste_PROY[3], salud_imss_issste_PROY[4], salud_imss_issste_PROY[5], salud_imss_issste_PROY[6], salud_imss_issste_PROY[7], 
                    salud_imss_issste_PROY[8], salud_imss_issste_PROY[9], salud_imss_issste_PROY[10], salud_imss_issste_PROY[11], salud_imss_issste_PROY[12], salud_imss_issste_PROY[13], salud_imss_issste_PROY[14], salud_imss_issste_PROY[15], 
                    salud_imss_issste_PROY[16], salud_imss_issste_PROY[17], salud_imss_issste_PROY[18], salud_imss_issste_PROY[19], salud_imss_issste_PROY[20], salud_imss_issste_PROY[21], salud_imss_issste_PROY[22], salud_imss_issste_PROY[23],
                    salud_imss_issste_PROY[24], salud_imss_issste_PROY[25], salud_imss_issste_PROY[26], salud_imss_issste_PROY[27], salud_imss_issste_PROY[28], salud_imss_issste_PROY[29], salud_imss_issste_PROY[30],
                    salud_imss_issste_PROY[31], salud_imss_issste_PROY[32], salud_imss_issste_PROY[33], salud_imss_issste_PROY[34], salud_imss_issste_PROY[35], salud_imss_issste_PROY[36], salud_imss_issste_PROY[37] ]
                }
      ]
    };
    var myChartProyeccionMenu4 = new Chart(ctxProyeccionMenu4).Line(startingData, {animationSteps: 15});


					var isr_pm_I1 = eval($(html).find("isr_pm_I1").text()); 
					var isr_pm_I2 = eval($(html).find("isr_pm_I2").text()); 
					var isr_pm_I3 = eval($(html).find("isr_pm_I3").text()); 
					var isr_pm_V = eval($(html).find("isr_pm_V").text()); 
					var isr_pm_PH = eval($(html).find("isr_pm_PH").text()); 
					var isr_pm_CH = eval($(html).find("isr_pm_CH").text()); 
					var isr_pm_PM = eval($(html).find("isr_pm_PM").text()); 
					var isr_pm_CM = eval($(html).find("isr_pm_CM").text()); 
					var isr_pm_PROY = eval($(html).find("isr_pm_PROY").text()); 
					var isr_pm_shcp_PROY = eval($(html).find("isr_pm_shcp_PROY").text()); 


					for(var i=0;i<isr_pm_I1.length;i++) { 
						$('#isr_pm_I1_'+i).html(isr_pm_I1[i]);
						$('#isr_pm_I2_'+i).html(isr_pm_I2[i]);
						$('#isr_pm_I3_'+i).html(isr_pm_I3[i]);
					}
					
					for(var i=0;i<isr_pm_V.length;i++) { 
						$('#isr_pm_V_'+i).html(isr_pm_V[i]);
					}




        var lineChartData3 = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [isr_pm_PH[0], isr_pm_PH[1], isr_pm_PH[2], isr_pm_PH[3], isr_pm_PH[4], isr_pm_PH[5], isr_pm_PH[6], isr_pm_PH[7], isr_pm_PH[8], isr_pm_PH[9], isr_pm_PH[10], isr_pm_PH[11], isr_pm_PH[12], isr_pm_PH[13], isr_pm_PH[14], isr_pm_PH[15], isr_pm_PH[16], isr_pm_PH[17], isr_pm_PH[18], isr_pm_PH[19], isr_pm_PH[20], isr_pm_PH[21], isr_pm_PH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [isr_pm_PM[0], isr_pm_PM[1], isr_pm_PM[2], isr_pm_PM[3], isr_pm_PM[4], isr_pm_PM[5], isr_pm_PM[6], isr_pm_PM[7], isr_pm_PM[8], isr_pm_PM[9], isr_pm_PM[10], isr_pm_PM[11], isr_pm_PM[12], isr_pm_PM[13], isr_pm_PM[14], isr_pm_PM[15], isr_pm_PM[16], isr_pm_PM[17], isr_pm_PM[18], isr_pm_PM[19], isr_pm_PM[20], isr_pm_PM[21], isr_pm_PM[22]]
                }
            ]

        }


        var lineChartData3b = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [isr_pm_CH[0], isr_pm_CH[1], isr_pm_CH[2], isr_pm_CH[3], isr_pm_CH[4], isr_pm_CH[5], isr_pm_CH[6], isr_pm_CH[7], isr_pm_CH[8], isr_pm_CH[9], isr_pm_CH[10], isr_pm_CH[11], isr_pm_CH[12], isr_pm_CH[13], isr_pm_CH[14], isr_pm_CH[15], isr_pm_CH[16], isr_pm_CH[17], isr_pm_CH[18], isr_pm_CH[19], isr_pm_CH[20], isr_pm_CH[21], isr_pm_CH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [isr_pm_CM[0], isr_pm_CM[1], isr_pm_CM[2], isr_pm_CM[3], isr_pm_CM[4], isr_pm_CM[5], isr_pm_CM[6], isr_pm_CM[7], isr_pm_CM[8], isr_pm_CM[9], isr_pm_CM[10], isr_pm_CM[11], isr_pm_CM[12], isr_pm_CM[13], isr_pm_CM[14], isr_pm_CM[15], isr_pm_CM[16], isr_pm_CM[17], isr_pm_CM[18], isr_pm_CM[19], isr_pm_CM[20], isr_pm_CM[21], isr_pm_CM[22]]
                }
            ]

        }


        var ctxPerfilesMenu3 = document.getElementById("canvas-perfiles-menu3").getContext("2d");
          window.myLinePerfilesMenu3 = new Chart(ctxPerfilesMenu3).Line(lineChartData3, {
            responsive: false
        });
        $( "#bnt-line-3" ).click(function() {
          var ctxPerfilesMenu3 = document.getElementById("canvas-perfiles-menu3").getContext("2d");
          window.myLinePerfilesMenu3 = new Chart(ctxPerfilesMenu3).Line(lineChartData3, {
            responsive: false
          });
        });
       
       
        $( "#bnt-line-3b" ).click(function() {
          var ctxPerfilesMenu3b = document.getElementById("canvas-perfiles-menu3b").getContext("2d");
          window.myLinePerfilesMenu3b = new Chart(ctxPerfilesMenu3b).Line(lineChartData3b, {
            responsive: false
          });
        });

    var canvas = document.getElementById('canvas-proyeccion-menu3'),
    ctxProyeccionMenu3 = canvas.getContext('2d'),
    startingData = {
            labels : [1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,
            2017,2018,2019,2020,2021,2022,2023,2024,2025,2026,2027,2028,2029,2030],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(206,206,206,0.2)",
                    strokeColor : "rgba(206,206,206,1)",
                    pointColor : "rgba(206,206,206,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(206,206,206,1)",
                    data : [null,null,null,null,null,null,null,null,null,isr_pm_shcp_PROY[0], isr_pm_shcp_PROY[1], isr_pm_shcp_PROY[2], isr_pm_shcp_PROY[3], isr_pm_shcp_PROY[4], isr_pm_shcp_PROY[5],
                    isr_pm_shcp_PROY[6], isr_pm_shcp_PROY[7], isr_pm_shcp_PROY[8], isr_pm_shcp_PROY[9], isr_pm_shcp_PROY[10], isr_pm_shcp_PROY[11], 
                    isr_pm_shcp_PROY[12] ]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(229, 95, 95, 0.2)",
                    strokeColor : "rgba(229, 95, 95, 1)",
                    pointColor : "rgba(229, 95, 95, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(229, 95, 95, 1)",
                    data : [isr_pm_PROY[0], isr_pm_PROY[1], isr_pm_PROY[2], isr_pm_PROY[3], isr_pm_PROY[4], isr_pm_PROY[5], isr_pm_PROY[6], isr_pm_PROY[7], 
                    isr_pm_PROY[8], isr_pm_PROY[9], isr_pm_PROY[10], isr_pm_PROY[11], isr_pm_PROY[12], isr_pm_PROY[13], isr_pm_PROY[14], isr_pm_PROY[15], 
                    isr_pm_PROY[16], isr_pm_PROY[17], isr_pm_PROY[18], isr_pm_PROY[19], isr_pm_PROY[20], isr_pm_PROY[21], isr_pm_PROY[22], isr_pm_PROY[23],
                    isr_pm_PROY[24], isr_pm_PROY[25], isr_pm_PROY[26], isr_pm_PROY[27], isr_pm_PROY[28], isr_pm_PROY[29], isr_pm_PROY[30],
                    isr_pm_PROY[31], isr_pm_PROY[32], isr_pm_PROY[33], isr_pm_PROY[34], isr_pm_PROY[35], isr_pm_PROY[36], isr_pm_PROY[37] ]
                }
      ]
    };
    var myChartProyeccionMenu3 = new Chart(ctxProyeccionMenu3).Line(startingData, {animationSteps: 15});



					var distr_oil_I1 = eval($(html).find("distr_oil_I1").text()); 
					var distr_oil_I2 = eval($(html).find("distr_oil_I2").text()); 
					var distr_oil_I3 = eval($(html).find("distr_oil_I3").text()); 
					var distr_oil_V = eval($(html).find("distr_oil_V").text()); 
					var distr_oil_PH = eval($(html).find("distr_oil_PH").text()); 
					var distr_oil_CH = eval($(html).find("distr_oil_CH").text()); 
					var distr_oil_PM = eval($(html).find("distr_oil_PM").text()); 
					var distr_oil_CM = eval($(html).find("distr_oil_CM").text()); 
 
					var distr_oil_PROY = eval($(html).find("distr_oil_PROY").text()); 
					var distr_oil_shcp_PROY = eval($(html).find("distr_oil_shcp_PROY").text()); 


					for(var i=0;i<distr_oil_I1.length;i++) { 
						$('#distr_oil_I1_'+i).html(distr_oil_I1[i]);
						$('#distr_oil_I2_'+i).html(distr_oil_I2[i]);
						$('#distr_oil_I3_'+i).html(distr_oil_I3[i]);
					}
					
					for(var i=0;i<distr_oil_V.length;i++) { 
						$('#distr_oil_V_'+i).html(distr_oil_V[i]);
					}




        var lineChartData5 = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [distr_oil_PH[0], distr_oil_PH[1], distr_oil_PH[2], distr_oil_PH[3], distr_oil_PH[4], distr_oil_PH[5], distr_oil_PH[6], distr_oil_PH[7], distr_oil_PH[8], distr_oil_PH[9], distr_oil_PH[10], distr_oil_PH[11], distr_oil_PH[12], distr_oil_PH[13], distr_oil_PH[14], distr_oil_PH[15], distr_oil_PH[16], distr_oil_PH[17], distr_oil_PH[18], distr_oil_PH[19], distr_oil_PH[20], distr_oil_PH[21], distr_oil_PH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [distr_oil_PM[0], distr_oil_PM[1], distr_oil_PM[2], distr_oil_PM[3], distr_oil_PM[4], distr_oil_PM[5], distr_oil_PM[6], distr_oil_PM[7], distr_oil_PM[8], distr_oil_PM[9], distr_oil_PM[10], distr_oil_PM[11], distr_oil_PM[12], distr_oil_PM[13], distr_oil_PM[14], distr_oil_PM[15], distr_oil_PM[16], distr_oil_PM[17], distr_oil_PM[18], distr_oil_PM[19], distr_oil_PM[20], distr_oil_PM[21], distr_oil_PM[22]]
                }
            ]

        }


        var lineChartData5b = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [distr_oil_CH[0], distr_oil_CH[1], distr_oil_CH[2], distr_oil_CH[3], distr_oil_CH[4], distr_oil_CH[5], distr_oil_CH[6], distr_oil_CH[7], distr_oil_CH[8], distr_oil_CH[9], distr_oil_CH[10], distr_oil_CH[11], distr_oil_CH[12], distr_oil_CH[13], distr_oil_CH[14], distr_oil_CH[15], distr_oil_CH[16], distr_oil_CH[17], distr_oil_CH[18], distr_oil_CH[19], distr_oil_CH[20], distr_oil_CH[21], distr_oil_CH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [distr_oil_CM[0], distr_oil_CM[1], distr_oil_CM[2], distr_oil_CM[3], distr_oil_CM[4], distr_oil_CM[5], distr_oil_CM[6], distr_oil_CM[7], distr_oil_CM[8], distr_oil_CM[9], distr_oil_CM[10], distr_oil_CM[11], distr_oil_CM[12], distr_oil_CM[13], distr_oil_CM[14], distr_oil_CM[15], distr_oil_CM[16], distr_oil_CM[17], distr_oil_CM[18], distr_oil_CM[19], distr_oil_CM[20], distr_oil_CM[21], distr_oil_CM[22]]
                }
            ]

        }


        var ctxPerfilesMenu5 = document.getElementById("canvas-perfiles-menu5").getContext("2d");
          window.myLinePerfilesMenu5 = new Chart(ctxPerfilesMenu5).Line(lineChartData5, {
            responsive: false
        });
        $( "#bnt-line-5" ).click(function() {
          var ctxPerfilesMenu5 = document.getElementById("canvas-perfiles-menu5").getContext("2d");
          window.myLinePerfilesMenu5 = new Chart(ctxPerfilesMenu5).Line(lineChartData5, {
            responsive: false
          });
        });
       
       
        $( "#bnt-line-5b" ).click(function() {
          var ctxPerfilesMenu5b = document.getElementById("canvas-perfiles-menu5b").getContext("2d");
          window.myLinePerfilesMenu5b = new Chart(ctxPerfilesMenu5b).Line(lineChartData5b, {
            responsive: false
          });
        });

    var canvas = document.getElementById('canvas-proyeccion-menu5'),
    ctxProyeccionMenu5 = canvas.getContext('2d'),
    startingData = {
            labels : [1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,
            2017,2018,2019,2020,2021,2022,2023,2024,2025,2026,2027,2028,2029,2030],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(206,206,206,0.2)",
                    strokeColor : "rgba(206,206,206,1)",
                    pointColor : "rgba(206,206,206,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(206,206,206,1)",
                    data : [distr_oil_shcp_PROY[0], distr_oil_shcp_PROY[1], distr_oil_shcp_PROY[2], distr_oil_shcp_PROY[3], distr_oil_shcp_PROY[4], distr_oil_shcp_PROY[5],
                    distr_oil_shcp_PROY[6], distr_oil_shcp_PROY[7], distr_oil_shcp_PROY[8], distr_oil_shcp_PROY[9], distr_oil_shcp_PROY[10], distr_oil_shcp_PROY[11], 
                    distr_oil_shcp_PROY[12], distr_oil_shcp_PROY[13], distr_oil_shcp_PROY[14], distr_oil_shcp_PROY[15], distr_oil_shcp_PROY[16], 
                    distr_oil_shcp_PROY[17], distr_oil_shcp_PROY[18], distr_oil_shcp_PROY[19], distr_oil_shcp_PROY[20], 
                    distr_oil_shcp_PROY[21], distr_oil_shcp_PROY[22] ]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(229, 95, 95, 0.2)",
                    strokeColor : "rgba(229, 95, 95, 1)",
                    pointColor : "rgba(229, 95, 95, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(229, 95, 95, 1)",
                    data : [null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,
                    null,null,null,null,distr_oil_PROY[0], distr_oil_PROY[1], distr_oil_PROY[2], distr_oil_PROY[3], 
                    distr_oil_PROY[4], distr_oil_PROY[5], distr_oil_PROY[6], distr_oil_PROY[7], distr_oil_PROY[8], 
                    distr_oil_PROY[9], distr_oil_PROY[10], distr_oil_PROY[11], distr_oil_PROY[12], distr_oil_PROY[13], 
                    distr_oil_PROY[14],distr_oil_PROY[15]]
                }
      ]
    };
    var myChartProyeccionMenu5 = new Chart(ctxProyeccionMenu5).Line(startingData, {animationSteps: 15});



					var ieps2_total_I1 = eval($(html).find("ieps2_total_I1").text()); 
					var ieps2_total_I2 = eval($(html).find("ieps2_total_I2").text()); 
					var ieps2_total_I3 = eval($(html).find("ieps2_total_I3").text()); 
					var ieps2_total_V = eval($(html).find("ieps2_total_V").text()); 
					var ieps2_total_PH = eval($(html).find("ieps2_total_PH").text()); 
					var ieps2_total_CH = eval($(html).find("ieps2_total_CH").text()); 
					var ieps2_total_PM = eval($(html).find("ieps2_total_PM").text()); 
					var ieps2_total_CM = eval($(html).find("ieps2_total_CM").text());  
					var ieps2_total_shcp_PROY = eval($(html).find("ieps2_total_shcp_PROY").text());
					var ieps2_total_PROY = eval($(html).find("ieps2_total_PROY").text());


					for(var i=0;i<ieps2_total_I1.length;i++) { 
						$('#ieps2_total_I1_'+i).html(ieps2_total_I1[i]);
						$('#ieps2_total_I2_'+i).html(ieps2_total_I2[i]);
						$('#ieps2_total_I3_'+i).html(ieps2_total_I3[i]);
					}
					
					for(var i=0;i<ieps2_total_V.length;i++) { 
						$('#ieps2_total_V_'+i).html(ieps2_total_V[i]);
					}




        var lineChartData6 = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [ieps2_total_PH[0], ieps2_total_PH[1], ieps2_total_PH[2], ieps2_total_PH[3], ieps2_total_PH[4], ieps2_total_PH[5], ieps2_total_PH[6], ieps2_total_PH[7], ieps2_total_PH[8], ieps2_total_PH[9], ieps2_total_PH[10], ieps2_total_PH[11], ieps2_total_PH[12], ieps2_total_PH[13], ieps2_total_PH[14], ieps2_total_PH[15], ieps2_total_PH[16], ieps2_total_PH[17], ieps2_total_PH[18], ieps2_total_PH[19], ieps2_total_PH[20], ieps2_total_PH[21], ieps2_total_PH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [ieps2_total_PM[0], ieps2_total_PM[1], ieps2_total_PM[2], ieps2_total_PM[3], ieps2_total_PM[4], ieps2_total_PM[5], ieps2_total_PM[6], ieps2_total_PM[7], ieps2_total_PM[8], ieps2_total_PM[9], ieps2_total_PM[10], ieps2_total_PM[11], ieps2_total_PM[12], ieps2_total_PM[13], ieps2_total_PM[14], ieps2_total_PM[15], ieps2_total_PM[16], ieps2_total_PM[17], ieps2_total_PM[18], ieps2_total_PM[19], ieps2_total_PM[20], ieps2_total_PM[21], ieps2_total_PM[22]]
                }
            ]

        }


        var lineChartData6b = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [ieps2_total_CH[0], ieps2_total_CH[1], ieps2_total_CH[2], ieps2_total_CH[3], ieps2_total_CH[4], ieps2_total_CH[5], ieps2_total_CH[6], ieps2_total_CH[7], ieps2_total_CH[8], ieps2_total_CH[9], ieps2_total_CH[10], ieps2_total_CH[11], ieps2_total_CH[12], ieps2_total_CH[13], ieps2_total_CH[14], ieps2_total_CH[15], ieps2_total_CH[16], ieps2_total_CH[17], ieps2_total_CH[18], ieps2_total_CH[19], ieps2_total_CH[20], ieps2_total_CH[21], ieps2_total_CH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [ieps2_total_CM[0], ieps2_total_CM[1], ieps2_total_CM[2], ieps2_total_CM[3], ieps2_total_CM[4], ieps2_total_CM[5], ieps2_total_CM[6], ieps2_total_CM[7], ieps2_total_CM[8], ieps2_total_CM[9], ieps2_total_CM[10], ieps2_total_CM[11], ieps2_total_CM[12], ieps2_total_CM[13], ieps2_total_CM[14], ieps2_total_CM[15], ieps2_total_CM[16], ieps2_total_CM[17], ieps2_total_CM[18], ieps2_total_CM[19], ieps2_total_CM[20], ieps2_total_CM[21], ieps2_total_CM[22]]
                }
            ]

        }



        var ctxPerfilesMenu6 = document.getElementById("canvas-perfiles-menu6").getContext("2d");
          window.myLinePerfilesMenu6 = new Chart(ctxPerfilesMenu6).Line(lineChartData6, {
            responsive: false
        });
        $( "#bnt-line-6" ).click(function() {
          var ctxPerfilesMenu6 = document.getElementById("canvas-perfiles-menu6").getContext("2d");
          window.myLinePerfilesMenu6 = new Chart(ctxPerfilesMenu6).Line(lineChartData6, {
            responsive: false
          });
        });
       
       
        $( "#bnt-line-6b" ).click(function() {
          var ctxPerfilesMenu6b = document.getElementById("canvas-perfiles-menu6b").getContext("2d");
          window.myLinePerfilesMenu6b = new Chart(ctxPerfilesMenu6b).Line(lineChartData6b, {
            responsive: false
          });
        });

    var canvas = document.getElementById('canvas-proyeccion-menu6'),
    ctxProyeccionMenu6 = canvas.getContext('2d'),
    startingData = {
            labels : [1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,
            2017,2018,2019,2020,2021,2022,2023,2024,2025,2026,2027,2028,2029,2030],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(206,206,206,0.2)",
                    strokeColor : "rgba(206,206,206,1)",
                    pointColor : "rgba(206,206,206,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(206,206,206,1)",
                    data : [ieps2_total_shcp_PROY[0], ieps2_total_shcp_PROY[1], ieps2_total_shcp_PROY[2], ieps2_total_shcp_PROY[3], ieps2_total_shcp_PROY[4], ieps2_total_shcp_PROY[5],
                    ieps2_total_shcp_PROY[6], ieps2_total_shcp_PROY[7], ieps2_total_shcp_PROY[8], ieps2_total_shcp_PROY[9], ieps2_total_shcp_PROY[10], ieps2_total_shcp_PROY[11], 
                    ieps2_total_shcp_PROY[12], ieps2_total_shcp_PROY[13], ieps2_total_shcp_PROY[14], ieps2_total_shcp_PROY[15], ieps2_total_shcp_PROY[16], 
                    ieps2_total_shcp_PROY[17], ieps2_total_shcp_PROY[18], ieps2_total_shcp_PROY[19], ieps2_total_shcp_PROY[20],ieps2_total_shcp_PROY[21],ieps2_total_shcp_PROY[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(229, 95, 95, 0.2)",
                    strokeColor : "rgba(229, 95, 95, 1)",
                    pointColor : "rgba(229, 95, 95, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(229, 95, 95, 1)",
                    data : [ieps2_total_PROY[0], ieps2_total_PROY[1], ieps2_total_PROY[2], ieps2_total_PROY[3], 
                    ieps2_total_PROY[4], ieps2_total_PROY[5], ieps2_total_PROY[6], ieps2_total_PROY[7], ieps2_total_PROY[8], 
                    ieps2_total_PROY[9], ieps2_total_PROY[10], ieps2_total_PROY[11], ieps2_total_PROY[12], ieps2_total_PROY[13], 
                    ieps2_total_PROY[14],ieps2_total_PROY[15], ieps2_total_PROY[16], 
                    ieps2_total_PROY[17], ieps2_total_PROY[18], ieps2_total_PROY[19], ieps2_total_PROY[20], 
                    ieps2_total_PROY[21], ieps2_total_PROY[22], ieps2_total_PROY[23], ieps2_total_PROY[24],
                    ieps2_total_PROY[25], ieps2_total_PROY[26], ieps2_total_PROY[27], ieps2_total_PROY[28],
                    ieps2_total_PROY[29], ieps2_total_PROY[30], ieps2_total_PROY[31], ieps2_total_PROY[32],
                    ieps2_total_PROY[33], ieps2_total_PROY[34], ieps2_total_PROY[35], ieps2_total_PROY[36],
                    ieps2_total_PROY[37]]
                }
      ]
    };
    var myChartProyeccionMenu6 = new Chart(ctxProyeccionMenu6).Line(startingData, {animationSteps: 15});

		

		
		},
		error: function(request,error) {
			console.log(request);
			console.log("Museo: sin motor Stata detrás (" + error + ")");
		}
	});

	
	

		/*****************  envio de iva ************************/	

	$('#ivaSub').click(function(){
			var idSession=makeid(); 
			if(getCookie("idSession")!=null) {
				idSession=getCookie("idSession");
			} 
			setCookie("idSession",idSession,1);

			var ivaA1 = $('#ivaA1').val();
			var ivaA2 = $('#ivaA2').val();
			var ivaA3 = $('#ivaA3').val();
			
			var ivaCanasta =2;
			if($('#ivaCanasta1').is(":checked"))
				ivaCanasta =1;
			if($('#ivaCanasta3').is(":checked"))
				ivaCanasta =3;
		
			var ivaMedicinas =2;
			if($('#ivaMedicinas1').is(":checked"))
				ivaMedicinas =1;
			if($('#ivaMedicinas3').is(":checked"))
				ivaMedicinas =3;
		
			var ivaTransUrbano =2;
			if($('#ivaTransUrbano1').is(":checked"))
				ivaTransUrbano =1;
			if($('#ivaTransUrbano3').is(":checked"))
				ivaTransUrbano =3;
	
			var ivaTransForaneo =2;
			if($('#ivaTransForaneo1').is(":checked"))
				ivaTransForaneo =1;
			if($('#ivaTransForaneo3').is(":checked"))
				ivaTransForaneo =3;
	
			var ivaEduPrib =2;                    
			if($('#ivaEduPrib1').is(":checked"))
				ivaEduPrib =1;
			if($('#ivaEduPrib3').is(":checked"))
				ivaEduPrib =3;
	
			var ivaCRCasa =2;
			if($('#ivaCRCasa1').is(":checked"))
				ivaCRCasa =1;
			if($('#ivaCRCasa3').is(":checked"))
				ivaCRCasa =3;
	
			var ivaAlimentos =2;
			if($('#ivaAlimentos1').is(":checked"))
				ivaAlimentos =1;
			if($('#ivaAlimentos3').is(":checked"))
				ivaAlimentos =3;
	
	
			var ivaAlimentosMascotas =2;
			if($('#ivaAlimentosMascotas1').is(":checked"))
				ivaAlimentosMascotas =1;
			if($('#ivaAlimentosMascotas3').is(":checked"))
				ivaAlimentosMascotas =3;
	
		
			var ivaB1 = $('#ivaB1').val();
			var ivaB2 = $('#ivaB2').val();
			var ivaB3 = $('#ivaB3').val();
			var ivaB4 = $('#ivaB4').val();
			var ivaB5 = $('#ivaB5').val();
			var ivaB6 = $('#ivaB6').val();
			var ivaB7 = $('#ivaB7').val();
			var ivaB8 = $('#ivaB8').val();
	
			setCookie("idSession",idSession,1);
			
			var data = 'ivaA1=' + ivaA1 +'&ivaA2=' + ivaA2 + '&ivaA3=' + ivaA3 + '&ivaCanasta=' +ivaCanasta + '&ivaMedicinas=' +  ivaMedicinas + '&ivaTransUrbano=' +  ivaTransUrbano+ '&ivaTransForaneo=' +  ivaTransForaneo+ '&ivaEduPrib=' +  ivaEduPrib+ '&ivaCRCasa=' +  ivaCRCasa+ '&ivaAlimentos=' +  ivaAlimentos+ '&ivaAlimentosMascotas=' +  ivaAlimentosMascotas+'&ivaB1=' + ivaB1 + '&ivaB2=' + ivaB2 + '&ivaB3=' + ivaB3 + '&ivaB4=' + ivaB4 + '&ivaB5=' + ivaB5 + '&ivaB6=' + ivaB6 + '&ivaB7=' + ivaB7 + '&ivaB8=' + ivaB8 + '&idSession='+idSession ;
//			alert(data);
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

					var iva3_I1 = eval($(html).find("iva2_I1").text()); 
					var iva3_I2 = eval($(html).find("iva2_I2").text()); 
					var iva3_I3 = eval($(html).find("iva2_I3").text()); 
					var iva3_V = eval($(html).find("iva2_V").text()); 

					var iva3_PH = eval($(html).find("iva2_PH").text()); 
					var iva3_CH = eval($(html).find("iva2_CH").text()); 
					var iva3_PM = eval($(html).find("iva2_PM").text()); 
					var iva3_CM = eval($(html).find("iva2_CM").text()); 
 
					var iva3_PROY = eval($(html).find("iva2_PROY").text()); 
					var iva3_shcp_PROY = eval($(html).find("iva2_shcp_PROY").text()); 
 

					cambiosGlobales(html);

					for(var i=0;i<iva3_I1.length;i++) { 
						$('#iva3_I1_'+i).html(iva3_I1[i]);
						$('#iva3_I2_'+i).html(iva3_I2[i]);
						$('#iva3_I3_'+i).html(iva3_I3[i]);
					}
					
					for(var i=0;i<iva3_I1.length;i++) { 
						$('#iva3_V_'+i).html(iva3_V[i]);
					}




        var lineChartData1 = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [iva3_PH[0], iva3_PH[1], iva3_PH[2], iva3_PH[3], iva3_PH[4], iva3_PH[5], iva3_PH[6], iva3_PH[7], iva3_PH[8], iva3_PH[9], iva3_PH[10], iva3_PH[11], iva3_PH[12], iva3_PH[13], iva3_PH[14], iva3_PH[15], iva3_PH[16], iva3_PH[17], iva3_PH[18], iva3_PH[19], iva3_PH[20], iva3_PH[21], iva3_PH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [iva3_PM[0], iva3_PM[1], iva3_PM[2], iva3_PM[3], iva3_PM[4], iva3_PM[5], iva3_PM[6], iva3_PM[7], iva3_PM[8], iva3_PM[9], iva3_PM[10], iva3_PM[11], iva3_PM[12], iva3_PM[13], iva3_PM[14], iva3_PM[15], iva3_PM[16], iva3_PM[17], iva3_PM[18], iva3_PM[19], iva3_PM[20], iva3_PM[21], iva3_PM[22]]
                }
            ]

        }

        var lineChartData1b = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [iva3_CH[0], iva3_CH[1], iva3_CH[2], iva3_CH[3], iva3_CH[4], iva3_CH[5], iva3_CH[6], iva3_CH[7], iva3_CH[8], iva3_CH[9], iva3_CH[10], iva3_CH[11], iva3_CH[12], iva3_CH[13], iva3_CH[14], iva3_CH[15], iva3_CH[16], iva3_CH[17], iva3_CH[18], iva3_CH[19], iva3_CH[20], iva3_CH[21], iva3_CH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [iva3_CM[0], iva3_CM[1], iva3_CM[2], iva3_CM[3], iva3_CM[4], iva3_CM[5], iva3_CM[6], iva3_CM[7], iva3_CM[8], iva3_CM[9], iva3_CM[10], iva3_CM[11], iva3_CM[12], iva3_CM[13], iva3_CM[14], iva3_CM[15], iva3_CM[16], iva3_CM[17], iva3_CM[18], iva3_CM[19], iva3_CM[20], iva3_CM[21], iva3_CM[22]]
                }
            ]

        }

/*        var canvCls = document.getElementById("canvas-perfiles-menu1").getContext("2d");
        canvCls.clearRect(0, 0, canvCls.width, canvCls.height);
        canvCls = document.getElementById("canvas-perfiles-menu1b").getContext("2d");
        canvCls.clearRect(0, 0, canvCls.width, canvCls.height);


        var tbCls = document.getElementById("canvas-perfiles-menu1").parentNode;
        var canvCls = document.getElementById("canvas-perfiles-menu1");
        canvCls.remove();

			$('<canvas>').attr({
		    		id: 'canvas-perfiles-menu1'
				}).css({
			    width: '708px',
			    height: '345px'
			}).appendTo(tbCls);
*/			
        var ctxPerfilesMenu1 = document.getElementById("canvas-perfiles-menu1").getContext("2d");
//          ctxPerfilesMenu1.clear;
          ctxPerfilesMenu1.clearRect(0, 0, ctxPerfilesMenu1.width, ctxPerfilesMenu1.height);
          window.myLinePerfilesMenu1 = new Chart(ctxPerfilesMenu1).Line(lineChartData1, {
            responsive: false
        });
        $( "#bnt-line-1" ).click(function() {
          var ctxPerfilesMenu1 = document.getElementById("canvas-perfiles-menu1").getContext("2d");
          ctxPerfilesMenu1.clearRect(0, 0, ctxPerfilesMenu1.width, ctxPerfilesMenu1.height);
          window.myLinePerfilesMenu1 = new Chart(ctxPerfilesMenu1).Line(lineChartData1, {
            responsive: false
          });
        });
       
       
        $( "#bnt-line-1b" ).click(function() {
          var ctxPerfilesMenu1b = document.getElementById("canvas-perfiles-menu1b").getContext("2d");
          window.myLinePerfilesMenu1b = new Chart(ctxPerfilesMenu1b).Line(lineChartData1b, {
            responsive: false
          });
        });


    var canvas = document.getElementById('canvas-proyeccion-menu1'),
    ctxProyeccionMenu1 = canvas.getContext('2d'),
    startingData = {
            labels : [1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,
            2017,2018,2019,2020,2021,2022,2023,2024,2025,2026,2027,2028,2029,2030],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "SHCP",
                    fillColor : "rgba(206,206,206,0.2)",
                    strokeColor : "rgba(206,206,206,1)",
                    pointColor : "rgba(206,206,206,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(206,206,206,1)",
                    data : [iva3_shcp_PROY[0], iva3_shcp_PROY[1], iva3_shcp_PROY[2], iva3_shcp_PROY[3], iva3_shcp_PROY[4], iva3_shcp_PROY[5],
                    iva3_shcp_PROY[6], iva3_shcp_PROY[7], iva3_shcp_PROY[8], iva3_shcp_PROY[9], iva3_shcp_PROY[10], iva3_shcp_PROY[11], 
                    iva3_shcp_PROY[12], iva3_shcp_PROY[13], iva3_shcp_PROY[14], iva3_shcp_PROY[15], iva3_shcp_PROY[16], iva3_shcp_PROY[17], 
                    iva3_shcp_PROY[18], iva3_shcp_PROY[19], iva3_shcp_PROY[20], iva3_shcp_PROY[21] , iva3_shcp_PROY[22] ]
                },
                {
                    label: "Proyeccion",
                    fillColor : "rgba(229, 95, 95, 0.2)",
                    strokeColor : "rgba(229, 95, 95, 1)",
                    pointColor : "rgba(229, 95, 95, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(229, 95, 95, 1)",
                    data : [iva3_PROY[0], iva3_PROY[1], iva3_PROY[2], iva3_PROY[3], iva3_PROY[4], iva3_PROY[5], iva3_PROY[6], iva3_PROY[7], 
                    iva3_PROY[8], iva3_PROY[9], iva3_PROY[10], iva3_PROY[11], iva3_PROY[12], iva3_PROY[13], iva3_PROY[14], iva3_PROY[15], 
                    iva3_PROY[16], iva3_PROY[17], iva3_PROY[18], iva3_PROY[19], iva3_PROY[20], iva3_PROY[21], iva3_PROY[22], iva3_PROY[23],
                    iva3_PROY[24], iva3_PROY[25], iva3_PROY[26], iva3_PROY[27], iva3_PROY[28], iva3_PROY[29], iva3_PROY[30],
                    iva3_PROY[31], iva3_PROY[32], iva3_PROY[33], iva3_PROY[34], iva3_PROY[35], iva3_PROY[36], iva3_PROY[37] ]
                }
      ]
    };
    var myChartProyeccionMenu1 = new Chart(ctxProyeccionMenu1).Line(startingData, {animationSteps: 15});

		
				},
				beforeSend: function () {
					$( "#cargando" ).show();
					alert ( "La ejecución puede demorar hasta un minuto");
				},		
				error: function(request,error) {
					console.log(request);
					console.log("Museo: sin motor Stata detrás (" + error + ")");
				},
				complete:function () {
					$( "#cargando" ).hide();
				}

			});
		
		//cancel the submit button default behaviours

		});


	/*****************  envio de isr ************************/	
	$('#isrSub').click(function(){
		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);

		//Simple validation to make sure user entered something
		//If error found, add hightlight class to the text field

//		alert("que hay");
		var ISR1x4 = $('#ISR1x4').val();
		var ISR2x4 = $('#ISR2x4').val();
		var ISR3x4 = $('#ISR3x4').val();
		var ISR4x4 = $('#ISR4x4').val();
		var ISR5x4 = $('#ISR5x4').val();
		var ISR6x4 = $('#ISR6x4').val();
		var ISR7x4 = $('#ISR7x4').val();
		var ISR8x4 = $('#ISR8x4').val();
		var ISR9x4 = $('#ISR9x4').val();
		var ISR10x4 = $('#ISR10x4').val();
		var ISR11x4 = $('#ISR11x4').val();

		var ISRB1x3 = $('#ISRB1x3').val();
		var ISRB2x3 = $('#ISRB2x3').val();
		var ISRB3x3 = $('#ISRB3x3').val();
		var ISRB4x3 = $('#ISRB4x3').val();
		var ISRB5x3 = $('#ISRB5x3').val();
		var ISRB6x3 = $('#ISRB6x3').val();
		var ISRB7x3 = $('#ISRB7x3').val();
		var ISRB8x3 = $('#ISRB8x3').val();
		var ISRB9x3 = $('#ISRB9x3').val();
		var ISRB10x3 = $('#ISRB10x3').val();
		var ISRB11x3 = $('#ISRB11x3').val();
		var ISRB12x3 = $('#ISRB12x3').val();
		
		var ISRE1x2 = $('#ISRE1x2').val();
		var ISRE2x2 = $('#ISRE2x2').val();
		var ISRE3x2 = $('#ISRE3x2').val();
		var ISRE4x2 = $('#ISRE4x2').val();
		var ISRE5x2 = $('#ISRE5x2').val();
		var ISRE6x2 = $('#ISRE6x2').val();
		var ISRE7x2 = $('#ISRE7x2').val();
		var ISRE8x2 = $('#ISRE8x2').val();


		//organize the data properly /// arreglar lo de existencia de cookie no genere una nueva
//		var idSession="sdfa21"; 

		var data = 'ISR1x4=' + ISR1x4 + '&ISR2x4=' + ISR2x4 + '& x4=' + ISR3x4 + '&ISR4x4=' + ISR4x4 + '&ISR5x4=' + ISR5x4 + 
		'&ISR6x4=' + ISR6x4 + '&ISR7x4=' + ISR7x4 + '&ISR8x4=' + ISR8x4 + '&ISR9x4=' + ISR9x4 + '&ISR10x4=' + ISR10x4 + 
		'&ISR11x4=' + ISR11x4 + '&ISRB1x3=' + ISRB1x3 + '&ISRB2x3=' + ISRB2x3 + '&ISRB3x3=' + ISRB3x3 + '&ISRB4x3=' + ISRB4x3 + 
		'&ISRB5x3=' + ISRB5x3 + '&ISRB6x3=' + ISRB6x3 + '&ISRB7x3=' + ISRB7x3 + '&ISRB8x3=' + ISRB8x3 + '&ISRB9x3=' + ISRB9x3 + 
		'&ISRB10x3=' +	ISRB10x3 + '&ISRB11x3=' + ISRB11x3 + '&ISRB12x3=' + ISRB12x3 + '&ISRE1x2=' + ISRE1x2 + '&ISRE2x2=' + ISRE2x2 + 
		'&ISRE3x2=' + ISRE3x2 + '&ISRE4x2=' + ISRE4x2 + '&ISRE5x2=' + ISRE5x2 + '&ISRE6x2=' + ISRE6x2 + '&ISRE7x2=' + ISRE7x2 + 
		'&ISRE8x2=' + ISRE8x2 +'&idSession='+idSession ;
//	alert(data);						

		//start the ajax
			$.ajax({
				//this is the php file that processes the data and send mail
				url: "isrStata.php",	
				
				async:false,
	
				//GET method is used
				type: "GET",
	
				//pass the data			
				data: data,		
				
				//Do not cache the page
				cache: false,
				
				//success
				success: function (html) {	

					var isr3_I1 = eval($(html).find("isr3_I1").text()); 
					var isr3_I2 = eval($(html).find("isr3_I2").text()); 
					var isr3_I3 = eval($(html).find("isr3_I3").text()); 
					var isr3_V = eval($(html).find("isr3_V").text()); 

					cambiosGlobales(html);

					var isr3_PH = eval($(html).find("isr3_PH").text()); 
					var isr3_CH = eval($(html).find("isr3_CH").text()); 
					var isr3_PM = eval($(html).find("isr3_PM").text()); 
					var isr3_CM = eval($(html).find("isr3_CM").text()); 
 
					var isr3_PROY = eval($(html).find("isr3_PROY").text()); 
					var isr3_shcp_PROY = eval($(html).find("isr3_shcp_PROY").text()); 


					for(var i=0;i<isr3_I1.length;i++) { 
						$('#isr3_I1_'+i).html(isr3_I1[i]);
						$('#isr3_I2_'+i).html(isr3_I2[i]);
						$('#isr3_I3_'+i).html(isr3_I3[i]);
					}
					
					for(var i=0;i<isr3_V.length;i++) { 
						$('#isr3_V_'+i).html(isr3_V[i]);
					}




        var lineChartData2 = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [isr3_PH[0], isr3_PH[1], isr3_PH[2], isr3_PH[3], isr3_PH[4], isr3_PH[5], isr3_PH[6], isr3_PH[7], isr3_PH[8], isr3_PH[9], isr3_PH[10], isr3_PH[11], isr3_PH[12], isr3_PH[13], isr3_PH[14], isr3_PH[15], isr3_PH[16], isr3_PH[17], isr3_PH[18], isr3_PH[19], isr3_PH[20], isr3_PH[21], isr3_PH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [isr3_PM[0], isr3_PM[1], isr3_PM[2], isr3_PM[3], isr3_PM[4], isr3_PM[5], isr3_PM[6], isr3_PM[7], isr3_PM[8], isr3_PM[9], isr3_PM[10], isr3_PM[11], isr3_PM[12], isr3_PM[13], isr3_PM[14], isr3_PM[15], isr3_PM[16], isr3_PM[17], isr3_PM[18], isr3_PM[19], isr3_PM[20], isr3_PM[21], isr3_PM[22]]
                }
            ]

        }


        var lineChartData2b = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [isr3_CH[0], isr3_CH[1], isr3_CH[2], isr3_CH[3], isr3_CH[4], isr3_CH[5], isr3_CH[6], isr3_CH[7], isr3_CH[8], isr3_CH[9], isr3_CH[10], isr3_CH[11], isr3_CH[12], isr3_CH[13], isr3_CH[14], isr3_CH[15], isr3_CH[16], isr3_CH[17], isr3_CH[18], isr3_CH[19], isr3_CH[20], isr3_CH[21], isr3_CH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [isr3_CM[0], isr3_CM[1], isr3_CM[2], isr3_CM[3], isr3_CM[4], isr3_CM[5], isr3_CM[6], isr3_CM[7], isr3_CM[8], isr3_CM[9], isr3_CM[10], isr3_CM[11], isr3_CM[12], isr3_CM[13], isr3_CM[14], isr3_CM[15], isr3_CM[16], isr3_CM[17], isr3_CM[18], isr3_CM[19], isr3_CM[20], isr3_CM[21], isr3_CM[22]]
                }
            ]

        }

        var canvCls = document.getElementById("canvas-perfiles-menu2").getContext("2d");
        canvCls.clearRect(0, 0, canvCls.width, canvCls.height);
        canvCls = document.getElementById("canvas-perfiles-menu2b").getContext("2d");
        canvCls.clearRect(0, 0, canvCls.width, canvCls.height);

        var ctxPerfilesMenu2 = document.getElementById("canvas-perfiles-menu2").getContext("2d");
          window.myLinePerfilesMenu2 = new Chart(ctxPerfilesMenu2).Line(lineChartData2, {
            responsive: false
        });
        $( "#bnt-line-2" ).click(function() {
          var ctxPerfilesMenu2 = document.getElementById("canvas-perfiles-menu2").getContext("2d");
          window.myLinePerfilesMenu2 = new Chart(ctxPerfilesMenu2).Line(lineChartData2, {
            responsive: false
          });
        });
       
       
        $( "#bnt-line-2b" ).click(function() {
          var ctxPerfilesMenu2b = document.getElementById("canvas-perfiles-menu2b").getContext("2d");
          window.myLinePerfilesMenu2b = new Chart(ctxPerfilesMenu2b).Line(lineChartData2b, {
            responsive: false
          });
        });

    var canvas = document.getElementById('canvas-proyeccion-menu2'),
    ctxProyeccionMenu2 = canvas.getContext('2d'),
    startingData = {
            labels : [1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,
            2017,2018,2019,2020,2021,2022,2023,2024,2025,2026,2027,2028,2029,2030],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(206,206,206,0.2)",
                    strokeColor : "rgba(206,206,206,1)",
                    pointColor : "rgba(206,206,206,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(206,206,206,1)",
                    data : [null,null,null,null,null,null,null,null,null,isr3_shcp_PROY[0], isr3_shcp_PROY[1], isr3_shcp_PROY[2], isr3_shcp_PROY[3], isr3_shcp_PROY[4], isr3_shcp_PROY[5],
                    isr3_shcp_PROY[6], isr3_shcp_PROY[7], isr3_shcp_PROY[8], isr3_shcp_PROY[9], isr3_shcp_PROY[10], isr3_shcp_PROY[11], 
                    isr3_shcp_PROY[12], isr3_shcp_PROY[13]  ]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(229, 95, 95, 0.2)",
                    strokeColor : "rgba(229, 95, 95, 1)",
                    pointColor : "rgba(229, 95, 95, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(229, 95, 95, 1)",
                    data : [isr3_PROY[0], isr3_PROY[1], isr3_PROY[2], isr3_PROY[3], isr3_PROY[4], isr3_PROY[5], isr3_PROY[6], isr3_PROY[7], 
                    isr3_PROY[8], isr3_PROY[9], isr3_PROY[10], isr3_PROY[11], isr3_PROY[12], isr3_PROY[13], isr3_PROY[14], isr3_PROY[15], 
                    isr3_PROY[16], isr3_PROY[17], isr3_PROY[18], isr3_PROY[19], isr3_PROY[20], isr3_PROY[21], isr3_PROY[22], isr3_PROY[23],
                    isr3_PROY[24], isr3_PROY[25], isr3_PROY[26], isr3_PROY[27], isr3_PROY[28], isr3_PROY[29], isr3_PROY[30],
                    isr3_PROY[31], isr3_PROY[32], isr3_PROY[33], isr3_PROY[34], isr3_PROY[35], isr3_PROY[36], isr3_PROY[37] ]
                }
      ]
    };
    var myChartProyeccionMenu2 = new Chart(ctxProyeccionMenu2).Line(startingData, {animationSteps: 15});



		
				},
				beforeSend: function () {
					$( "#cargando" ).show();
					alert ( "La ejecución puede demorar hasta un minuto");
				},		
				error: function(request,error) {
					console.log(request);
					console.log("Museo: sin motor Stata detrás (" + error + ")");
				},
				complete:function () {
					$( "#cargando" ).hide();
				}

			});
		
		//cancel the submit button default behaviours

		});


	/*****************  envio de imss ******************/	
	$('#imssSub').click(function(){
		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);

		//Simple validation to make sure user entered something
		//If error found, add hightlight class to the text field

		var seguridadSocialImssIn1 = $('#seguridadSocialIn1').val();
		var seguridadSocialImssIn2 = $('#seguridadSocialIn2').val();
		var seguridadSocialImssIn3 = $('#seguridadSocialIn3').val();
		var seguridadSocialImssIn4 = $('#seguridadSocialIn4').val();
		var seguridadSocialImssIn5 = $('#seguridadSocialIn5').val();
		var seguridadSocialImssIn6 = $('#seguridadSocialIn6').val();
		var seguridadSocialImssIn7 = $('#seguridadSocialIn7').val();
		var seguridadSocialImssIn8 = $('#seguridadSocialIn8').val();
		var seguridadSocialImssIn9 = $('#seguridadSocialIn9').val();
		var seguridadSocialImssIn10 = $('#seguridadSocialIn10').val();
		var seguridadSocialImssIn11 = $('#seguridadSocialIn11').val();
		var seguridadSocialImssIn12 = $('#seguridadSocialIn12').val();
		var seguridadSocialImssIn13 = $('#seguridadSocialIn13').val();
		var seguridadSocialImssIn14 = $('#seguridadSocialIn14').val();
		var seguridadSocialImssIn15 = $('#seguridadSocialIn15').val();
		var seguridadSocialImssIn16 = $('#seguridadSocialIn16').val();
		var seguridadSocialImssIn17 = $('#seguridadSocialIn17').val();
		var seguridadSocialImssIn18 = $('#seguridadSocialIn18').val();
		var seguridadSocialImssIn19 = $('#seguridadSocialIn19').val();
		var seguridadSocialImssIn20 = $('#seguridadSocialIn20').val();


		//organize the data properly /// arreglar lo de existencia de cookie no genere una nueva
		var data = 'seguridadSocialImssIn1=' + seguridadSocialImssIn1  + '&seguridadSocialImssIn2=' + seguridadSocialImssIn2 + 
		'&seguridadSocialImssIn3=' + seguridadSocialImssIn3  + '&seguridadSocialImssIn4=' + seguridadSocialImssIn4  + 
		'&seguridadSocialImssIn5=' + seguridadSocialImssIn5  + '&seguridadSocialImssIn6=' + seguridadSocialImssIn6  + 
		'&seguridadSocialImssIn7=' + seguridadSocialImssIn7  + '&seguridadSocialImssIn8=' + seguridadSocialImssIn8  + 
		'&seguridadSocialImssIn9=' + seguridadSocialImssIn9  + '&seguridadSocialImssIn10=' + seguridadSocialImssIn10  + 
		'&seguridadSocialImssIn11=' + seguridadSocialImssIn11  + '&seguridadSocialImssIn12=' + seguridadSocialImssIn12  + 
		'&seguridadSocialImssIn13=' + seguridadSocialImssIn13  + '&seguridadSocialImssIn14=' + seguridadSocialImssIn14  + 
		'&seguridadSocialImssIn15=' + seguridadSocialImssIn15  + '&seguridadSocialImssIn16=' + seguridadSocialImssIn16  + 
		'&seguridadSocialImssIn17=' + seguridadSocialImssIn17  + '&seguridadSocialImssIn18=' + seguridadSocialImssIn18  + 
		'&seguridadSocialImssIn19=' + seguridadSocialImssIn19  + '&seguridadSocialImssIn20=' + seguridadSocialImssIn20  + 
		'&idSession='+idSession ;


		//start the ajax
			$.ajax({
				//this is the php file that processes the data and send mail
				url: "imssStata.php",	
				
				async:false,
	
				//GET method is used
				type: "GET",
	
				//pass the data			
				data: data,		
				
				//Do not cache the page
				cache: false,
				
				//success
				success: function (html) {	

					var salud_imss_issste_I1 = eval($(html).find("cuotasT2_I1").text()); 
					var salud_imss_issste_I2 = eval($(html).find("cuotasT2_I2").text()); 
					var salud_imss_issste_I3 = eval($(html).find("cuotasT2_I3").text()); 
					var salud_imss_issste_V = eval($(html).find("cuotasT2_V").text()); 

					cambiosGlobales(html);

					var salud_imss_issste_PH = eval($(html).find("cuotasT2_PH").text()); 
					var salud_imss_issste_CH = eval($(html).find("cuotasT2_CH").text()); 
					var salud_imss_issste_PM = eval($(html).find("cuotasT2_PM").text()); 
					var salud_imss_issste_CM = eval($(html).find("cuotasT2_CM").text()); 
 
					var salud_imss_issste_PROY = eval($(html).find("cuotasT2_PROY").text()); 
					var salud_imss_issste_shcp_PROY = eval($(html).find("cuotasT2_shcp_PROY").text()); 


					for(var i=0;i<salud_imss_issste_I1.length;i++) { 
						$('#salud_imss_issste_I1_'+i).html(salud_imss_issste_I1[i]);
						$('#salud_imss_issste_I2_'+i).html(salud_imss_issste_I2[i]);
						$('#salud_imss_issste_I3_'+i).html(salud_imss_issste_I3[i]);
					}
					
					for(var i=0;i<salud_imss_issste_V.length;i++) { 
						$('#salud_imss_issste_V_'+i).html(salud_imss_issste_V[i]);
					}




        var lineChartData4 = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [salud_imss_issste_PH[0], salud_imss_issste_PH[1], salud_imss_issste_PH[2], salud_imss_issste_PH[3], salud_imss_issste_PH[4], salud_imss_issste_PH[5], salud_imss_issste_PH[6], salud_imss_issste_PH[7], salud_imss_issste_PH[8], salud_imss_issste_PH[9], salud_imss_issste_PH[10], salud_imss_issste_PH[11], salud_imss_issste_PH[12], salud_imss_issste_PH[13], salud_imss_issste_PH[14], salud_imss_issste_PH[15], salud_imss_issste_PH[16], salud_imss_issste_PH[17], salud_imss_issste_PH[18], salud_imss_issste_PH[19], salud_imss_issste_PH[20], salud_imss_issste_PH[21], salud_imss_issste_PH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [salud_imss_issste_PM[0], salud_imss_issste_PM[1], salud_imss_issste_PM[2], salud_imss_issste_PM[3], salud_imss_issste_PM[4], salud_imss_issste_PM[5], salud_imss_issste_PM[6], salud_imss_issste_PM[7], salud_imss_issste_PM[8], salud_imss_issste_PM[9], salud_imss_issste_PM[10], salud_imss_issste_PM[11], salud_imss_issste_PM[12], salud_imss_issste_PM[13], salud_imss_issste_PM[14], salud_imss_issste_PM[15], salud_imss_issste_PM[16], salud_imss_issste_PM[17], salud_imss_issste_PM[18], salud_imss_issste_PM[19], salud_imss_issste_PM[20], salud_imss_issste_PM[21], salud_imss_issste_PM[22]]
                }
            ]

        }


        var lineChartData4b = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [salud_imss_issste_CH[0], salud_imss_issste_CH[1], salud_imss_issste_CH[2], salud_imss_issste_CH[3], salud_imss_issste_CH[4], salud_imss_issste_CH[5], salud_imss_issste_CH[6], salud_imss_issste_CH[7], salud_imss_issste_CH[8], salud_imss_issste_CH[9], salud_imss_issste_CH[10], salud_imss_issste_CH[11], salud_imss_issste_CH[12], salud_imss_issste_CH[13], salud_imss_issste_CH[14], salud_imss_issste_CH[15], salud_imss_issste_CH[16], salud_imss_issste_CH[17], salud_imss_issste_CH[18], salud_imss_issste_CH[19], salud_imss_issste_CH[20], salud_imss_issste_CH[21], salud_imss_issste_CH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [salud_imss_issste_CM[0], salud_imss_issste_CM[1], salud_imss_issste_CM[2], salud_imss_issste_CM[3], salud_imss_issste_CM[4], salud_imss_issste_CM[5], salud_imss_issste_CM[6], salud_imss_issste_CM[7], salud_imss_issste_CM[8], salud_imss_issste_CM[9], salud_imss_issste_CM[10], salud_imss_issste_CM[11], salud_imss_issste_CM[12], salud_imss_issste_CM[13], salud_imss_issste_CM[14], salud_imss_issste_CM[15], salud_imss_issste_CM[16], salud_imss_issste_CM[17], salud_imss_issste_CM[18], salud_imss_issste_CM[19], salud_imss_issste_CM[20], salud_imss_issste_CM[21], salud_imss_issste_CM[22]]
                }
            ]

        }

        var canvCls = document.getElementById("canvas-perfiles-menu4").getContext("2d");
        canvCls.clearRect(0, 0, canvCls.width, canvCls.height);
        canvCls = document.getElementById("canvas-perfiles-menu4b").getContext("2d");
        canvCls.clearRect(0, 0, canvCls.width, canvCls.height);

        var ctxPerfilesMenu4 = document.getElementById("canvas-perfiles-menu4").getContext("2d");
          window.myLinePerfilesMenu4 = new Chart(ctxPerfilesMenu4).Line(lineChartData4, {
            responsive: false
        });
        $( "#bnt-line-4" ).click(function() {
          var ctxPerfilesMenu4 = document.getElementById("canvas-perfiles-menu4").getContext("2d");
          ctxPerfilesMenu4.clearRect(0, 0, ctxPerfilesMenu4.width, ctxPerfilesMenu4.height);
          window.myLinePerfilesMenu4 = new Chart(ctxPerfilesMenu4).Line(lineChartData4, {
            responsive: false
          });
        });
       
       
        $( "#bnt-line-4b" ).click(function() {
          var ctxPerfilesMenu4b = document.getElementById("canvas-perfiles-menu4b").getContext("2d");
          ctxPerfilesMenu4b.clearRect(0, 0, ctxPerfilesMenu4b.width, ctxPerfilesMenu4b.height);
          window.myLinePerfilesMenu4b = new Chart(ctxPerfilesMenu4b).Line(lineChartData4b, {
            responsive: false
          });
        });

    var canvas = document.getElementById('canvas-proyeccion-menu4'),
    ctxProyeccionMenu4 = canvas.getContext('2d'),
    startingData = {
            labels : [1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,
            2017,2018,2019,2020,2021,2022,2023,2024,2025,2026,2027,2028,2029,2030],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(206,206,206,0.2)",
                    strokeColor : "rgba(206,206,206,1)",
                    pointColor : "rgba(206,206,206,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(206,206,206,1)",
                    data : [null,null,null,null,null,null,null,null,null,null,null,null,null,null,salud_imss_issste_shcp_PROY[0], salud_imss_issste_shcp_PROY[1], salud_imss_issste_shcp_PROY[2], salud_imss_issste_shcp_PROY[3], salud_imss_issste_shcp_PROY[4], salud_imss_issste_shcp_PROY[5],
                    salud_imss_issste_shcp_PROY[6], salud_imss_issste_shcp_PROY[7], salud_imss_issste_shcp_PROY[8] ]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(229, 95, 95, 0.2)",
                    strokeColor : "rgba(229, 95, 95, 1)",
                    pointColor : "rgba(229, 95, 95, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(229, 95, 95, 1)",
                    data : [salud_imss_issste_PROY[0], salud_imss_issste_PROY[1], salud_imss_issste_PROY[2], salud_imss_issste_PROY[3], salud_imss_issste_PROY[4], salud_imss_issste_PROY[5], salud_imss_issste_PROY[6], salud_imss_issste_PROY[7], 
                    salud_imss_issste_PROY[8], salud_imss_issste_PROY[9], salud_imss_issste_PROY[10], salud_imss_issste_PROY[11], salud_imss_issste_PROY[12], salud_imss_issste_PROY[13], salud_imss_issste_PROY[14], salud_imss_issste_PROY[15], 
                    salud_imss_issste_PROY[16], salud_imss_issste_PROY[17], salud_imss_issste_PROY[18], salud_imss_issste_PROY[19], salud_imss_issste_PROY[20], salud_imss_issste_PROY[21], salud_imss_issste_PROY[22], salud_imss_issste_PROY[23],
                    salud_imss_issste_PROY[24], salud_imss_issste_PROY[25], salud_imss_issste_PROY[26], salud_imss_issste_PROY[27], salud_imss_issste_PROY[28], salud_imss_issste_PROY[29], salud_imss_issste_PROY[30],
                    salud_imss_issste_PROY[31], salud_imss_issste_PROY[32], salud_imss_issste_PROY[33], salud_imss_issste_PROY[34], salud_imss_issste_PROY[35], salud_imss_issste_PROY[36], salud_imss_issste_PROY[37] ]
                }
      ]
    };
    var myChartProyeccionMenu4 = new Chart(ctxProyeccionMenu4).Line(startingData, {animationSteps: 15});



		
				},
				beforeSend: function () {
					$( "#cargando" ).show();
					alert ( "La ejecución puede demorar hasta un minuto");
				},		
				error: function(request,error) {
					console.log(request);
					console.log("Museo: sin motor Stata detrás (" + error + ")");
				},
				complete:function () {
					$( "#cargando" ).hide();
				}

			});
		
		//cancel the submit button default behaviours

		});




	/*****************  envio de isr personas morales ******************/	
	$('#isrMoralesSub').click(function(){
		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);

		//Simple validation to make sure user entered something
		//If error found, add hightlight class to the text field

		var isrMoralesA1 = $('#isrMoralesA1').val();


		//organize the data properly /// arreglar lo de existencia de cookie no genere una nueva

		var data = 'isrMoralesA1=' + isrMoralesA1  +'&idSession='+idSession ;

		//start the ajax
			$.ajax({
				//this is the php file that processes the data and send mail
				url: "isrPmoralesStata.php",	
				
				async:false,
	
				//GET method is used
				type: "GET",
	
				//pass the data			
				data: data,		
				
				//Do not cache the page
				cache: false,
				
				//success
				success: function (html) {	

					var isr_pm_I1 = eval($(html).find("isr_pm_I1").text()); 
					var isr_pm_I2 = eval($(html).find("isr_pm_I2").text()); 
					var isr_pm_I3 = eval($(html).find("isr_pm_I3").text()); 
					var isr_pm_V = eval($(html).find("isr_pm_V").text()); 

					cambiosGlobales(html);

					var isr_pm_PH = eval($(html).find("isr_pm_PH").text()); 
					var isr_pm_CH = eval($(html).find("isr_pm_CH").text()); 
					var isr_pm_PM = eval($(html).find("isr_pm_PM").text()); 
					var isr_pm_CM = eval($(html).find("isr_pm_CM").text()); 
 
					var isr_pm_PROY = eval($(html).find("isr_pm_PROY").text()); 
					var isr_pm_shcp_PROY = eval($(html).find("isr_pm_shcp_PROY").text()); 


					for(var i=0;i<isr_pm_I1.length;i++) { 
						$('#isr_pm_I1_'+i).html(isr_pm_I1[i]);
						$('#isr_pm_I2_'+i).html(isr_pm_I2[i]);
						$('#isr_pm_I3_'+i).html(isr_pm_I3[i]);
					}
					
					for(var i=0;i<isr_pm_V.length;i++) { 
						$('#isr_pm_V_'+i).html(isr_pm_V[i]);
					}




        var lineChartData3 = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [isr_pm_PH[0], isr_pm_PH[1], isr_pm_PH[2], isr_pm_PH[3], isr_pm_PH[4], isr_pm_PH[5], isr_pm_PH[6], isr_pm_PH[7], isr_pm_PH[8], isr_pm_PH[9], isr_pm_PH[10], isr_pm_PH[11], isr_pm_PH[12], isr_pm_PH[13], isr_pm_PH[14], isr_pm_PH[15], isr_pm_PH[16], isr_pm_PH[17], isr_pm_PH[18], isr_pm_PH[19], isr_pm_PH[20], isr_pm_PH[21], isr_pm_PH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [isr_pm_PM[0], isr_pm_PM[1], isr_pm_PM[2], isr_pm_PM[3], isr_pm_PM[4], isr_pm_PM[5], isr_pm_PM[6], isr_pm_PM[7], isr_pm_PM[8], isr_pm_PM[9], isr_pm_PM[10], isr_pm_PM[11], isr_pm_PM[12], isr_pm_PM[13], isr_pm_PM[14], isr_pm_PM[15], isr_pm_PM[16], isr_pm_PM[17], isr_pm_PM[18], isr_pm_PM[19], isr_pm_PM[20], isr_pm_PM[21], isr_pm_PM[22]]
                }
            ]

        }


        var lineChartData3b = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [isr_pm_CH[0], isr_pm_CH[1], isr_pm_CH[2], isr_pm_CH[3], isr_pm_CH[4], isr_pm_CH[5], isr_pm_CH[6], isr_pm_CH[7], isr_pm_CH[8], isr_pm_CH[9], isr_pm_CH[10], isr_pm_CH[11], isr_pm_CH[12], isr_pm_CH[13], isr_pm_CH[14], isr_pm_CH[15], isr_pm_CH[16], isr_pm_CH[17], isr_pm_CH[18], isr_pm_CH[19], isr_pm_CH[20], isr_pm_CH[21], isr_pm_CH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [isr_pm_CM[0], isr_pm_CM[1], isr_pm_CM[2], isr_pm_CM[3], isr_pm_CM[4], isr_pm_CM[5], isr_pm_CM[6], isr_pm_CM[7], isr_pm_CM[8], isr_pm_CM[9], isr_pm_CM[10], isr_pm_CM[11], isr_pm_CM[12], isr_pm_CM[13], isr_pm_CM[14], isr_pm_CM[15], isr_pm_CM[16], isr_pm_CM[17], isr_pm_CM[18], isr_pm_CM[19], isr_pm_CM[20], isr_pm_CM[21], isr_pm_CM[22]]
                }
            ]

        }

        var canvCls = document.getElementById("canvas-perfiles-menu3").getContext("2d");
        canvCls.clearRect(0, 0, canvCls.width, canvCls.height);
        canvCls = document.getElementById("canvas-perfiles-menu3b").getContext("2d");
        canvCls.clearRect(0, 0, canvCls.width, canvCls.height);

        var ctxPerfilesMenu3 = document.getElementById("canvas-perfiles-menu3").getContext("2d");
          window.myLinePerfilesMenu3 = new Chart(ctxPerfilesMenu3).Line(lineChartData3, {
            responsive: false
        });
        $( "#bnt-line-3" ).click(function() {
          var ctxPerfilesMenu3 = document.getElementById("canvas-perfiles-menu3").getContext("2d");
          window.myLinePerfilesMenu3 = new Chart(ctxPerfilesMenu3).Line(lineChartData3, {
            responsive: false
          });
        });
       
       
        $( "#bnt-line-3b" ).click(function() {
          var ctxPerfilesMenu3b = document.getElementById("canvas-perfiles-menu3b").getContext("2d");
          window.myLinePerfilesMenu3b = new Chart(ctxPerfilesMenu3b).Line(lineChartData3b, {
            responsive: false
          });
        });

    var canvas = document.getElementById('canvas-proyeccion-menu3'),
    ctxProyeccionMenu3 = canvas.getContext('2d'),
    startingData = {
            labels : [1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,
            2017,2018,2019,2020,2021,2022,2023,2024,2025,2026,2027,2028,2029,2030],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(206,206,206,0.2)",
                    strokeColor : "rgba(206,206,206,1)",
                    pointColor : "rgba(206,206,206,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(206,206,206,1)",
                    data : [null,null,null,null,null,null,null,null,null,isr_pm_shcp_PROY[0], isr_pm_shcp_PROY[1], isr_pm_shcp_PROY[2], isr_pm_shcp_PROY[3], isr_pm_shcp_PROY[4], isr_pm_shcp_PROY[5],
                    isr_pm_shcp_PROY[6], isr_pm_shcp_PROY[7], isr_pm_shcp_PROY[8], isr_pm_shcp_PROY[9], isr_pm_shcp_PROY[10], isr_pm_shcp_PROY[11], 
                    isr_pm_shcp_PROY[12] ]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(229, 95, 95, 0.2)",
                    strokeColor : "rgba(229, 95, 95, 1)",
                    pointColor : "rgba(229, 95, 95, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(229, 95, 95, 1)",
                    data : [isr_pm_PROY[0], isr_pm_PROY[1], isr_pm_PROY[2], isr_pm_PROY[3], isr_pm_PROY[4], isr_pm_PROY[5], isr_pm_PROY[6], isr_pm_PROY[7], 
                    isr_pm_PROY[8], isr_pm_PROY[9], isr_pm_PROY[10], isr_pm_PROY[11], isr_pm_PROY[12], isr_pm_PROY[13], isr_pm_PROY[14], isr_pm_PROY[15], 
                    isr_pm_PROY[16], isr_pm_PROY[17], isr_pm_PROY[18], isr_pm_PROY[19], isr_pm_PROY[20], isr_pm_PROY[21], isr_pm_PROY[22], isr_pm_PROY[23],
                    isr_pm_PROY[24], isr_pm_PROY[25], isr_pm_PROY[26], isr_pm_PROY[27], isr_pm_PROY[28], isr_pm_PROY[29], isr_pm_PROY[30],
                    isr_pm_PROY[31], isr_pm_PROY[32], isr_pm_PROY[33], isr_pm_PROY[34], isr_pm_PROY[35], isr_pm_PROY[36], isr_pm_PROY[37] ]
                }
      ]
    };
    var myChartProyeccionMenu3 = new Chart(ctxProyeccionMenu3).Line(startingData, {animationSteps: 15});



		
				},
				beforeSend: function () {
					$( "#cargando" ).show();
					alert ( "La ejecución puede demorar hasta un minuto");
				},		
				error: function(request,error) {
					console.log(request);
					console.log("Museo: sin motor Stata detrás (" + error + ")");
				},
				complete:function () {
					$( "#cargando" ).hide();
				}

			});
		
		//cancel the submit button default behaviours

		});



	/*****************  envio de petroleo ******************/	
	$('#distr_oilSub').click(function(){
		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);

		//Simple validation to make sure user entered something
		//If error found, add hightlight class to the text field

		var distr_oil1 = $('#valor-fader1').val();
		var distr_oil2 = $('#valor-fader2').val();
		var distr_oil3 = $('#valor-fader3').val();
		var distr_oil4 = $('#valor-fader4').val();
		var distr_oil5 = $('#valor-fader5').val();
		var distr_oil6 = $('#valor-fader6').val();
		var distr_oil7 = $('#valor-fader7').val();
		var distr_oil8 = $('#valor-fader8').val();
		var distr_oil9 = $('#valor-fader9').val();
		var distr_oil10 = $('#valor-fader10').val();
		var distr_oil11 = $('#valor-fader11').val();
		var distr_oil12 = $('#valor-fader12').val();
		var distr_oil13 = $('#valor-fader13').val();
		var distr_oil14 = $('#valor-fader14').val();
		var distr_oil15 = $('#valor-fader15').val();
		var distr_oil16 = $('#valor-fader16').val();


		//organize the data properly /// arreglar lo de existencia de cookie no genere una nueva

		var data = 'distr_oil1=' + distr_oil1 + '&distr_oil2=' + distr_oil2 + '&distr_oil3=' + distr_oil3 + '&distr_oil4=' + distr_oil4 + 
		'&distr_oil5=' + distr_oil5 + '&distr_oil6=' + distr_oil6 + '&distr_oil7=' + distr_oil7 + '&distr_oil8=' + distr_oil8 + 
		'&distr_oil9=' + distr_oil9 + '&distr_oil10=' + distr_oil10 + '&distr_oil11=' + distr_oil11 + '&distr_oil12=' + distr_oil12 + 
		'&distr_oil13=' + distr_oil13 + '&distr_oil14=' + distr_oil14 + '&distr_oil15=' + distr_oil15 + '&distr_oil16=' + distr_oil16 +
		'&idSession='+idSession ;

		//start the ajax
			$.ajax({
				//this is the php file that processes the data and send mail
				url: "distr_oilStata.php",	
				
				async:false,
	
				//GET method is used
				type: "GET",
	
				//pass the data			
				data: data,		
				
				//Do not cache the page
				cache: false,
				
				//success
				success: function (html) {	

					var distr_oil_I1 = eval($(html).find("distr_oil_I1").text()); 
					var distr_oil_I2 = eval($(html).find("distr_oil_I2").text()); 
					var distr_oil_I3 = eval($(html).find("distr_oil_I3").text()); 
					var distr_oil_V = eval($(html).find("distr_oil_V").text()); 

					cambiosGlobales(html);

					var distr_oil_PH = eval($(html).find("distr_oil_PH").text()); 
					var distr_oil_CH = eval($(html).find("distr_oil_CH").text()); 
					var distr_oil_PM = eval($(html).find("distr_oil_PM").text()); 
					var distr_oil_CM = eval($(html).find("distr_oil_CM").text()); 
 
					var distr_oil_PROY = eval($(html).find("distr_oil_PROY").text()); 
					var distr_oil_shcp_PROY = eval($(html).find("distr_oil_shcp_PROY").text()); 


					for(var i=0;i<distr_oil_I1.length;i++) { 
						$('#distr_oil_I1_'+i).html(distr_oil_I1[i]);
						$('#distr_oil_I2_'+i).html(distr_oil_I2[i]);
						$('#distr_oil_I3_'+i).html(distr_oil_I3[i]);
					}
					
					for(var i=0;i<distr_oil_V.length;i++) { 
						$('#distr_oil_V_'+i).html(distr_oil_V[i]);
					}




        var lineChartData5 = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [distr_oil_PH[0], distr_oil_PH[1], distr_oil_PH[2], distr_oil_PH[3], distr_oil_PH[4], distr_oil_PH[5], distr_oil_PH[6], distr_oil_PH[7], distr_oil_PH[8], distr_oil_PH[9], distr_oil_PH[10], distr_oil_PH[11], distr_oil_PH[12], distr_oil_PH[13], distr_oil_PH[14], distr_oil_PH[15], distr_oil_PH[16], distr_oil_PH[17], distr_oil_PH[18], distr_oil_PH[19], distr_oil_PH[20], distr_oil_PH[21], distr_oil_PH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [distr_oil_PM[0], distr_oil_PM[1], distr_oil_PM[2], distr_oil_PM[3], distr_oil_PM[4], distr_oil_PM[5], distr_oil_PM[6], distr_oil_PM[7], distr_oil_PM[8], distr_oil_PM[9], distr_oil_PM[10], distr_oil_PM[11], distr_oil_PM[12], distr_oil_PM[13], distr_oil_PM[14], distr_oil_PM[15], distr_oil_PM[16], distr_oil_PM[17], distr_oil_PM[18], distr_oil_PM[19], distr_oil_PM[20], distr_oil_PM[21], distr_oil_PM[22]]
                }
            ]

        }


        var lineChartData5b = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [distr_oil_CH[0], distr_oil_CH[1], distr_oil_CH[2], distr_oil_CH[3], distr_oil_CH[4], distr_oil_CH[5], distr_oil_CH[6], distr_oil_CH[7], distr_oil_CH[8], distr_oil_CH[9], distr_oil_CH[10], distr_oil_CH[11], distr_oil_CH[12], distr_oil_CH[13], distr_oil_CH[14], distr_oil_CH[15], distr_oil_CH[16], distr_oil_CH[17], distr_oil_CH[18], distr_oil_CH[19], distr_oil_CH[20], distr_oil_CH[21], distr_oil_CH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [distr_oil_CM[0], distr_oil_CM[1], distr_oil_CM[2], distr_oil_CM[3], distr_oil_CM[4], distr_oil_CM[5], distr_oil_CM[6], distr_oil_CM[7], distr_oil_CM[8], distr_oil_CM[9], distr_oil_CM[10], distr_oil_CM[11], distr_oil_CM[12], distr_oil_CM[13], distr_oil_CM[14], distr_oil_CM[15], distr_oil_CM[16], distr_oil_CM[17], distr_oil_CM[18], distr_oil_CM[19], distr_oil_CM[20], distr_oil_CM[21], distr_oil_CM[22]]
                }
            ]

        }

        var canvCls = document.getElementById("canvas-perfiles-menu5").getContext("2d");
        canvCls.clearRect(0, 0, canvCls.width, canvCls.height);
        canvCls = document.getElementById("canvas-perfiles-menu5b").getContext("2d");
        canvCls.clearRect(0, 0, canvCls.width, canvCls.height);

        var ctxPerfilesMenu5 = document.getElementById("canvas-perfiles-menu5").getContext("2d");
          window.myLinePerfilesMenu5 = new Chart(ctxPerfilesMenu5).Line(lineChartData5, {
            responsive: false
        });
        $( "#bnt-line-5" ).click(function() {
          var ctxPerfilesMenu5 = document.getElementById("canvas-perfiles-menu5").getContext("2d");
          window.myLinePerfilesMenu5 = new Chart(ctxPerfilesMenu5).Line(lineChartData5, {
            responsive: false
          });
        });
       
       
        $( "#bnt-line-5b" ).click(function() {
          var ctxPerfilesMenu5b = document.getElementById("canvas-perfiles-menu5b").getContext("2d");
          window.myLinePerfilesMenu5b = new Chart(ctxPerfilesMenu5b).Line(lineChartData5b, {
            responsive: false
          });
        });

    var canvas = document.getElementById('canvas-proyeccion-menu5'),
    ctxProyeccionMenu5 = canvas.getContext('2d'),
    startingData = {
            labels : [1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,
            2017,2018,2019,2020,2021,2022,2023,2024,2025,2026,2027,2028,2029,2030],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(206,206,206,0.2)",
                    strokeColor : "rgba(206,206,206,1)",
                    pointColor : "rgba(206,206,206,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(206,206,206,1)",
                    data : [distr_oil_shcp_PROY[0], distr_oil_shcp_PROY[1], distr_oil_shcp_PROY[2], distr_oil_shcp_PROY[3], distr_oil_shcp_PROY[4], distr_oil_shcp_PROY[5],
                    distr_oil_shcp_PROY[6], distr_oil_shcp_PROY[7], distr_oil_shcp_PROY[8], distr_oil_shcp_PROY[9], distr_oil_shcp_PROY[10], distr_oil_shcp_PROY[11], 
                    distr_oil_shcp_PROY[12], distr_oil_shcp_PROY[13], distr_oil_shcp_PROY[14], distr_oil_shcp_PROY[15], distr_oil_shcp_PROY[16], 
                    distr_oil_shcp_PROY[17], distr_oil_shcp_PROY[18], distr_oil_shcp_PROY[19], distr_oil_shcp_PROY[20], 
                    distr_oil_shcp_PROY[21], distr_oil_shcp_PROY[22] ]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(229, 95, 95, 0.2)",
                    strokeColor : "rgba(229, 95, 95, 1)",
                    pointColor : "rgba(229, 95, 95, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(229, 95, 95, 1)",
                    data : [null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,
                    null,null,null,null,distr_oil_PROY[0], distr_oil_PROY[1], distr_oil_PROY[2], distr_oil_PROY[3], 
                    distr_oil_PROY[4], distr_oil_PROY[5], distr_oil_PROY[6], distr_oil_PROY[7], distr_oil_PROY[8], 
                    distr_oil_PROY[9], distr_oil_PROY[10], distr_oil_PROY[11], distr_oil_PROY[12], distr_oil_PROY[13], 
                    distr_oil_PROY[14],distr_oil_PROY[15]]
                }
      ]
    };
    var myChartProyeccionMenu5 = new Chart(ctxProyeccionMenu5).Line(startingData, {animationSteps: 15});



		
				},
				beforeSend: function () {
					$( "#cargando" ).show();
					alert ( "La ejecución puede demorar hasta un minuto");
				},		
				error: function(request,error) {
					console.log(request);
					console.log("Museo: sin motor Stata detrás (" + error + ")");
				},
				complete:function () {
					$( "#cargando" ).hide();
				}

			});
		
		//cancel the submit button default behaviours

		});




	/*****************  envio de ieps ******************/	
	$('#iepsSub').click(function(){
		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);

		//Simple validation to make sure user entered something
		//If error found, add hightlight class to the text field

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


		//organize the data properly /// arreglar lo de existencia de cookie no genere una nueva

		var data = 'IEPSA1=' + IEPSA1 + '&IEPSA2=' + IEPSA2 + '&IEPSA3=' + IEPSA3 + '&IEPSA4=' + IEPSA4 + 
		'&IEPSA5=' + IEPSA5 + '&IEPSA6=' + IEPSA6 + '&IEPSA7=' + IEPSA7 + '&IEPSA8=' + IEPSA8 + 
		'&IEPSA9=' + IEPSA9 + '&IEPSA10=' + IEPSA10 + '&IEPSA11=' + IEPSA11 + '&IEPSA12=' + IEPSA12 + 
		'&IEPSA13=' + IEPSA13 +'&idSession='+idSession ;

		//start the ajax
			$.ajax({
				//this is the php file that processes the data and send mail
				url: "iepsnpStata.php",	
				
				async:false,
	
				//GET method is used
				type: "GET",
	
				//pass the data			
				data: data,		
				
				//Do not cache the page
				cache: false,
				
				//success
				success: function (html) {	

					var ieps2_total_I1 = eval($(html).find("ieps2_total_I1").text()); 
					var ieps2_total_I2 = eval($(html).find("ieps2_total_I2").text()); 
					var ieps2_total_I3 = eval($(html).find("ieps2_total_I3").text()); 
					var ieps2_total_V = eval($(html).find("ieps2_total_V").text()); 

					cambiosGlobales(html);

					var ieps2_total_PH = eval($(html).find("ieps2_total_PH").text()); 
					var ieps2_total_CH = eval($(html).find("ieps2_total_CH").text()); 
					var ieps2_total_PM = eval($(html).find("ieps2_total_PM").text()); 
					var ieps2_total_CM = eval($(html).find("ieps2_total_CM").text()); 
 
/*
					var ieps2_alcohol_shcp_PROY = eval($(html).find("ieps2_alcohol_shcp_PROY").text()); 
					var ieps2_benerg_shcp_PROY = eval($(html).find("ieps2_benerg_shcp_PROY").text()); 
					var ieps2_bsabor_shcp_PROY = eval($(html).find("ieps2_bsabor_shcp_PROY").text()); 
					var ieps2_cerveza_shcp_PROY = eval($(html).find("ieps2_cerveza_shcp_PROY").text()); 
					var ieps2_chatarra_shcp_PROY = eval($(html).find("ieps2_chatarra_shcp_PROY").text()); 
					var ieps2_sorteos_shcp_PROY = eval($(html).find("ieps2_sorteos_shcp_PROY").text()); 
					var ieps2_tabaco_shcp_PROY = eval($(html).find("ieps2_tabaco_shcp_PROY").text()); 
					var ieps2_tele_shcp_PROY = eval($(html).find("ieps2_tele_shcp_PROY").text());
					
					var ieps2_alcohol_PROY = eval($(html).find("ieps2_alcohol_PROY").text()); 
					var ieps2_benerg_PROY = eval($(html).find("ieps2_benerg_PROY").text()); 
					var ieps2_bsabor_PROY = eval($(html).find("ieps2_bsabor_PROY").text()); 
					var ieps2_cerveza_PROY = eval($(html).find("ieps2_cerveza_PROY").text()); 
					var ieps2_chatarra_PROY = eval($(html).find("ieps2_chatarra_PROY").text()); 
					var ieps2_sorteos_PROY = eval($(html).find("ieps2_sorteos_PROY").text()); 
					var ieps2_tabaco_PROY = eval($(html).find("ieps2_tabaco_PROY").text()); 
					var ieps2_tele_PROY = eval($(html).find("ieps2_tele_PROY").text());
					 
					var ieps2_alcohol_anios = eval($(html).find("ieps2_alcohol_anios").text()); 
					var ieps2_benerg_anios = eval($(html).find("ieps2_benerg_anios").text()); 
					var ieps2_bsabor_anios = eval($(html).find("ieps2_bsabor_anios").text()); 
					var ieps2_cerveza_anios = eval($(html).find("ieps2_cerveza_anios").text()); 
					var ieps2_chatarra_anios = eval($(html).find("ieps2_chatarra_anios").text()); 
					var ieps2_sorteos_anios = eval($(html).find("ieps2_sorteos_anios").text()); 
					var ieps2_tabaco_anios = eval($(html).find("ieps2_tabaco_anios").text()); 
					var ieps2_tele_anios = eval($(html).find("ieps2_tele_anios").text());


					var distr_oil_PROY = eval($(html).find("distr_oil_PROY").text()); 
					var distr_oil_shcp_PROY = eval($(html).find("distr_oil_shcp_PROY").text()); 

					for(var i=0;i<ieps2_total_shcp_PROY.length;i++) { 
						ieps2_total_shcp_PROY[i] = ieps2_alcohol_shcp_PROY[i]+benerg_shcp_PROY[i]+ieps2_bsabor_shcp_PROY[i]+
								ieps2_cerveza_shcp_PROY[i]+ieps2_chatarra_shcp_PROY[i]+ieps2_sorteos_shcp_PROY[i]+
								ieps2_tabaco_shcp_PROY[i]+ieps2_tele_shcp_PROY[i];
								 
					}

*/
					var ieps2_total_shcp_PROY = eval($(html).find("ieps2_total_shcp_PROY").text());
					var ieps2_total_PROY = eval($(html).find("ieps2_total_PROY").text());


					for(var i=0;i<ieps2_total_I1.length;i++) { 
						$('#ieps2_total_I1_'+i).html(ieps2_total_I1[i]);
						$('#ieps2_total_I2_'+i).html(ieps2_total_I2[i]);
						$('#ieps2_total_I3_'+i).html(ieps2_total_I3[i]);
					}
					
					for(var i=0;i<ieps2_total_V.length;i++) { 
						$('#ieps2_total_V_'+i).html(ieps2_total_V[i]);
					}




        var lineChartData6 = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [ieps2_total_PH[0], ieps2_total_PH[1], ieps2_total_PH[2], ieps2_total_PH[3], ieps2_total_PH[4], ieps2_total_PH[5], ieps2_total_PH[6], ieps2_total_PH[7], ieps2_total_PH[8], ieps2_total_PH[9], ieps2_total_PH[10], ieps2_total_PH[11], ieps2_total_PH[12], ieps2_total_PH[13], ieps2_total_PH[14], ieps2_total_PH[15], ieps2_total_PH[16], ieps2_total_PH[17], ieps2_total_PH[18], ieps2_total_PH[19], ieps2_total_PH[20], ieps2_total_PH[21], ieps2_total_PH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [ieps2_total_PM[0], ieps2_total_PM[1], ieps2_total_PM[2], ieps2_total_PM[3], ieps2_total_PM[4], ieps2_total_PM[5], ieps2_total_PM[6], ieps2_total_PM[7], ieps2_total_PM[8], ieps2_total_PM[9], ieps2_total_PM[10], ieps2_total_PM[11], ieps2_total_PM[12], ieps2_total_PM[13], ieps2_total_PM[14], ieps2_total_PM[15], ieps2_total_PM[16], ieps2_total_PM[17], ieps2_total_PM[18], ieps2_total_PM[19], ieps2_total_PM[20], ieps2_total_PM[21], ieps2_total_PM[22]]
                }
            ]

        }


        var lineChartData6b = {
            labels : [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,109],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(220,220,220,0.2)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(220,220,220,1)",
                    data : [ieps2_total_CH[0], ieps2_total_CH[1], ieps2_total_CH[2], ieps2_total_CH[3], ieps2_total_CH[4], ieps2_total_CH[5], ieps2_total_CH[6], ieps2_total_CH[7], ieps2_total_CH[8], ieps2_total_CH[9], ieps2_total_CH[10], ieps2_total_CH[11], ieps2_total_CH[12], ieps2_total_CH[13], ieps2_total_CH[14], ieps2_total_CH[15], ieps2_total_CH[16], ieps2_total_CH[17], ieps2_total_CH[18], ieps2_total_CH[19], ieps2_total_CH[20], ieps2_total_CH[21], ieps2_total_CH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [ieps2_total_CM[0], ieps2_total_CM[1], ieps2_total_CM[2], ieps2_total_CM[3], ieps2_total_CM[4], ieps2_total_CM[5], ieps2_total_CM[6], ieps2_total_CM[7], ieps2_total_CM[8], ieps2_total_CM[9], ieps2_total_CM[10], ieps2_total_CM[11], ieps2_total_CM[12], ieps2_total_CM[13], ieps2_total_CM[14], ieps2_total_CM[15], ieps2_total_CM[16], ieps2_total_CM[17], ieps2_total_CM[18], ieps2_total_CM[19], ieps2_total_CM[20], ieps2_total_CM[21], ieps2_total_CM[22]]
                }
            ]

        }


        var canvCls = document.getElementById("canvas-perfiles-menu6").getContext("2d");
        canvCls.clearRect(0, 0, canvCls.width, canvCls.height);
        canvCls = document.getElementById("canvas-perfiles-menu6b").getContext("2d");
        canvCls.clearRect(0, 0, canvCls.width, canvCls.height);

        var ctxPerfilesMenu6 = document.getElementById("canvas-perfiles-menu6").getContext("2d");
          window.myLinePerfilesMenu6 = new Chart(ctxPerfilesMenu6).Line(lineChartData6, {
            responsive: false
        });
        $( "#bnt-line-6" ).click(function() {
          var ctxPerfilesMenu6 = document.getElementById("canvas-perfiles-menu6").getContext("2d");
          window.myLinePerfilesMenu6 = new Chart(ctxPerfilesMenu6).Line(lineChartData6, {
            responsive: false
          });
        });
       
       
        $( "#bnt-line-6b" ).click(function() {
          var ctxPerfilesMenu6b = document.getElementById("canvas-perfiles-menu6b").getContext("2d");
          window.myLinePerfilesMenu6b = new Chart(ctxPerfilesMenu6b).Line(lineChartData6b, {
            responsive: false
          });
        });

    var canvas = document.getElementById('canvas-proyeccion-menu6'),
    ctxProyeccionMenu6 = canvas.getContext('2d'),
    startingData = {
            labels : [1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,
            2017,2018,2019,2020,2021,2022,2023,2024,2025,2026,2027,2028,2029,2030],
            scaleGridLineColor : "rgba(0,0,0,1)",
            datasets : [
                {
                    label: "Hombres",
                    fillColor : "rgba(206,206,206,0.2)",
                    strokeColor : "rgba(206,206,206,1)",
                    pointColor : "rgba(206,206,206,1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(206,206,206,1)",
                    data : [ieps2_total_shcp_PROY[0], ieps2_total_shcp_PROY[1], ieps2_total_shcp_PROY[2], ieps2_total_shcp_PROY[3], ieps2_total_shcp_PROY[4], ieps2_total_shcp_PROY[5],
                    ieps2_total_shcp_PROY[6], ieps2_total_shcp_PROY[7], ieps2_total_shcp_PROY[8], ieps2_total_shcp_PROY[9], ieps2_total_shcp_PROY[10], ieps2_total_shcp_PROY[11], 
                    ieps2_total_shcp_PROY[12], ieps2_total_shcp_PROY[13], ieps2_total_shcp_PROY[14], ieps2_total_shcp_PROY[15], ieps2_total_shcp_PROY[16], 
                    ieps2_total_shcp_PROY[17], ieps2_total_shcp_PROY[18], ieps2_total_shcp_PROY[19], ieps2_total_shcp_PROY[20],ieps2_total_shcp_PROY[21],ieps2_total_shcp_PROY[22]]
/*                    data : [ieps2_total_shcp_PROY[0], ieps2_total_shcp_PROY[1], ieps2_total_shcp_PROY[2], ieps2_total_shcp_PROY[3], ieps2_total_shcp_PROY[4], ieps2_total_shcp_PROY[5],
                    ieps2_total_shcp_PROY[6], ieps2_total_shcp_PROY[7], ieps2_total_shcp_PROY[8], ieps2_total_shcp_PROY[9], ieps2_total_shcp_PROY[10], ieps2_total_shcp_PROY[11], 
                    ieps2_total_shcp_PROY[12], ieps2_total_shcp_PROY[13], ieps2_total_shcp_PROY[14], ieps2_total_shcp_PROY[15], ieps2_total_shcp_PROY[16], 
                    ieps2_total_shcp_PROY[17], ieps2_total_shcp_PROY[18], ieps2_total_shcp_PROY[19], ieps2_total_shcp_PROY[20], 
                    ieps2_total_shcp_PROY[21], ieps2_total_shcp_PROY[22], ieps2_total_shcp_PROY[23], ieps2_total_shcp_PROY[24],
                    ieps2_total_shcp_PROY[25], ieps2_total_shcp_PROY[26], ieps2_total_shcp_PROY[27], ieps2_total_shcp_PROY[28],
                    ieps2_total_shcp_PROY[29], ieps2_total_shcp_PROY[30], ieps2_total_shcp_PROY[31], ieps2_total_shcp_PROY[32],
                    ieps2_total_shcp_PROY[33], ieps2_total_shcp_PROY[34], ieps2_total_shcp_PROY[35], ieps2_total_shcp_PROY[36],
                    ieps2_total_shcp_PROY[37]]
*/                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(229, 95, 95, 0.2)",
                    strokeColor : "rgba(229, 95, 95, 1)",
                    pointColor : "rgba(229, 95, 95, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(229, 95, 95, 1)",
                    data : [ieps2_total_PROY[0], ieps2_total_PROY[1], ieps2_total_PROY[2], ieps2_total_PROY[3], 
                    ieps2_total_PROY[4], ieps2_total_PROY[5], ieps2_total_PROY[6], ieps2_total_PROY[7], ieps2_total_PROY[8], 
                    ieps2_total_PROY[9], ieps2_total_PROY[10], ieps2_total_PROY[11], ieps2_total_PROY[12], ieps2_total_PROY[13], 
                    ieps2_total_PROY[14],ieps2_total_PROY[15], ieps2_total_PROY[16], 
                    ieps2_total_PROY[17], ieps2_total_PROY[18], ieps2_total_PROY[19], ieps2_total_PROY[20], 
                    ieps2_total_PROY[21], ieps2_total_PROY[22], ieps2_total_PROY[23], ieps2_total_PROY[24],
                    ieps2_total_PROY[25], ieps2_total_PROY[26], ieps2_total_PROY[27], ieps2_total_PROY[28],
                    ieps2_total_PROY[29], ieps2_total_PROY[30], ieps2_total_PROY[31], ieps2_total_PROY[32],
                    ieps2_total_PROY[33], ieps2_total_PROY[34], ieps2_total_PROY[35], ieps2_total_PROY[36],
                    ieps2_total_PROY[37]]
                }
      ]
    };
    var myChartProyeccionMenu6 = new Chart(ctxProyeccionMenu6).Line(startingData, {animationSteps: 15});



		
				},
				beforeSend: function () {
					$( "#cargando" ).show();
					alert ( "La ejecución puede demorar hasta un minuto");
				},		
				error: function(request,error) {
					console.log(request);
					console.log("Museo: sin motor Stata detrás (" + error + ")");
				},
				complete:function () {
					$( "#cargando" ).hide();
				}

			});
		
		//cancel the submit button default behaviours

		});



});	

