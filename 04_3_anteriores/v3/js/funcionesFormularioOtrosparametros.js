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
				url: "defaultStata-otros.xml", dataType: "xml", // MUSEO (2026-10-01): respuesta estática; el original llamaba defaultStata.php	
				
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



        var ctxPerfilesMenu1 = document.getElementById("canvas-line1").getContext("2d");
        window.myLinePerfilesMenu1 = new Chart(ctxPerfilesMenu1).Line(lineChartData1, {
            responsive: false
        });
        $( "#bnt-line-1" ).click(function() {
          var ctxPerfilesMenu1 = document.getElementById("canvas-line1").getContext("2d");
          ctxPerfilesMenu1.clearRect(0, 0, ctxPerfilesMenu1.width, ctxPerfilesMenu1.height);
          window.myLinePerfilesMenu1 = new Chart(ctxPerfilesMenu1).Line(lineChartData1, {
            responsive: false
          });
        });
       
       
        $( "#bnt-line-1b" ).click(function() {
          var ctxPerfilesMenu1b = document.getElementById("canvas-line2").getContext("2d");
          ctxPerfilesMenu1b.clearRect(0, 0, ctxPerfilesMenu1b.width, ctxPerfilesMenu1b.height);
          window.myLinePerfilesMenu1b = new Chart(ctxPerfilesMenu1b).Line(lineChartData1b, {
            responsive: false
          });
        });


    var canvas = document.getElementById("canvas-proyeccion-menu2").getContext("2d");
	 canvas.clearRect(0, 0, canvas.width, canvas.height);    
    var canvas = document.getElementById('canvas-proyeccion-menu2'),
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
                    iva3_shcp_PROY[18], iva3_shcp_PROY[19], iva3_shcp_PROY[20], iva3_shcp_PROY[21] ]
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
				error: function(request,error) {
					console.log(request);
					console.log("Museo: sin motor Stata detrás (" + error + ")");
				}

			});

	
	
	
	

		/*****************  envio de Pib ************************/	

	$('#pib_crecSub').click(function(){
			var idSession=makeid(); 
			if(getCookie("idSession")!=null) {
				idSession=getCookie("idSession");
			} 
			setCookie("idSession",idSession,1);

			var pib_crec1519 = $('#pib_crec1519').val();
			var pib_crec2024 = $('#pib_crec2024').val();
			var pib_crec2529 = $('#pib_crec2529').val();	
			var pib_crec30plus = $('#pib_crec30plus').val();


			setCookie("idSession",idSession,1);
			
			var data = 'pib_crec1519=' + pib_crec1519 +'&pib_crec2024=' + pib_crec2024 + '&pib_crec2529=' + pib_crec2529 + 
			'&pib_crec30plus=' +pib_crec30plus + '&idSession='+idSession ;
//			alert(data);
			$.ajax({
				//this is the php file that processes the data and send mail
				url: "pib_crecStata.php",	
				
				async:false,
	
				//GET method is used
				type: "GET",
	
				//pass the data			
				data: data,		
				
				//Do not cache the page
				cache: false,
				
				//success
				success: function (html) {	
					alert("Se han actualizado el valor del PIB ");
		
				},
				beforeSend: function () {

				},		
				error: function(request,error) {
					console.log(request);
					console.log("Museo: sin motor Stata detrás (" + error + ")");
				},
				complete:function () {
//					$( ".la-anim-10" ).removeClass('la-animate');
				}

			});
		
		//cancel the submit button default behaviours

		});



		/*****************  envio de deflactor ************************/	

	$('#def_crecSub').click(function(){
			var idSession=makeid(); 
			if(getCookie("idSession")!=null) {
				idSession=getCookie("idSession");
			} 
			setCookie("idSession",idSession,1);

			var def_crec1519 = $('#def_crec1519').val();
			var def_crec2024 = $('#def_crec2024').val();
			var def_crec2529 = $('#def_crec2529').val();	
			var def_crec30plus = $('#def_crec30plus').val();


			setCookie("idSession",idSession,1);
			
			var data = 'def_crec1519=' + def_crec1519 +'&def_crec2024=' + def_crec2024 + '&def_crec2529=' + def_crec2529 + 
			'&def_crec30plus=' +def_crec30plus + '&idSession='+idSession ;
//			alert(data);
			$.ajax({
				//this is the php file that processes the data and send mail
				url: "def_crecStata.php",	
				
				async:false,
	
				//GET method is used
				type: "GET",
	
				//pass the data			
				data: data,		
				
				//Do not cache the page
				cache: false,
				
				//success
				success: function (html) {	
					alert("Se han actualizado el valor del deflactor ");
		
				},
				beforeSend: function () {

				},		
				error: function(request,error) {
					console.log(request);
					console.log("Museo: sin motor Stata detrás (" + error + ")");
				},
				complete:function () {
//					$( ".la-anim-10" ).removeClass('la-animate');
				}

			});
		
		//cancel the submit button default behaviours

		});


		/*****************  envio de inflacion ************************/	

	$('#inf_crecSub').click(function(){
			var idSession=makeid(); 
			if(getCookie("idSession")!=null) {
				idSession=getCookie("idSession");
			} 
			setCookie("idSession",idSession,1);

			var inf_crec1519 = $('#inf_crec1519').val();
			var inf_crec2024 = $('#inf_crec2024').val();
			var inf_crec2529 = $('#inf_crec2529').val();	
			var inf_crec30plus = $('#inf_crec30plus').val();


			setCookie("idSession",idSession,1);
			
			var data = 'inf_crec1519=' + inf_crec1519 +'&inf_crec2024=' + inf_crec2024 + '&inf_crec2529=' + inf_crec2529 + 
			'&inf_crec30plus=' +inf_crec30plus + '&idSession='+idSession ;
//			alert(data);
			$.ajax({
				//this is the php file that processes the data and send mail
				url: "inf_crecStata.php",	
				
				async:false,
	
				//GET method is used
				type: "GET",
	
				//pass the data			
				data: data,		
				
				//Do not cache the page
				cache: false,
				
				//success
				success: function (html) {	
					alert("Se han actualizado el valor de inflacion ");
		
				},
				beforeSend: function () {

				},		
				error: function(request,error) {
					console.log(request);
					console.log("Museo: sin motor Stata detrás (" + error + ")");
				},
				complete:function () {
//					$( ".la-anim-10" ).removeClass('la-animate');
				}

			});
		
		//cancel the submit button default behaviours

		});


		/*****************  envio de crecimiento de salarios ************************/	

	$('#sal_crecSub').click(function(){
			var idSession=makeid(); 
			if(getCookie("idSession")!=null) {
				idSession=getCookie("idSession");
			} 
			setCookie("idSession",idSession,1);

			var sal_crec1519 = $('#sal_crec1519').val();
			var sal_crec2024 = $('#sal_crec2024').val();
			var sal_crec2529 = $('#sal_crec2529').val();	
			var sal_crec30plus = $('#sal_crec30plus').val();


			setCookie("idSession",idSession,1);
			
			var data = 'sal_crec1519=' + sal_crec1519 +'&sal_crec2024=' + sal_crec2024 + '&sal_crec2529=' + sal_crec2529 + 
			'&sal_crec30plus=' +sal_crec30plus + '&idSession='+idSession ;
//			alert(data);
			$.ajax({
				//this is the php file that processes the data and send mail
				url: "sal_crecStata.php",	
				
				async:false,
	
				//GET method is used
				type: "GET",
	
				//pass the data			
				data: data,		
				
				//Do not cache the page
				cache: false,
				
				//success
				success: function (html) {	
					alert("Se han actualizado el valor de salarios ");
		
				},
				beforeSend: function () {

				},		
				error: function(request,error) {
					console.log(request);
					console.log("Museo: sin motor Stata detrás (" + error + ")");
				},
				complete:function () {
//					$( ".la-anim-10" ).removeClass('la-animate');
				}

			});
		
		//cancel the submit button default behaviours

		});


		/*****************  envio de tipo de cambio ************************/	

	$('#tcSub').click(function(){
			var idSession=makeid(); 
			if(getCookie("idSession")!=null) {
				idSession=getCookie("idSession");
			} 
			setCookie("idSession",idSession,1);

			var tc1519 = $('#tc1519').val();
			var tc2024 = $('#tc2024').val();
			var tc2529 = $('#tc2529').val();	
			var tc30plus = $('#tc30plus').val();


			setCookie("idSession",idSession,1);
			
			var data = 'tc1519=' + tc1519 +'&tc2024=' + tc2024 + '&tc2529=' + tc2529 + 
			'&tc30plus=' +tc30plus + '&idSession='+idSession ;
//			alert(data);
			$.ajax({
				//this is the php file that processes the data and send mail
				url: "tcStata.php",	
				
				async:false,
	
				//GET method is used
				type: "GET",
	
				//pass the data			
				data: data,		
				
				//Do not cache the page
				cache: false,
				
				//success
				success: function (html) {	
					alert("Se han actualizado el valor del tipo de cambio ");
		
				},
				beforeSend: function () {

				},		
				error: function(request,error) {
					console.log(request);
					console.log("Museo: sin motor Stata detrás (" + error + ")");
				},
				complete:function () {
//					$( ".la-anim-10" ).removeClass('la-animate');
				}

			});
		
		//cancel the submit button default behaviours

		});


});	

