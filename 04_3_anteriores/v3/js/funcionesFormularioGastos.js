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
          ['educacion',				'Impuestos',        		LIF[2], 		LIF[2]],
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
	
	
	
/**************************************carga os valores por defecto   **********/	
				var idSession=makeid(); 
			if(getCookie("idSession")!=null) {
				idSession=getCookie("idSession");
			} 

				$.ajax({
				//this is the php file that processes the data and send mail
				url: "defaultStata-gasto.xml", dataType: "xml", // MUSEO (2026-10-01): respuesta estática; el original llamaba defaultStata.php	
				
				async:false,
	
				//GET method is used
				type: "GET",
	
				//pass the data			
				data: "idSession="+idSession,		
				
				//Do not cache the page
				cache: false,
				
				//success
				success: function (html) {	
	
					var gasto_educacion_I1 = eval($(html).find("gasto_educacion_I1").text()); 
					var gasto_educacion_I2 = eval($(html).find("gasto_educacion_I2").text()); 
					var gasto_educacion_I3 = eval($(html).find("gasto_educacion_I3").text()); 
					var gasto_educacion_V = eval($(html).find("gasto_educacion_V").text()); 

					var gasto_educacion_PH = eval($(html).find("gasto_educacion_PH").text()); 
					var gasto_educacion_CH = eval($(html).find("gasto_educacion_CH").text()); 
					var gasto_educacion_PM = eval($(html).find("gasto_educacion_PM").text()); 
					var gasto_educacion_CM = eval($(html).find("gasto_educacion_CM").text()); 
 
					var gasto_educacion_PROY = eval($(html).find("gasto_educacion_PROY").text()); 
					var gasto_educacion_shcp_PROY = eval($(html).find("gasto_educacion_shcp_PROY").text()); 
 

					cambiosGlobales(html);

					for(var i=0;i<gasto_educacion_I1.length;i++) { 
						$('#gasto_educacion_I1_'+i).html(gasto_educacion_I1[i]);
						$('#gasto_educacion_I2_'+i).html(gasto_educacion_I2[i]);
						$('#gasto_educacion_I3_'+i).html(gasto_educacion_I3[i]);
					}
					
					for(var i=0;i<gasto_educacion_I1.length;i++) { 
						$('#gasto_educacion_V_'+i).html(gasto_educacion_V[i]);
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
                    data : [gasto_educacion_PH[0], gasto_educacion_PH[1], gasto_educacion_PH[2], gasto_educacion_PH[3], gasto_educacion_PH[4], gasto_educacion_PH[5], gasto_educacion_PH[6], gasto_educacion_PH[7], gasto_educacion_PH[8], gasto_educacion_PH[9], gasto_educacion_PH[10], gasto_educacion_PH[11], gasto_educacion_PH[12], gasto_educacion_PH[13], gasto_educacion_PH[14], gasto_educacion_PH[15], gasto_educacion_PH[16], gasto_educacion_PH[17], gasto_educacion_PH[18], gasto_educacion_PH[19], gasto_educacion_PH[20], gasto_educacion_PH[21], gasto_educacion_PH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [gasto_educacion_PM[0], gasto_educacion_PM[1], gasto_educacion_PM[2], gasto_educacion_PM[3], gasto_educacion_PM[4], gasto_educacion_PM[5], gasto_educacion_PM[6], gasto_educacion_PM[7], gasto_educacion_PM[8], gasto_educacion_PM[9], gasto_educacion_PM[10], gasto_educacion_PM[11], gasto_educacion_PM[12], gasto_educacion_PM[13], gasto_educacion_PM[14], gasto_educacion_PM[15], gasto_educacion_PM[16], gasto_educacion_PM[17], gasto_educacion_PM[18], gasto_educacion_PM[19], gasto_educacion_PM[20], gasto_educacion_PM[21], gasto_educacion_PM[22]]
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
                    data : [gasto_educacion_CH[0], gasto_educacion_CH[1], gasto_educacion_CH[2], gasto_educacion_CH[3], gasto_educacion_CH[4], gasto_educacion_CH[5], gasto_educacion_CH[6], gasto_educacion_CH[7], gasto_educacion_CH[8], gasto_educacion_CH[9], gasto_educacion_CH[10], gasto_educacion_CH[11], gasto_educacion_CH[12], gasto_educacion_CH[13], gasto_educacion_CH[14], gasto_educacion_CH[15], gasto_educacion_CH[16], gasto_educacion_CH[17], gasto_educacion_CH[18], gasto_educacion_CH[19], gasto_educacion_CH[20], gasto_educacion_CH[21], gasto_educacion_CH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [gasto_educacion_CM[0], gasto_educacion_CM[1], gasto_educacion_CM[2], gasto_educacion_CM[3], gasto_educacion_CM[4], gasto_educacion_CM[5], gasto_educacion_CM[6], gasto_educacion_CM[7], gasto_educacion_CM[8], gasto_educacion_CM[9], gasto_educacion_CM[10], gasto_educacion_CM[11], gasto_educacion_CM[12], gasto_educacion_CM[13], gasto_educacion_CM[14], gasto_educacion_CM[15], gasto_educacion_CM[16], gasto_educacion_CM[17], gasto_educacion_CM[18], gasto_educacion_CM[19], gasto_educacion_CM[20], gasto_educacion_CM[21], gasto_educacion_CM[22]]
                }
            ]

        }

        var ctxPerfilesMenu1 = document.getElementById("canvas-perfiles-menu1").getContext("2d");
          window.myLinePerfilesMenu1 = new Chart(ctxPerfilesMenu1).Line(lineChartData1, {
            responsive: false
        });
        $( "#bnt-line-1" ).click(function() {
          var ctxPerfilesMenu1 = document.getElementById("canvas-perfiles-menu1").getContext("2d");
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
                    data : [null,null,null,null,null,null,null,null,null,null,null,null,null,null,gasto_educacion_shcp_PROY[0], gasto_educacion_shcp_PROY[1], gasto_educacion_shcp_PROY[2], gasto_educacion_shcp_PROY[3], gasto_educacion_shcp_PROY[4], gasto_educacion_shcp_PROY[5],
                    gasto_educacion_shcp_PROY[6], gasto_educacion_shcp_PROY[7], gasto_educacion_shcp_PROY[8] ]
                },
                {
                    label: "Proyeccion",
                    fillColor : "rgba(229, 95, 95, 0.2)",
                    strokeColor : "rgba(229, 95, 95, 1)",
                    pointColor : "rgba(229, 95, 95, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(229, 95, 95, 1)",
                    data : [gasto_educacion_PROY[0], gasto_educacion_PROY[1], gasto_educacion_PROY[2], gasto_educacion_PROY[3], gasto_educacion_PROY[4], gasto_educacion_PROY[5], gasto_educacion_PROY[6], gasto_educacion_PROY[7], 
                    gasto_educacion_PROY[8], gasto_educacion_PROY[9], gasto_educacion_PROY[10], gasto_educacion_PROY[11], gasto_educacion_PROY[12], gasto_educacion_PROY[13], gasto_educacion_PROY[14], gasto_educacion_PROY[15], 
                    gasto_educacion_PROY[16], gasto_educacion_PROY[17], gasto_educacion_PROY[18], gasto_educacion_PROY[19], gasto_educacion_PROY[20], gasto_educacion_PROY[21], gasto_educacion_PROY[22], gasto_educacion_PROY[23],
                    gasto_educacion_PROY[24], gasto_educacion_PROY[25], gasto_educacion_PROY[26], gasto_educacion_PROY[27], gasto_educacion_PROY[28], gasto_educacion_PROY[29], gasto_educacion_PROY[30],
                    gasto_educacion_PROY[31], gasto_educacion_PROY[32], gasto_educacion_PROY[33], gasto_educacion_PROY[34], gasto_educacion_PROY[35], gasto_educacion_PROY[36], gasto_educacion_PROY[37] ]
                }
      ]
    };
    var myChartProyeccionMenu1 = new Chart(ctxProyeccionMenu1).Line(startingData, {animationSteps: 15});

		


					var salud_I1 = eval($(html).find("salud_I1").text()); 
					var salud_I2 = eval($(html).find("salud_I2").text()); 
					var salud_I3 = eval($(html).find("salud_I3").text()); 
					var salud_V = eval($(html).find("salud_V").text()); 

					var salud_PH = eval($(html).find("salud_PH").text()); 
					var salud_CH = eval($(html).find("salud_CH").text()); 
					var salud_PM = eval($(html).find("salud_PM").text()); 
					var salud_CM = eval($(html).find("salud_CM").text()); 
 
					var salud_PROY = eval($(html).find("salud_PROY").text()); 
					var salud_shcp_PROY = eval($(html).find("salud_shcp_PROY").text()); 


					for(var i=0;i<salud_I1.length;i++) { 
						$('#salud_I1_'+i).html(salud_I1[i]);
						$('#salud_I2_'+i).html(salud_I2[i]);
						$('#salud_I3_'+i).html(salud_I3[i]);
					}
					
					for(var i=0;i<salud_V.length;i++) { 
						$('#salud_V_'+i).html(salud_V[i]);
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
                    data : [salud_PH[0], salud_PH[1], salud_PH[2], salud_PH[3], salud_PH[4], salud_PH[5], salud_PH[6], salud_PH[7], salud_PH[8], salud_PH[9], salud_PH[10], salud_PH[11], salud_PH[12], salud_PH[13], salud_PH[14], salud_PH[15], salud_PH[16], salud_PH[17], salud_PH[18], salud_PH[19], salud_PH[20], salud_PH[21], salud_PH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [salud_PM[0], salud_PM[1], salud_PM[2], salud_PM[3], salud_PM[4], salud_PM[5], salud_PM[6], salud_PM[7], salud_PM[8], salud_PM[9], salud_PM[10], salud_PM[11], salud_PM[12], salud_PM[13], salud_PM[14], salud_PM[15], salud_PM[16], salud_PM[17], salud_PM[18], salud_PM[19], salud_PM[20], salud_PM[21], salud_PM[22]]
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
                    data : [salud_CH[0], salud_CH[1], salud_CH[2], salud_CH[3], salud_CH[4], salud_CH[5], salud_CH[6], salud_CH[7], salud_CH[8], salud_CH[9], salud_CH[10], salud_CH[11], salud_CH[12], salud_CH[13], salud_CH[14], salud_CH[15], salud_CH[16], salud_CH[17], salud_CH[18], salud_CH[19], salud_CH[20], salud_CH[21], salud_CH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [salud_CM[0], salud_CM[1], salud_CM[2], salud_CM[3], salud_CM[4], salud_CM[5], salud_CM[6], salud_CM[7], salud_CM[8], salud_CM[9], salud_CM[10], salud_CM[11], salud_CM[12], salud_CM[13], salud_CM[14], salud_CM[15], salud_CM[16], salud_CM[17], salud_CM[18], salud_CM[19], salud_CM[20], salud_CM[21], salud_CM[22]]
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
                    data : [null,null,null,null,null,null,null,null,null,null,null,null,null,null,salud_shcp_PROY[0], salud_shcp_PROY[1], salud_shcp_PROY[2], salud_shcp_PROY[3], salud_shcp_PROY[4], salud_shcp_PROY[5],
                    salud_shcp_PROY[6], salud_shcp_PROY[7], salud_shcp_PROY[8] ]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(229, 95, 95, 0.2)",
                    strokeColor : "rgba(229, 95, 95, 1)",
                    pointColor : "rgba(229, 95, 95, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(229, 95, 95, 1)",
                    data : [salud_PROY[0], salud_PROY[1], salud_PROY[2], salud_PROY[3], salud_PROY[4], salud_PROY[5], salud_PROY[6], salud_PROY[7], 
                    salud_PROY[8], salud_PROY[9], salud_PROY[10], salud_PROY[11], salud_PROY[12], salud_PROY[13], salud_PROY[14], salud_PROY[15], 
                    salud_PROY[16], salud_PROY[17], salud_PROY[18], salud_PROY[19], salud_PROY[20], salud_PROY[21], salud_PROY[22], salud_PROY[23],
                    salud_PROY[24], salud_PROY[25], salud_PROY[26], salud_PROY[27], salud_PROY[28], salud_PROY[29], salud_PROY[30],
                    salud_PROY[31], salud_PROY[32], salud_PROY[33], salud_PROY[34], salud_PROY[35], salud_PROY[36], salud_PROY[37] ]
                }
      ]
    };
    var myChartProyeccionMenu2 = new Chart(ctxProyeccionMenu2).Line(startingData, {animationSteps: 15});

				},
				error: function(request,error) {
					console.log(request);
					console.log("Museo: sin motor Stata detrás (" + error + ")");
				}

			});
	
	

		/*****************  envio de Educacion ************************/	

	$('#educacionSub').click(function(){
			var idSession=makeid(); 
			if(getCookie("idSession")!=null) {
				idSession=getCookie("idSession");
			} 
			setCookie("idSession",idSession,1);

			var educacionA1 = $('#educacionA1').val();
			var educacionA2 = $('#educacionA2').val();
			var educacionA3 = $('#educacionA3').val();
			var educacionA4 = $('#educacionA4').val();
			var educacionA5 = $('#educacionA5').val();
			var educacionA6 = $('#educacionA6').val();
			var educacionA7 = $('#educacionA7').val();
			var educacionA8 = $('#educacionA8').val();
			var educacionA9 = $('#educacionA9').val();
			var educacionA10 = $('#educacionA10').val();
			var educacionA11 = $('#educacionA11').val();
			var educacionA12 = $('#educacionA12').val();
			var educacionA13 = $('#educacionA13').val();
			var educacionA14 = $('#educacionA14').val();
			var educacionA15 = $('#educacionA15').val();
			var educacionA16 = $('#educacionA16').val();
			var educacionA17 = $('#educacionA17').val();
			var educacionA18 = $('#educacionA18').val();
			var educacionA19 = $('#educacionA19').val();

	
			setCookie("idSession",idSession,1);
			
			var data ='educacionA1=' + educacionA1 +'&educacionA2=' + educacionA2 + '&educacionA3=' + educacionA3 +
			'&educacionA4=' + educacionA4 +'&educacionA5=' + educacionA5 + '&educacionA6=' + educacionA6 + '&educacionA7=' + educacionA7 +
			'&educacionA8=' + educacionA8 +'&educacionA9=' + educacionA9 + '&educacionA10=' + educacionA10 + '&educacionA11=' + educacionA11 +
			'&educacionA12=' + educacionA12 +'&educacionA13=' + educacionA13 + '&educacionA14=' + educacionA14 + '&educacionA15=' + educacionA15 +
			'&educacionA16=' + educacionA16 +'&educacionA17=' + educacionA17 + '&educacionA18=' + educacionA18 + '&educacionA19=' + educacionA19 + '&idSession='+idSession ;
//			alert(data);
			$.ajax({
				//this is the php file that processes the data and send mail
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

					var gasto_educacion_I1 = eval($(html).find("gasto_educacion_I1").text()); 
					var gasto_educacion_I2 = eval($(html).find("gasto_educacion_I2").text()); 
					var gasto_educacion_I3 = eval($(html).find("gasto_educacion_I3").text()); 
					var gasto_educacion_V = eval($(html).find("gasto_educacion_V").text()); 

					var gasto_educacion_PH = eval($(html).find("gasto_educacion_PH").text()); 
					var gasto_educacion_CH = eval($(html).find("gasto_educacion_CH").text()); 
					var gasto_educacion_PM = eval($(html).find("gasto_educacion_PM").text()); 
					var gasto_educacion_CM = eval($(html).find("gasto_educacion_CM").text()); 
 
					var gasto_educacion_PROY = eval($(html).find("gasto_educacion_PROY").text()); 
					var gasto_educacion_shcp_PROY = eval($(html).find("gasto_educacion_shcp_PROY").text()); 
 

					cambiosGlobales(html);

					for(var i=0;i<gasto_educacion_I1.length;i++) { 
						$('#gasto_educacion_I1_'+i).html(gasto_educacion_I1[i]);
						$('#gasto_educacion_I2_'+i).html(gasto_educacion_I2[i]);
						$('#gasto_educacion_I3_'+i).html(gasto_educacion_I3[i]);
					}
					
					for(var i=0;i<gasto_educacion_I1.length;i++) { 
						$('#gasto_educacion_V_'+i).html(gasto_educacion_V[i]);
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
                    data : [gasto_educacion_PH[0], gasto_educacion_PH[1], gasto_educacion_PH[2], gasto_educacion_PH[3], gasto_educacion_PH[4], gasto_educacion_PH[5], gasto_educacion_PH[6], gasto_educacion_PH[7], gasto_educacion_PH[8], gasto_educacion_PH[9], gasto_educacion_PH[10], gasto_educacion_PH[11], gasto_educacion_PH[12], gasto_educacion_PH[13], gasto_educacion_PH[14], gasto_educacion_PH[15], gasto_educacion_PH[16], gasto_educacion_PH[17], gasto_educacion_PH[18], gasto_educacion_PH[19], gasto_educacion_PH[20], gasto_educacion_PH[21], gasto_educacion_PH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [gasto_educacion_PM[0], gasto_educacion_PM[1], gasto_educacion_PM[2], gasto_educacion_PM[3], gasto_educacion_PM[4], gasto_educacion_PM[5], gasto_educacion_PM[6], gasto_educacion_PM[7], gasto_educacion_PM[8], gasto_educacion_PM[9], gasto_educacion_PM[10], gasto_educacion_PM[11], gasto_educacion_PM[12], gasto_educacion_PM[13], gasto_educacion_PM[14], gasto_educacion_PM[15], gasto_educacion_PM[16], gasto_educacion_PM[17], gasto_educacion_PM[18], gasto_educacion_PM[19], gasto_educacion_PM[20], gasto_educacion_PM[21], gasto_educacion_PM[22]]
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
                    data : [gasto_educacion_CH[0], gasto_educacion_CH[1], gasto_educacion_CH[2], gasto_educacion_CH[3], gasto_educacion_CH[4], gasto_educacion_CH[5], gasto_educacion_CH[6], gasto_educacion_CH[7], gasto_educacion_CH[8], gasto_educacion_CH[9], gasto_educacion_CH[10], gasto_educacion_CH[11], gasto_educacion_CH[12], gasto_educacion_CH[13], gasto_educacion_CH[14], gasto_educacion_CH[15], gasto_educacion_CH[16], gasto_educacion_CH[17], gasto_educacion_CH[18], gasto_educacion_CH[19], gasto_educacion_CH[20], gasto_educacion_CH[21], gasto_educacion_CH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [gasto_educacion_CM[0], gasto_educacion_CM[1], gasto_educacion_CM[2], gasto_educacion_CM[3], gasto_educacion_CM[4], gasto_educacion_CM[5], gasto_educacion_CM[6], gasto_educacion_CM[7], gasto_educacion_CM[8], gasto_educacion_CM[9], gasto_educacion_CM[10], gasto_educacion_CM[11], gasto_educacion_CM[12], gasto_educacion_CM[13], gasto_educacion_CM[14], gasto_educacion_CM[15], gasto_educacion_CM[16], gasto_educacion_CM[17], gasto_educacion_CM[18], gasto_educacion_CM[19], gasto_educacion_CM[20], gasto_educacion_CM[21], gasto_educacion_CM[22]]
                }
            ]

        }

        var ctxPerfilesMenu1 = document.getElementById("canvas-perfiles-menu1").getContext("2d");
          window.myLinePerfilesMenu1 = new Chart(ctxPerfilesMenu1).Line(lineChartData1, {
            responsive: false
        });
        $( "#bnt-line-1" ).click(function() {
          var ctxPerfilesMenu1 = document.getElementById("canvas-perfiles-menu1").getContext("2d");
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
                    data : [null,null,null,null,null,null,null,null,null,null,null,null,null,null,gasto_educacion_shcp_PROY[0], gasto_educacion_shcp_PROY[1], gasto_educacion_shcp_PROY[2], gasto_educacion_shcp_PROY[3], gasto_educacion_shcp_PROY[4], gasto_educacion_shcp_PROY[5],
                    gasto_educacion_shcp_PROY[6], gasto_educacion_shcp_PROY[7], gasto_educacion_shcp_PROY[8] ]
                },
                {
                    label: "Proyeccion",
                    fillColor : "rgba(229, 95, 95, 0.2)",
                    strokeColor : "rgba(229, 95, 95, 1)",
                    pointColor : "rgba(229, 95, 95, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(229, 95, 95, 1)",
                    data : [gasto_educacion_PROY[0], gasto_educacion_PROY[1], gasto_educacion_PROY[2], gasto_educacion_PROY[3], gasto_educacion_PROY[4], gasto_educacion_PROY[5], gasto_educacion_PROY[6], gasto_educacion_PROY[7], 
                    gasto_educacion_PROY[8], gasto_educacion_PROY[9], gasto_educacion_PROY[10], gasto_educacion_PROY[11], gasto_educacion_PROY[12], gasto_educacion_PROY[13], gasto_educacion_PROY[14], gasto_educacion_PROY[15], 
                    gasto_educacion_PROY[16], gasto_educacion_PROY[17], gasto_educacion_PROY[18], gasto_educacion_PROY[19], gasto_educacion_PROY[20], gasto_educacion_PROY[21], gasto_educacion_PROY[22], gasto_educacion_PROY[23],
                    gasto_educacion_PROY[24], gasto_educacion_PROY[25], gasto_educacion_PROY[26], gasto_educacion_PROY[27], gasto_educacion_PROY[28], gasto_educacion_PROY[29], gasto_educacion_PROY[30],
                    gasto_educacion_PROY[31], gasto_educacion_PROY[32], gasto_educacion_PROY[33], gasto_educacion_PROY[34], gasto_educacion_PROY[35], gasto_educacion_PROY[36], gasto_educacion_PROY[37] ]
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


	/*****************  envio de salud ************************/	
	$('#saludSub').click(function(){
		var idSession=makeid(); 
		if(getCookie("idSession")!=null) {
			idSession=getCookie("idSession");
		} 
		setCookie("idSession",idSession,1);

		//Simple validation to make sure user entered something
		//If error found, add hightlight class to the text field

//		alert("que hay");
		var salud1 = $('#salud1').val();
		var salud2 = $('#salud2').val();
		var salud3 = $('#salud3').val();
		var salud4 = $('#salud4').val();
		var salud5 = $('#salud5').val();
		var salud6 = $('#salud6').val();
		var salud7 = $('#salud7').val();
		var salud8 = $('#salud8').val();
		var salud9 = $('#salud9').val();


		//organize the data properly /// arreglar lo de existencia de cookie no genere una nueva
//		var idSession="sdfa21"; 

		var data = 'salud1=' + salud1 + '&salud2=' + salud2 + '&salud3=' + salud3 + '&salud4=' + salud4 + '&salud5=' + salud5 + 
		'&salud6=' + salud6 + '&salud7=' + salud7 + '&salud8=' + salud8 + '&salud9=' + salud9 + '&idSession='+idSession ;
//	alert(data);						

		//start the ajax
			$.ajax({
				//this is the php file that processes the data and send mail
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

					var salud_I1 = eval($(html).find("salud_I1").text()); 
					var salud_I2 = eval($(html).find("salud_I2").text()); 
					var salud_I3 = eval($(html).find("salud_I3").text()); 
					var salud_V = eval($(html).find("salud_V").text()); 

					cambiosGlobales(html);

					var salud_PH = eval($(html).find("salud_PH").text()); 
					var salud_CH = eval($(html).find("salud_CH").text()); 
					var salud_PM = eval($(html).find("salud_PM").text()); 
					var salud_CM = eval($(html).find("salud_CM").text()); 
 
					var salud_PROY = eval($(html).find("salud_PROY").text()); 
					var salud_shcp_PROY = eval($(html).find("salud_shcp_PROY").text()); 


					for(var i=0;i<salud_I1.length;i++) { 
						$('#salud_I1_'+i).html(salud_I1[i]);
						$('#salud_I2_'+i).html(salud_I2[i]);
						$('#salud_I3_'+i).html(salud_I3[i]);
					}
					
					for(var i=0;i<salud_V.length;i++) { 
						$('#salud_V_'+i).html(salud_V[i]);
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
                    data : [salud_PH[0], salud_PH[1], salud_PH[2], salud_PH[3], salud_PH[4], salud_PH[5], salud_PH[6], salud_PH[7], salud_PH[8], salud_PH[9], salud_PH[10], salud_PH[11], salud_PH[12], salud_PH[13], salud_PH[14], salud_PH[15], salud_PH[16], salud_PH[17], salud_PH[18], salud_PH[19], salud_PH[20], salud_PH[21], salud_PH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [salud_PM[0], salud_PM[1], salud_PM[2], salud_PM[3], salud_PM[4], salud_PM[5], salud_PM[6], salud_PM[7], salud_PM[8], salud_PM[9], salud_PM[10], salud_PM[11], salud_PM[12], salud_PM[13], salud_PM[14], salud_PM[15], salud_PM[16], salud_PM[17], salud_PM[18], salud_PM[19], salud_PM[20], salud_PM[21], salud_PM[22]]
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
                    data : [salud_CH[0], salud_CH[1], salud_CH[2], salud_CH[3], salud_CH[4], salud_CH[5], salud_CH[6], salud_CH[7], salud_CH[8], salud_CH[9], salud_CH[10], salud_CH[11], salud_CH[12], salud_CH[13], salud_CH[14], salud_CH[15], salud_CH[16], salud_CH[17], salud_CH[18], salud_CH[19], salud_CH[20], salud_CH[21], salud_CH[22]]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(150, 223, 98, 0.2)",
                    strokeColor : "rgba(150, 223, 98, 1)",
                    pointColor : "rgba(150, 223, 98, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(150, 223, 98, 1)",
                    data : [salud_CM[0], salud_CM[1], salud_CM[2], salud_CM[3], salud_CM[4], salud_CM[5], salud_CM[6], salud_CM[7], salud_CM[8], salud_CM[9], salud_CM[10], salud_CM[11], salud_CM[12], salud_CM[13], salud_CM[14], salud_CM[15], salud_CM[16], salud_CM[17], salud_CM[18], salud_CM[19], salud_CM[20], salud_CM[21], salud_CM[22]]
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
                    data : [null,null,null,null,null,null,null,null,null,null,null,null,null,null,salud_shcp_PROY[0], salud_shcp_PROY[1], salud_shcp_PROY[2], salud_shcp_PROY[3], salud_shcp_PROY[4], salud_shcp_PROY[5],
                    salud_shcp_PROY[6], salud_shcp_PROY[7], salud_shcp_PROY[8] ]
                },
                {
                    label: "Mujeres",
                    fillColor : "rgba(229, 95, 95, 0.2)",
                    strokeColor : "rgba(229, 95, 95, 1)",
                    pointColor : "rgba(229, 95, 95, 1)",
                    pointStrokeColor : "#fff",
                    pointHighlightFill : "#fff",
                    pointHighlightStroke : "rgba(229, 95, 95, 1)",
                    data : [salud_PROY[0], salud_PROY[1], salud_PROY[2], salud_PROY[3], salud_PROY[4], salud_PROY[5], salud_PROY[6], salud_PROY[7], 
                    salud_PROY[8], salud_PROY[9], salud_PROY[10], salud_PROY[11], salud_PROY[12], salud_PROY[13], salud_PROY[14], salud_PROY[15], 
                    salud_PROY[16], salud_PROY[17], salud_PROY[18], salud_PROY[19], salud_PROY[20], salud_PROY[21], salud_PROY[22], salud_PROY[23],
                    salud_PROY[24], salud_PROY[25], salud_PROY[26], salud_PROY[27], salud_PROY[28], salud_PROY[29], salud_PROY[30],
                    salud_PROY[31], salud_PROY[32], salud_PROY[33], salud_PROY[34], salud_PROY[35], salud_PROY[36], salud_PROY[37] ]
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



});	

