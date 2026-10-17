var chart0			= null;
//var chartPIB2  		= null;
var chartline1 		= null;
var chartstacked1 	= null;
var chartstacked2 	= null;
var chartarea2 		= null;
var chartduopt1 	= null;
var chartduopt2 	= null;
var cambioISR		= 0;
var cambioIVA		= 0;
var PIBY			= 38000000000000.0;  // PIB en pesos (se actualiza desde output.txt)

// Variables para almacenar datos default (2027) y simulación
var datosDefault = null;
var datosSimulacion = null;

// Variables para almacenar datos Sankey (default y simulación)
var sankeyDefaultData = {};
var sankeySimulacionData = {};
var haySimulacion = false;

// Función para actualizar una sección con los datos seleccionados
function actualizarSeccion(section, datos) {
	switch(section) {
		case 'tablaINCD':
			// Actualizar tabla de aportaciones por hogar
			$(".valINCD").each(function(index, element) {
				$(this).html(formatoMexico(datos.INCD[index]));
			});
			$(".valINCD2").each(function(index, element) {
				$(this).html(formatoMexico(datos.INCD2[index]));
			});
			$(".valINCD3").each(function(index, element) {
				$(this).html(formatoMexico(datos.INCD3[index]));
			});
			break;
			
		case 'chartDuo':
			// Actualizar gráficas de carga fiscal por edades (pirámide)
			if(chartduopt1 && datos.APORTHIV) {
				chartduopt1.updateSeries([
					{ name: 'Deciles I-V', data: datos.APORTHIV },
					{ name: 'VI-IX', data: datos.APORTHVIIX },
					{ name: 'X', data: datos.APORTHX }
				], false);
			}
			if(chartduopt2 && datos.APORTMIV) {
				chartduopt2.updateSeries([
					{ name: 'Deciles I-V', data: datos.APORTMIV },
					{ name: 'VI-IX', data: datos.APORTMVIIX },
					{ name: 'X', data: datos.APORTMX }
				], false);
			}
			break;
			
		case 'line1':
			// Actualizar gráfica del bono fiscal
			if(chartline1 && datos.PROY) {
				chartline1.updateSeries([{
					name: 'Aportaciones netas',
					data: datos.PROY
				}], false);
			}
			break;
			
		case 'stacked1':
			// Actualizar gráfica de proyección de recursos (ingresos)
			if(chartstacked1 && datos.PROYLABOR) {
				chartstacked1.updateSeries([{
					name: 'Al trabajo',
					data: datos.PROYLABOR
				}, {
					name: 'Al consumo',
					data: datos.PROYCONSU
				}, {
					name: 'Al capital',
					data: datos.PROYCAPIT
				}, {
					name: 'OyE públicas',
					data: datos.PROYORGAN
				}], false);
			}
			break;
			
		case 'stacked2':
			// Actualizar gráfica de proyección de compromisos (gastos)
			if(chartstacked2 && datos.PROYEDUCA) {
				chartstacked2.updateSeries([{
					name: 'Educación',
					data: datos.PROYEDUCA
				}, {
					name: 'Pensiones',
					data: datos.PROYPENSI
				}, {
					name: 'Salud',
					data: datos.PROYSALUD
				}, {
					name: 'Otros',
					data: datos.PROYOTROS
				}, {
					name: 'Energía',
					data: datos.PROYENERG
				}, {
					name: 'Inversión',
					data: datos.PROYINVER
				}, {
					name: 'Costo deuda',
					data: datos.PROYCOSTO
				}], false);
			}
			break;
			
		case 'area2':
			// Actualizar gráfica de sostenibilidad fiscal (deuda)
			if(chartarea2 && datos.PROYSHRFSP1) {
				chartarea2.updateSeries([{
					name: 'Reportado',
					data: datos.PROYSHRFSP1
				}, {
					name: 'Proyectado',
					data: datos.PROYSHRFSP2
				}], false); // false = no animar para evitar refresh visual
			}
			break;
			
		case 'sankey':
			// Los diagramas Sankey requieren recarga completa vía AJAX
			// Usar 'ciepmx' para default y el idSession del usuario para simulación
			var isDefault = (datos === datosDefault);
			var sessionToUse = isDefault ? 'ciepmx' : $("#idSession").val();
			
			// Lista de Sankeys a actualizar
			var sankeyConfigs = [
				{ id: 'sankey-1-chart', renderAt: 'sankey-1', url: 'jsonSankey.php' },
				{ id: 'sankey-2-chart', renderAt: 'sankey-2', url: 'jsonSankeyGrupoedad.php' },
				{ id: 'sankey-3-chart', renderAt: 'sankey-3', url: 'jsonSankeyEscol.php' },
				{ id: 'sankey-4-chart', renderAt: 'sankey-4', url: 'jsonSankeyRural.php' },
				{ id: 'sankey-5-chart', renderAt: 'sankey-5', url: 'jsonSankeySexo.php' }
			];
			
			// Recargar cada Sankey
			sankeyConfigs.forEach(function(config) {
				if(isDefault && sankeyDefaultData[config.renderAt]) {
					// Usar datos guardados para default
					var chart = FusionCharts.items[config.id];
					if(chart) {
						chart.setJSONData(sankeyDefaultData[config.renderAt]);
					}
				} else {
					// Cargar desde servidor para simulación
					$.ajax({
						type: 'post',
						url: config.url,
						data: { 'idSession': sessionToUse },
						success: function(dataSource) {
							var chart = FusionCharts.items[config.id];
							if(chart) {
								chart.setJSONData(dataSource);
							}
						}
					});
				}
			});
			break;
	}
}



function formatoMoneda(valor, porcentaje=100, minDig=0, maxDig=1) {
  return  Number(valor*porcentaje).toLocaleString('es-MX',{maximumFractionDigits:maxDig,minimumFractionDigits:minDig});;
}
const formatoMexico = (number) => {
  const exp = /(\d)(?=(\d{3})+(?!\d))/g;
  const rep = '$1,';
  let arr = number.toString().split('.');
  arr[0] = arr[0].replace(exp,rep);
  return arr[1] ? arr.join('.'): arr[0];
}



$(document).ready(function() {


	$('.CSSIMSS').on( "change", function() {
		$('#moduloCambio').val(1);
	});

	$('.CSSISSSTE').on( "change", function() {
		$('#moduloCambio').val(1);
	});

	$('.ISRSUBS').on( "change", function() {
		$('#moduloCambio').val(1);
	});
	$('.IVA').on( "change", function() {
		$('#moduloCambio').val(1);
	});

	$('.IVAT').on( "change", function() {
		$('#moduloCambioIva').val(1);
	});

	$('.ISRDEDU').on( "change", function() {
		$('#moduloCambio').val(1);
	});

	$('.ISRMORA').on( "change", function() {
		$('#moduloCambio').val(1);
	});



	$("#ISRsalarios").click(function() {
		$(".tabla2").show();
		$(".tabla3").hide();
		$("#tabla-inter-1").removeClass( "col-sm-12" );
		$("#Modal-ISR-1 .modal-dialog").removeClass( "modal-lg" );
		$("#Modal-ISR-1 .modal-content").removeClass( "modal-lg" );
	});
	$("#ISRfisicas").click(function() {
		$(".tabla2").hide();
		$(".tabla3").show();
		$("#tabla-inter-1").addClass( "col-sm-12" );
		$("#Modal-ISR-1 .modal-dialog").addClass( "modal-lg" );
		$("#Modal-ISR-1 .modal-content").addClass( "modal-lg" );
	});

	$(".IVA,  .ISRSUBS, .ISRDEDU,.ISRMORA").change(function() {
		cambioISR=1;
	});
	$(".IVAT ").change(function() {
		cambioIVA=1;
	});

	$( ".form-control" ).change(function() {
		$( "#box-actualizar" ).addClass( "slide-top" );
	});
	$( ".cerrar-actualizar" ).click(function() {
		$( "#box-actualizar" ).removeClass( "slide-top" );
		$("#Modal-cuotas-imss").modal('hide');
//				$( "#Modal-cuotas-imss" ).hide();

	});

//	$( "#btn-actualizar, #btn-reestablecer" ).click(function() {
//		$( ".table" ).addClass( "blink-1" );
//	  	setTimeout(function() { 
//			$(".table").removeClass( "blink-1" );
//		}, 1500);
//	});
	
	$( "#btn-reestablecer" ).click(function() {
		location.href = 'index.php';		
//	  	$( "#ampliar" ).addClass( "opacity1" );
	});		

	// Event handlers para botones de per cápita
	// v8.2.0: conteos de población/derechohabientes desde el motor (GASTOSPOB).
	// Sobreescribe la columna visible (.pob-value) y los data-pop de los
	// botones ± en cada carga; los números del HTML son solo placeholder
	// (snapshot del motor al momento del deploy). Índices espejo de GASTOSPC.
	var POBIDX = {
		iniciaA:0, basica:1, medsup:2, superi:3, posgra:4, eduadu:5,
		otrose:6, invere:7, cultur:8, invest:9, totEducac:10,
		ssa:11, imssbien:12, imss:13, issste:14, pemex:15, issfam:16,
		invers:17, totSalud:18,
		bienestar:19, penims:20, peniss:21, penpeme:22, penotr:23, totPension:24,
		gascfe:25, gaspemex:26, gassener:27, gasinverf:28, gascosdeue:29, totEnergia:30,
		gasinfra:31, gasotros:32, gasfeder:33, gascosto:34, totOtros:35,
		IngBas:36, gasmadres:39, gascuidados:40, totTransf:41
	};
	window.poblarConteos = function(datos) {
		// Guard: motor viejo sin GASTOSPOB -> quedan los placeholders del HTML
		if(!datos || !datos.GASTOSPOB1 || !datos.GASTOSPOB2) return;
		var POB = datos.GASTOSPOB1.concat(datos.GASTOSPOB2);
		$('.pob-value').each(function() {
			var i = POBIDX[$(this).data('target')];
			if(i === undefined) return;
			var v = parseFloat(POB[i]);
			if(!isFinite(v) || v <= 0) return;
			$(this).text(formatoMexico(Math.round(v)));
		});
		$('.btn-percapita').each(function() {
			var i = POBIDX[$(this).data('target')];
			if(i === undefined) return;
			var v = parseFloat(POB[i]);
			if(!isFinite(v) || v <= 0) return;
			// attr + data: .data() es lo que lee el click handler (cache jQuery)
			$(this).attr('data-pop', v).data('pop', v);
		});
	};

	$('.btn-percapita').click(function() {
		var targetId = $(this).data('target');  // ID del input de % PIB
		var poblacion = parseFloat($(this).data('pop'));  // Población
		var percapitaSpan = $(this).siblings('.percapita-value');  // Span del per cápita
		
		// Obtener el per cápita actual (remover comas y convertir a número)
		var percapitaActual = parseFloat(percapitaSpan.text().replace(/,/g, '')) || 0;
		
		// Incremento: 1000 pesos por click
		var incremento = 1000;
		
		// Aumentar o disminuir según el botón
		if($(this).hasClass('btn-up')) {
			percapitaActual += incremento;
		} else {
			percapitaActual = Math.max(0, percapitaActual - incremento);  // No permitir negativos
		}
		
		// Calcular el nuevo % PIB: (per cápita × población) / PIB × 100
		var nuevoPorcentajePIB = (percapitaActual * poblacion) / PIBY * 100;
		
		// Actualizar el input de % PIB
		$('#' + targetId).val(nuevoPorcentajePIB.toFixed(3));
		
		// Actualizar el span del per cápita con formato
		percapitaSpan.text(formatoMexico(Math.round(percapitaActual)));
		
		// Marcar que hubo cambios
		$( "#box-actualizar" ).addClass( "slide-top" );
	});

	// Event handlers para botones de tasa efectiva
	$('.btn-tasa').click(function() {
		var targetId = $(this).data('target');  // ID del input de % PIB (ej: INGRESOS0)
		var baseGravable = parseFloat($(this).data('base'));  // Cuenta gravable (% PIB)
		var tasaSpan = $(this).siblings('.tasa-value');  // Span de la tasa efectiva
		
		// Obtener la tasa efectiva actual
		var tasaActual = parseFloat(tasaSpan.text()) || 0;
		
		// Incremento: 0.1% por click
		var incremento = 0.1;
		
		// Aumentar o disminuir según el botón
		if($(this).hasClass('btn-up')) {
			tasaActual += incremento;
		} else {
			tasaActual = Math.max(0, tasaActual - incremento);  // No permitir negativos
		}
		
		// Calcular el nuevo % PIB: tasa efectiva × cuenta gravable / 100
		var nuevoPorcentajePIB = (tasaActual * baseGravable) / 100;
		
		// Actualizar el input de % PIB
		$('#' + targetId).val(nuevoPorcentajePIB.toFixed(3));
		
		// Actualizar el span de la tasa efectiva
		tasaSpan.text(tasaActual.toFixed(1));
		
		// Marcar que hubo cambios
		$( "#box-actualizar" ).addClass( "slide-top" );
	});

	// Event handlers para botones de marco macro
	$('.btn-macro').click(function() {
		var targetId = $(this).data('target');  // ID del input (ej: CRECPIB2025)
		var input = $('#' + targetId);
		
		// Obtener el valor actual
		var valorActual = parseFloat(input.val()) || 0;
		
		// Incremento: 100 para subsidio al empleo (SE), 1 para otros
		var incremento = 1;
		if(targetId.match(/^SE\d+$/)) {
			incremento = 100;  // Subsidio al empleo en pesos
		}
		
		// Aumentar o disminuir según el botón
		if($(this).hasClass('btn-up')) {
			valorActual += incremento;
		} else {
			valorActual = Math.max(-10, valorActual - incremento);  // Permitir valores negativos hasta -10
		}
		
		// Actualizar el input con formato de 2 decimales
		input.val(valorActual.toFixed(2));
		
		// Disparar evento change para activar listeners (moduloCambio, moduloCambioIva, etc.)
		input.trigger('change');
		
		// Marcar que hubo cambios
		$( "#box-actualizar" ).addClass( "slide-top" );
	});

/*Aqui va el ajax para cargar los valores de default con el php
*/
	
   	$.ajax({
        async: true,
        type: 'post',
        url: 'cargaDefault.php',
        data: {
        },
		beforeSend:function () {
			$('.cargando').show();
		},
        success: function (datos) {
			// Guardar datos default (2027) para toggle
			datosDefault = JSON.parse(JSON.stringify(datos));
			
			// Guardar PIBY para cálculos de per cápita
			if(datos.PIBY) {
				PIBY = parseFloat(datos.PIBY);
			}
			
			var GASTOSTOTAL =parseFloat(datos.GASTOS[40]) ;
			var INGRESOSTOTAL =parseFloat(datos.INGRESOS[19]);
			var DEUDA = INGRESOSTOTAL -GASTOSTOTAL;
			if(DEUDA >=0 )  {
				$(".idDeuda").parent().parent().addClass("positivo");
				$(".idDeuda").addClass("txt-ingresos");
				$(".idDeuda").removeClass("txt-gastos");
			} else {
				$(".idDeuda").parent().parent().removeClass("positivo");
				$(".idDeuda").addClass("txt-gastos");
				$(".idDeuda").removeClass("txt-ingresos");
			}
			$(".GASTOSTOTAL").html(GASTOSTOTAL);
			$(".INGRESOSTOTAL").html(INGRESOSTOTAL);
			$(".DEUDA").html(formatoMoneda(DEUDA,1,0,3));


			$("#DEUDA0").val(formatoMoneda(datos.DEUDAPARAM[0],1,0,3));
			$("#DEUDA1").val(formatoMoneda(datos.DEUDAPARAM[1],1,0,3));
			$("#DEUDA2").val(formatoMoneda(datos.DEUDAPARAM[2],1,0,3));
			//				$("#PROYMAX").html(datos.PROYMAX);

			if(datos.PROYSHRFSP1[parseInt(datos.ANIOBASE)-2013] > datos.PROYSHRFSP2[datos.PROYSHRFSP2.length-1]) {
				$("#textPROYSHRFSP").addClass("alert-secondary");
				$("#textPROYSHRFSP").removeClass("alert-danger");
				$("#textPROYSHRFSP").html('<p>Al ' + (datos.ANIOEND || 2032) + ', el indicador de la deuda sería menor que en ' + datos.ANIOBASE + '.</p>');
			}else {
				$("#textPROYSHRFSP").removeClass("alert-secondary");
				$("#textPROYSHRFSP").addClass("alert-danger");
				$("#textPROYSHRFSP").html('<span class="material-icons">warning</span><p>Al ' + (datos.ANIOEND || 2032) + ', el indicador de la deuda sería mayor que en ' + datos.ANIOBASE + '.</p>');
			}

			var PROYMAX =parseFloat(datos.PROYMAX) ;
			if(PROYMAX>2049) {
				$("#PROYMAX").parent().parent().addClass("alert-warning");
				$("#PROYMAX").parent().parent().removeClass("alert-danger");
				$("#PROYMAX").parent().parent().html("Las Aportaciones Netas no disminuirían, al menos, hasta el 2050.");
			} else {
				$("#PROYMAX").parent().parent().addClass("alert-danger");
				$("#PROYMAX").parent().parent().removeClass("alert-warning");
				$("#PROYMAX").parent().parent().html('<span class="material-icons">warning</span><p>A partir del <span id="PROYMAX">'+ PROYMAX +'</span>, las <b>Aportaciones Netas</b> comienzan a DISMINUIR</p>');
			}
			
/*			t=0;
			for (var i = 0; i < 10; i++) { //10
				t += datos.GASTOSPC[i];
			}
			$(".INPUTSGTotalEducacion").val(t);
			
			t=0;
			for (var i = 11; i < 17; i++) { //7
				t += datos.GASTOSPC[i];
			}
			$(".INPUTSGTotalSalud").val(t);

			t=0;
			for (var i = 19; i < 23; i++) { // 5
				t += datos.GASTOSPC[i];
			}
			$(".INPUTSGTotalPension").val(t);

			t=0;
			for (var i = 25; i < 29; i++) {//5
				t += datos.GASTOSPC[i];
			}
			$(".INPUTSGTotalEnergia").val(t);

			t=0;
			for (var i = 27; i < 32; i++) {//5
				t += datos.GASTOSPC[i];
			}
			
			$(".INPUTSGTotalOtrosgastos").val(t);

			t=0;
			for (var i = 32; i < 35; i++) {//3
				t += datos.GASTOSPC[i];
			}
			$(".INPUTSGTotalIngresobasico").val(t);
		*/
			$(".IVA").each(function(index, element) {
                $( this ).html(datos.ISRTASA[index]);
            });
			
			$(".CSSIMSS").each(function(index, element) {
                $( this ).val(datos.CSSIMSS[index]);
            });
			$(".CSSISSSTE").each(function(index, element) {
                $( this ).val(datos.CSSISSSTE[index]);
            });
							
			$(".ISRCUFI").each(function(index, element) {
                $( this ).html(formatoMexico(datos.ISRCUFI[index]));
            });
				
			$(".valINCD").each(function(index, element) {
                $( this ).html(formatoMexico(datos.INCD[index]));
            });
			$(".valINCD2").each(function(index, element) {
                $( this ).html(formatoMexico(datos.INCD2[index]));
            });
			$(".valINCD3").each(function(index, element) {
                $( this ).html(formatoMexico(datos.INCD3[index]));
            });
			$(".INGRESOS").each(function(index, element) {
				switch (index) {
					case 6:
						$( this ).val(datos.INGRESOS[15]);
						break;
					case 7:
						$( this ).val(datos.INGRESOS[6]);
						break;
					case 8:
						$( this ).val(datos.INGRESOS[7]);
						break;
					case 9:
						$( this ).val(datos.INGRESOS[8]);
						break;
					case 10:
						$( this ).val(datos.INGRESOS[9]);
						break;
					case 11:
						$( this ).val(datos.INGRESOS[10]);
						break;
					case 12:
						$( this ).val(datos.INGRESOS[11]);
						break;
					case 13:
						$( this ).val(datos.INGRESOS[12]);
						break;
					case 14:
						$( this ).val(datos.INGRESOS[13]);
						break;
					case 15:
						$( this ).val(datos.INGRESOS[14]);
						break;
					case 16:
						$( this ).val(datos.INGRESOS[17]);  // DOM index 16 = CFE (id=INGRESOS17)
						break;
					case 17:
						$( this ).val(datos.INGRESOS[16]);  // DOM index 17 = Pemex (id=INGRESOS16)
						break;
					default:
						$( this ).val(datos.INGRESOS[index]);        
				}
            });

			$(".GASTOS").each(function(index, element) {
                $( this ).val(datos.GASTOS[index]);
            });

			$(".INGRESOSTEF").each(function(index, element) {
				switch (index) {
					case 6:
						$( this ).html(datos.INGRESOSTEF[15]);
						break;
					case 7:
						$( this ).val(datos.INGRESOSTEF[6]);
						break;
					case 8:
						$( this ).html(datos.INGRESOSTEF[7]);
						break;
					case 9:
						$( this ).html(datos.INGRESOSTEF[8]);
						break;
					case 10:
						$( this ).html(datos.INGRESOSTEF[9]);
						break;
					case 11:
						$( this ).html(datos.INGRESOSTEF[10]);
						break;
					case 12:
						$( this ).html(datos.INGRESOSTEF[11]);
						break;
					case 13:
						if(index == 13)
							$( this ).val(datos.INGRESOSTEF[12]);
						$( this ).html(datos.INGRESOSTEF[12]);
						break;
					case 14:
						$( this ).html(datos.INGRESOSTEF[13]);
						break;
					case 15:
						$( this ).html(datos.INGRESOSTEF[14]);
						break;
					case 16:
						$( this ).html(datos.INGRESOSTEF[17]);  // DOM index 16 = CFE (id=INGRESOSTEF17)
						break;
					case 17:
						$( this ).html(datos.INGRESOSTEF[16]);  // DOM index 17 = Pemex (id=INGRESOSTEF16)
						break;
					case 18:
						$( this ).val(datos.INGRESOSTEF[18]);
						break;
					default:
						if(index == 3)
							$( this ).val(datos.INGRESOSTEF[index]);
						$( this ).html(datos.INGRESOSTEF[index]);				
//						$( this ).val(datos.INGRESOSTEF[index]);        
				}
            });

//			$(".INPUTSI").each(function(index, element) {
//                $( this ).val(datos.INGRESOSTEF[index]);        
//            });
//			$(".INPUTSG").each(function(index, element) {
  //              $( this ).val(datos.GASTOSPC[index]);        
//            });
			$(".INPUTSG").each(function(index, element) {
				switch(index) {
				case 38:
					$("#ingbasico18").attr('checked', datos.GASTOSPC[index]);
					break;
				case 39:
					$("#ingbasico65").attr('checked', datos.GASTOSPC[index]);
					break;
				default:
					$( this ).html(formatoMexico(Math.round(datos.GASTOSPC[index])));
				
				}
			});
			poblarConteos(datos);
			$(".CRECPIB").each(function(index, element) {
				$( this ).val(datos.CRECPIB[index]);
			});
			$(".CRECDEF").each(function(index, element) {
				$( this ).val(datos.CRECDEF[index]);
			});
			$(".ISRSUBS").each(function(index, element) {
				$( this ).val(datos.ISRSUBS[index]);
			});

			$(".ISRDEDU").each(function(index, element) {
				$( this ).val(datos.ISRDEDU[index]);
			});
			
			$(".ISRMORA").each(function(index, element) {
				$( this ).val(datos.ISRMORA[index]);
			});
	
			for(var index=0; index<=12;index++) {
				if(index==0 || index ==12) {
					$("#IVAT"+index).val(datos.IVA[index]);
				} else {
					var v=parseInt(datos.IVA[index]);
					switch (v) {
				  		case 1:
							$("#IVAT"+index+"a").attr('checked', true);
					    	break;
  						case 2:
							$("#IVAT"+index+"b").attr('checked', true);
					    	break;
  						default:
							$("#IVAT"+index+"c").attr('checked', true);
					}
					
				}
				
			}
/*
			$(".IVAT").each(function(index, element) {
				if(index==0 || index==12 ) {
					$( this ).val(datos.IVA[index]);
				} else {
					var v=parseInt(datos.IVA[index]);
					$("#IVAT"+v+"a").attr('checked', true);
				}
			});
	*/
  			$(".PROYSHRFSP3").each(function(index, element) {
				$( this ).html(formatoMexico(datos.PROYSHRFSP3[index]));
			});


			
		/****************** Carga valores iniciales	Producto Interno Bruto   *******************
			var options = {
            chart: {
				toolbar: {
					show: true,
					offsetX: 200,
					offsetY: 0,
					export: {
					  csv: {
						filename: undefined,
						columnDelimiter: ',',
						headerCategory: 'category',
						headerValue: 'value',
						dateFormatter(timestamp) {
						  return new Date(timestamp).toDateString()
						}
					  }
					},
				},
                height: 430,
                type: 'area',
				zoom: {
                    enabled: false
                }
            },
			legend: {
				position: 'top',
				horizontalAlign: 'left',
				fontSize: '15px',
				offsetX: -2,
				offsetY: -5,
				markers: {
				  width: 14,
				  height: 14,
				  radius: 14
				},
				itemMargin: {
					horizontal: 5
				}
			},
			annotations: {
			  xaxis: [
				{
				  x: 12,
				  strokeDashArray: 0,
				  borderColor: '#775DD0',
				  label: {
					  borderColor: '#775DD0',
					  style: {
						color: '#fff',
						background: '#775DD0',
					  },
					  text: 'HOY',
				  }
				}
			  ]
			},
            dataLabels: {
                enabled: false
            },
            stroke: {
                curve: 'smooth'
            },

            series: [{
				name: 'PIB Reportado',
				data: datos.Reportado
			}, {
				name: 'PIB Simulado',
				data:  datos.Estimado
            }],
             xaxis: {
                categories: [2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030],
                labels: {
			      rotate: -45,
                  rotateAlways: true,
                  style: {
                    colors: 'rgba(94, 96, 110, .9)'
                  }
                }           
            },
        yaxis: {
          title: {
            text: 'billones MXN de 2021',
          },
        },
			title: {
				text: ' ',
			},  grid: {
              borderColor: 'rgba(94, 96, 110, .5)',
              strokeDashArray: 4
            }
,
  noData: {
    text: 'Loading...'
  }
}
			 chartPIB2 = new ApexCharts(
			  document.querySelector("#pib-2"),
			  options
			);

			chartPIB2.render();
		/****************** Fin de carga valores iniciales	Producto Interno Bruto   *******************/
		/****************** Carga valores iniciales	Proyección de las aportaciones netas  *******************/

		var options = {
            chart: {
                height: 380,
                type: 'line',
                zoom: {
                    enabled: false
                }
            },
            series: [{
                name: "Aportaciones netas",
                data: datos.PROY
            }],
			annotations: {
			  xaxis: [
				{
				  x: 4.2,
				  strokeDashArray: 0,
				  borderColor: '#775DD0',
				  label: {
					  borderColor: '#775DD0',
					  style: {
						color: '#fff',
						background: '#775DD0',
					  },
					  text: 'HOY',
				  }
				}
			  ]
			},
            dataLabels: {
                enabled: false
            },
            stroke: {
                curve: 'smooth'
            },
            grid: {
                borderColor: 'rgba(94, 96, 110, .5)',
                strokeDashArray: 4
            },
            xaxis: {
                categories: [2010, 2015, 2020, 2025, 2030, 2035, 2040, 2045, 2050, 2055, 2060, 2065, 2070],
                labels: {
                  style: {
                    colors: 'rgba(94, 96, 110, 1.0)'
                  }
                }
            },
        yaxis: {
          title: {
            text: 'billones MXN de 2027',
          },
          min: -1,
          max: 3
        },
        tooltip: {
		  inverseOrder: true,
          x: {
            format: 'dd/MM/yy HH:mm'
          },
          y: {
            formatter: function (val) {
              return Math.abs(val)
            }

          }
        }
        }

        chartline1 = new ApexCharts(
            document.querySelector("#line-1"),
            options
        );

        chartline1.render();	
			/****************** Fin de carga valores iniciales Proyección de las aportaciones netas   *******************/
		/****************** Carga valores iniciales	Ingresos presupuestarios  *******************/

		var options = {
          series: [{
			  name: 'Al trabajo',
			  data:  datos.PROYLABOR
			}, {
			  name: 'Al consumo',
			  data:  datos.PROYCONSU
			}, {
			  name: 'Al capital',
			  data:  datos.PROYCAPIT 
			}, {
			  name: 'OyE públicas',
			  data:  datos.PROYORGAN
		  }],
          chart: {
	      stacked: true,
          height: 390,
          type: 'area'
        },
		legend: {
				position: 'top',
				horizontalAlign: 'left',
				fontSize: '15px',
				offsetX: -2,
				offsetY: -5,
				markers: {
				  width: 14,
				  height: 14,
				  offsetX: 20,
				  radius: 14
				},
				itemMargin: {
					horizontal: 15
				}
		},
		annotations: {
			  xaxis: [
				{
				  x: 14,
				  strokeDashArray: 0,
				  borderColor: '#775DD0',
				  label: {
					  borderColor: '#775DD0',
					  style: {
						color: '#fff',
						background: '#775DD0',
					  },
					  text: 'HOY',
				  }
				}
			  ]
		},
        dataLabels: {
          enabled: false
        },
        stroke: {
          curve: 'smooth'
        },
        xaxis: {
                categories: [2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030, 2031, 2032],
				labels: {
					rotate: -45,
                    rotateAlways: true
                } 
        },
        yaxis: {
          title: {
            text: 'billones MXN de 2024',
          },
        },
        tooltip: {
		  inverseOrder: true,
          x: {
            format: 'dd/MM/yy HH:mm'
          },
          y: {
            formatter: function (val) {
              return Math.abs(val)
            }
          }
        },
        };

        chartstacked1 = new ApexCharts(document.querySelector("#stacked1"), options);
        chartstacked1.render();
	
		
		/****************** Fin de carga valores iniciales Ingresos presupuestarios   *******************/
		/****************** Carga valores iniciales	Gasto público  *******************/


		var options = {
          series: [{			  
			  name: 'Educación',
			  data:  datos.PROYEDUCA
			}, {
			  name: 'Pensiones',
			  data:  datos.PROYPENSI
			}, {
			  name: 'Salud',
			  data:  datos.PROYSALUD
			}, {
			  name: 'Otros',
			  data:  datos.PROYOTROS
			}, {
			  name: 'Energía',
			  data:  datos.PROYENERG
			}, {
			  name: 'Inversión',
			  data:  datos.PROYINVER  
			}, {
			  name: 'Costo deuda',
			  data:  datos.PROYCOSTO 
				},],
          chart: {
	      stacked: true,
          height: 400,
          type: 'area'
        },
		colors: ['#7c8d8e', '#344a7b', '#cf0b0b', '#f97c11', '#ffcb01', '#9b43bd', '#269aea', '#11d463'],
		legend: {
				position: 'top',
				horizontalAlign: 'left',
				fontSize: '15px',
				offsetX: -2,
				offsetY: -5,
				markers: {
				  width: 14,
				  height: 14,
				  radius: 14
				},
				itemMargin: {
					horizontal: 5
				}
		},
		annotations: {
			  xaxis: [
				{
				  x: 14,
				  strokeDashArray: 0,
				  borderColor: '#775DD0',
				  label: {
					  borderColor: '#775DD0',
					  style: {
						color: '#fff',
						background: '#775DD0',
					  },
					  text: 'HOY',
				  }
				}
			  ]
		},
        dataLabels: {
          enabled: false
        },
        stroke: {
          curve: 'smooth', 
        },
        xaxis: {
                categories: [2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030, 2031, 2032],
				labels: {
					rotate: -45,
                    rotateAlways: true
                } 
        },
        yaxis: {
          title: {
            text: 'billones MXN de 2024',
          },
        },
        tooltip: {
		  inverseOrder: true,
          x: {
            format: 'dd/MM/yy HH:mm'
          },
          y: {
            formatter: function (val) {
              return Math.abs(val)
            }
          }
        },
        };

        chartstacked2 = new ApexCharts(document.querySelector("#stacked2"), options);
        chartstacked2.render();
	
		/****************** Fin de carga valores iniciales Gasto público   *******************/

		var options = {
          series: [{
          name: 'Reportado',
          data: datos.PROYSHRFSP1
        }, {
          name: 'Proyectado',
          data: datos.PROYSHRFSP2
        }],
          chart: {
          height: 380,
          type: 'area'
        },
		legend: {
				position: 'top',
				horizontalAlign: 'left',
				fontSize: '15px',
				offsetX: -2,
				offsetY: -5,
				markers: {
				  width: 14,
				  height: 14,
				  radius: 14
				},
				itemMargin: {
					horizontal: 5
				}
		},
		annotations: {
			  xaxis: [
				{
				  x: 14,
				  strokeDashArray: 0,
				  borderColor: '#775DD0',
				  label: {
					  borderColor: '#775DD0',
					  style: {
						color: '#fff',
						background: '#775DD0',
					  },
					  text: 'HOY',
				  }
				}
			  ]
		},
        dataLabels: {
          enabled: false
        },
        stroke: {
          curve: 'smooth'
        },
        xaxis: {
                categories: [2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030, 2031, 2032],
				labels: {
					rotate: -45,
                    rotateAlways: true
                }  
        },
        yaxis: {
          title: {
            text: '% PIB',
          },
          min: 30,
          max: 100
        },
        };

        chartarea2 = new ApexCharts(document.querySelector("#area2"), options);
        chartarea2.render();
	
		/****************** Fin de carga valores iniciales Proyección de la deuda   *******************/
		/****************** Carga valores iniciales Aportaciones netas *******************/

		var options = {
          series: [
	{
        name: 'Deciles I-V',
          data: datos.APORTHIV
        },	{
          name: 'VI-IX',
          data: datos.APORTHVIIX
        },  {
          name: 'X',
          data: datos.APORTHX
        }
        ],
          chart: {
          type: 'bar',
		  fontFamily: 'Roboto Mono, monospace',
          height: 440,
          width: '100%',
          stacked: true,
          animations: {
            enabled: false
          }
        },
        plotOptions: {
          bar: {
            horizontal: true,
            barHeight: '80%',
        
          },
        },
        dataLabels: {
          enabled: false
        },
        stroke: {
          width: 1,
          colors: ["#fff"]
        },
        
        grid: {
          xaxis: {
            lines: {
              show: false
            }
          }
        },
        yaxis: {
          min: -30,
          max: 40,
		  stepSize: 10,
          title: {
            text: 'Edades',
          },
        },
        tooltip: {
          shared: false,
          x: {
            formatter: function (val) {
              return val
            }
          },
          y: {
            formatter: function (val) {
              return Math.abs(val) + " MXN"
            }
          }
        },
        xaxis: {
          categories: ['105-109','100-104','95-99','90-94','85-89', '80-84', '75-79', '70-74', '65-69', '60-64', '55-59', '50-54',
            '45-49', '40-44', '35-39', '30-34', '25-29', '20-24', '15-19', '10-14', '5-9', '0-4'
          ],
		  labels: {
			      style: {
					  colors: '#404040',
					  fontSize: '10px'
				  },
          }, 
          title: {
            text: 'Perfil de HOMBRES'
          },

        },
        };


        chartduopt1 = new ApexCharts(document.querySelector("#chart-duo-pt1"), options);
        chartduopt1.render();
		
		var options = {
          series: [{
           name: 'Deciles I-V',
          data: datos.APORTMIV
        },	{
          name: 'VI-IX',
          data: datos.APORTMVIIX
        },  {
          name: 'X',
          data: datos.APORTMX
        }
        ],
          chart: {
          type: 'bar',
		  fontFamily: 'Roboto Mono, monospace',
          height: 440,
          width: '100%',
          stacked: true,
          animations: {
            enabled: false
          }
        },
        plotOptions: {
          bar: {
            horizontal: true,
            barHeight: '80%',
			dataLabels: {
              position: 'top', // top, center, bottom
            },
          },
        },
        dataLabels: {
          enabled: false
        },
        stroke: {
          width: 1,
          colors: ["#fff"]
        },
        
        grid: {
          xaxis: {
            lines: {
              show: false
            }
          }
        },
        yaxis: {
          min: -30,
          max: 40,
		  stepSize: 10,
          title: {
            //text: 'Age',
          },
        },
        tooltip: {
          shared: false,
          x: {
            formatter: function (val) {
              return val
            }
          },
          y: {
            formatter: function (val) {
              return Math.abs(val) + "% PIB"
            }
          }
        },
        xaxis: {
          categories: ['105-109','100-104','95-99','90-94','85-89', '80-84', '75-79', '70-74', '65-69', '60-64', '55-59', '50-54',
            '45-49', '40-44', '35-39', '30-34', '25-29', '20-24', '15-19', '10-14', '5-9', '0-4'
          ],
		  labels: {
			      style: {
					  colors: '#404040',
					  fontSize: '10px'
				  },
          }, 
          title: {
            text: 'Perfil de MUJERES'
          }
        },
        };

        chartduopt2 = new ApexCharts(document.querySelector("#chart-duo-pt2"), options);
        chartduopt2.render();


		/****************** Fin de carga valores iniciales Aportaciones netas   *******************/
		
		/****************** Carga valores iniciales	 de sankey  *******************/
			
		$.ajax({
			type: 'post',
			url: 'jsonSankey.php',
			data: {
				'idSession': $("#idSession").val(),
			},
	        success: function (dataSource) {
				// Guardar datos default de Sankey
				sankeyDefaultData['sankey-1'] = dataSource;
				FusionCharts.ready(function() {
				  var myChart = new FusionCharts({
					id: 'sankey-1-chart',
					type: "sankey",
					renderAt: "sankey-1",
					width: "100%",
					height: "100%",
					dataFormat: "json",
					dataSource
				  }).render();
		});
				}
			});

		$.ajax({
			type: 'post',
			url: 'jsonSankeyGrupoedad.php',
			data: {
				'idSession': $("#idSession").val(),
			},
	        success: function (dataSource) {
				sankeyDefaultData['sankey-2'] = dataSource;
				FusionCharts.ready(function() {
				  var myChart = new FusionCharts({
					id: 'sankey-2-chart',
					type: "sankey",
					renderAt: "sankey-2",
					width: "100%",
					height: "100%",
					dataFormat: "json",
					dataSource
				  }).render();
		});
				}
			});

		$.ajax({
			type: 'post',
			url: 'jsonSankeyEscol.php',
			data: {
				'idSession': $("#idSession").val(),
			},
	        success: function (dataSource) {
				sankeyDefaultData['sankey-3'] = dataSource;
				FusionCharts.ready(function() {
				  var myChart = new FusionCharts({
					id: 'sankey-3-chart',
					type: "sankey",
					renderAt: "sankey-3",
					width: "100%",
					height: "100%",
					dataFormat: "json",
					dataSource
				  }).render();
		});
				}
			});

		$.ajax({
			type: 'post',
			url: 'jsonSankeyRural.php',
			data: {
				'idSession': $("#idSession").val(),
			},
	        success: function (dataSource) {
				sankeyDefaultData['sankey-4'] = dataSource;
				FusionCharts.ready(function() {
				  var myChart = new FusionCharts({
					id: 'sankey-4-chart',
					type: "sankey",
					renderAt: "sankey-4",
					width: "100%",
					height: "100%",
					dataFormat: "json",
					dataSource
				  }).render();
		});
				}
			});

		$.ajax({
			type: 'post',
			url: 'jsonSankeySexo.php',
			data: {
				'idSession': $("#idSession").val(),
			},
	        success: function (dataSource) {
				sankeyDefaultData['sankey-5'] = dataSource;
				FusionCharts.ready(function() {
				  var myChart = new FusionCharts({
					id: 'sankey-5-chart',
					type: "sankey",
					renderAt: "sankey-5",
					width: "100%",
					height: "100%",
					dataFormat: "json",
					dataSource
				  }).render();
		});
				}
			});
			
		},
		complete: function() {
			$('.cargando').hide();
		},
        error: function (request, status, error) {
            alert(jQuery.parseJSON(request.responseText).Message);
        }
	});


	
    $('#testPIB').click(function() {


$("#FormGastos").validate({
  success: "valid",
  submitHandler: function() { alert("Submitted!") }
});


	});
	
	
    $('#isrSub,.isrSub').click(function() {

		// Registrar clic en log
		$.ajax({
			async: true,
			type: 'post',
			url: 'logCalcular.php',
			dataType: 'json',
			data: {
				'sessionId': $("#idSession").val(),
				'pageVersion': 'es'
			}
		});

		// Enviar evento a Google Analytics
		if (typeof gtag !== 'undefined') {
			gtag('event', 'click_calcular', {
				'event_category': 'engagement',
				'event_label': 'Botón Calcular',
				'value': 1
			});
		}

		$("#Modal-ISR-1").modal('hide');
		$("#Modal-ISR-2").modal('hide');
		$("#Modal-IVA").modal('hide');

/*Aqui va el ajax para enviar los valores y se invoca al .post con el php
*/
	
   	$.ajax({
        async: true,
        type: 'post',
        url: 'calculaStata.php',
        dataType: 'json',
        data: {
			'idSession': $("#idSession").val(),

			'CRECPIB2026': $("#CRECPIB2026").val(),	
			'CRECPIB2027': $("#CRECPIB2027").val(),	
			'CRECPIB2028': $("#CRECPIB2028").val(),	
			'CRECPIB2029': $("#CRECPIB2029").val(),	
			'CRECPIB2030': $("#CRECPIB2030").val(),	
			'CRECPIB2031': $("#CRECPIB2031").val(),
			'CRECPIB2032': $("#CRECPIB2032").val(),

			'CRECDEF2026': $("#CRECDEF2026").val(),	
			'CRECDEF2027': $("#CRECDEF2027").val(),	
			'CRECDEF2028': $("#CRECDEF2028").val(),	
			'CRECDEF2029': $("#CRECDEF2029").val(),	
			'CRECDEF2030': $("#CRECDEF2030").val(),	
			'CRECDEF2031': $("#CRECDEF2031").val(),
			'CRECDEF2032': $("#CRECDEF2032").val(),

			'DEUDA0': $("#DEUDA0").val(),

			'INGRESOS0': $("#INGRESOS0").val(),
			'INGRESOS1': $("#INGRESOS1").val(),
			'INGRESOS2': $("#INGRESOS2").val(),
			'INGRESOS3':  $("#INGRESOS3").val(), 
			'INGRESOS4':  $("#INGRESOS4").val(), 
			'INGRESOS5':  $("#INGRESOS5").val(), 
			'INGRESOS6':  $("#INGRESOS6").val(), 
			'INGRESOS7':  $("#INGRESOS7").val(),
			'INGRESOS8':  $("#INGRESOS8").val(),
			'INGRESOS9':  $("#INGRESOS9").val(),
			'INGRESOS10':  $("#INGRESOS10").val(),
			'INGRESOS11':  $("#INGRESOS11").val(),
			'INGRESOS12':  $("#INGRESOS12").val(),
			'INGRESOS13':  $("#INGRESOS13").val(),
			'INGRESOS14':  $("#INGRESOS14").val(),
			'INGRESOS15':  $("#INGRESOS15").val(),
			'INGRESOS16':  $("#INGRESOS16").val(),
			'INGRESOS17':  $("#INGRESOS17").val(),
			'INGRESOS18':  $("#INGRESOS18").val(),
			
			'iniciaA': $("#iniciaA").val(),
			'basica': $("#basica").val(),
			'medsup': $("#medsup").val(),
			'superi': $("#superi").val(),
			'posgra': $("#posgra").val(),
			'eduadu': $("#eduadu").val(),
			'otrose': $("#otrose").val(),
			'invere': $("#invere").val(),
			'cultur': $("#cultur").val(),
			'invest': $("#invest").val(),

			'ssa': $("#ssa").val(),
			'imssbien': $("#imssbien").val(),
			'imss': $("#imss").val(),
			'issste': $("#issste").val(),
			'pemex': $("#pemex").val(),
			'issfam': $("#issfam").val(),
			'invers': $("#invers").val(),

			'bienestar': $("#bienestar").val(),
			'penims': $("#penims").val(),
			'peniss': $("#peniss").val(),
			'penpeme': $("#penpeme").val(),
			'penotr': $("#penotr").val(),

			'gascfe': $("#gascfe").val(),
			'gaspemex': $("#gaspemex").val(),
			'gassener': $("#gassener").val(),
			'gasinverf': $("#gasinverf").val(),
			'gascosdeue': $("#gascosdeue").val(),

			'gasinfra': $("#gasinfra").val(),
			'gasotros': $("#gasotros").val(),
			'gasfeder': $("#gasfeder").val(),
			'gascosto': $("#gascosto").val(),

			'ingbasico18': +$('#ingbasico18').is(":checked"),
			'ingbasico65': +$('#ingbasico65').is(":checked"),
			'IngBas': $("#IngBas").val(),
			'gasmadres': $("#gasmadres").val(),
			'gascuidados': $("#gascuidados").val(),

			'ISRTASA0': $("#ISRTASA0").val(),
			'ISRTASA1': $("#ISRTASA1").val(),
			'ISRTASA2': $("#ISRTASA2").val(),
			'ISRTASA3': $("#ISRTASA3").val(),
			'ISRTASA4': $("#ISRTASA4").val(),
			'ISRTASA5': $("#ISRTASA5").val(),
			'ISRTASA6': $("#ISRTASA6").val(),
			'ISRTASA7': $("#ISRTASA7").val(),
			'ISRTASA8': $("#ISRTASA8").val(),
			'ISRTASA9': $("#ISRTASA9").val(),
			'ISRTASA10': $("#ISRTASA10").val(),

			'SE0': $("#SE0").val(),
			'SE1': $("#SE1").val(),
			'SE2': $("#SE2").val(),
			'SE3': $("#SE3").val(),
			'SE4': $("#SE4").val(),
			'SE5': $("#SE5").val(),
			'SE6': $("#SE6").val(),
			'SE7': $("#SE7").val(),
			'SE8': $("#SE8").val(),
			'SE9': $("#SE9").val(),
			'SE10': $("#SE10").val(),

			'DED0': $("#DED0").val(),
			'DED1': $("#DED1").val(),
			'DED2': $("#DED2").val(),
			'DED3': $("#DED3").val(),

			'ISRMORA0': $("#ISRMORA0").val(),
			'ISRMORA1': $("#ISRMORA1").val(),

			'IVAT0': $("#IVAT0").val(),
			'IVAT1':$('input[name=IVAT1]:checked').val(),
			'IVAT2':$('input[name=IVAT2]:checked').val(),
			'IVAT3':$('input[name=IVAT3]:checked').val(),
			'IVAT4':$('input[name=IVAT4]:checked').val(),
			'IVAT5':$('input[name=IVAT5]:checked').val(),
			'IVAT6':$('input[name=IVAT6]:checked').val(),
			'IVAT7':$('input[name=IVAT7]:checked').val(),
			'IVAT8':$('input[name=IVAT8]:checked').val(),
			'IVAT9':$('input[name=IVAT9]:checked').val(),
			'IVAT10':$('input[name=IVAT10]:checked').val(),
			'IVAT11':$('input[name=IVAT11]:checked').val(),
			'IVAT12': $("#IVAT12").val(),


			'CSSIMSS0': $("#CSSIMSS0").val(),
			'CSSIMSS1': $("#CSSIMSS1").val(),
			'CSSIMSS2': $("#CSSIMSS2").val(),
			'CSSIMSS3': $("#CSSIMSS3").val(),
			'CSSIMSS4': $("#CSSIMSS4").val(),
			'CSSIMSS5': $("#CSSIMSS5").val(),
			'CSSIMSS6': $("#CSSIMSS6").val(),
			'CSSIMSS7': $("#CSSIMSS7").val(),
			'CSSIMSS8': $("#CSSIMSS8").val(),
			'CSSIMSS9': $("#CSSIMSS9").val(),
			'CSSIMSS10': $("#CSSIMSS10").val(),
			'CSSIMSS11': $("#CSSIMSS11").val(),
			'CSSIMSS12': $("#CSSIMSS12").val(),
			'CSSIMSS13': $("#CSSIMSS13").val(),
			'CSSIMSS14': $("#CSSIMSS14").val(),
			'CSSIMSS15': $("#CSSIMSS15").val(),
			'CSSIMSS16': $("#CSSIMSS16").val(),
			'CSSIMSS17': $("#CSSIMSS17").val(),
			'CSSIMSS18': $("#CSSIMSS18").val(),
			'CSSIMSS19': $("#CSSIMSS19").val(),
			'CSSIMSS20': $("#CSSIMSS20").val(),

			'CSSISSSTE0': $("#CSSISSSTE0").val(),
			'CSSISSSTE1': $("#CSSISSSTE1").val(),
			'CSSISSSTE2': $("#CSSISSSTE2").val(),
			'CSSISSSTE3': $("#CSSISSSTE3").val(),
			'CSSISSSTE4': $("#CSSISSSTE4").val(),
			'CSSISSSTE5': $("#CSSISSSTE5").val(),
			'CSSISSSTE6': $("#CSSISSSTE6").val(),
			'CSSISSSTE7': $("#CSSISSSTE7").val(),
			'CSSISSSTE8': $("#CSSISSSTE8").val(),
			'CSSISSSTE9': $("#CSSISSSTE9").val(),
			'CSSISSSTE10': $("#CSSISSSTE10").val(),
			'CSSISSSTE11': $("#CSSISSSTE11").val(),
			'CSSISSSTE12': $("#CSSISSSTE12").val(),
			'CSSISSSTE13': $("#CSSISSSTE13").val(),
			'CSSISSSTE14': $("#CSSISSSTE14").val(),
			'CSSISSSTE15': $("#CSSISSSTE15").val(),
			'CSSISSSTE16': $("#CSSISSSTE16").val(),
			'CSSISSSTE17': $("#CSSISSSTE17").val(),
			'CSSISSSTE18': $("#CSSISSSTE18").val(),
			'CSSISSSTE19': $("#CSSISSSTE19").val(),
			'CSSISSSTE20': $("#CSSISSSTE20").val(),
			'CSSISSSTE21': $("#CSSISSSTE21").val(),
			'CSSISSSTE22': $("#CSSISSSTE22").val(),
			'CSSISSSTE23': $("#CSSISSSTE23").val(),
			
			'moduloCambio': $("#moduloCambio").val(),			
			'moduloCambioIva': $("#moduloCambioIva").val(),			



        },
 beforeSend:function () {

		$('#cargando-notify').addClass('active');
		$('#count').text(35);
//		alert("moduloCambio:" +  $("#moduloCambio").val()  + " moduloCambioIva:"+ $("#moduloCambioIva").val())

 },
        success: function (datos) {
			// Guardar datos de simulación para toggle
			datosSimulacion = JSON.parse(JSON.stringify(datos));
			haySimulacion = true;
			
			// Habilitar botones de simulación y activar vista de simulación
			$('.toggle-data-btns .btn-toggle[data-view="simulacion"]').removeClass('btn-disabled');
			$('.toggle-data-btns .btn-toggle').removeClass('active');
			$('.toggle-data-btns .btn-toggle[data-view="simulacion"]').addClass('active');
			
			cambioISR=0;
			cambioIVA=0;
			var GASTOSTOTAL =parseFloat(datos.GASTOS[40]) ;
			var INGRESOSTOTAL =parseFloat(datos.INGRESOS[19]);
			var DEUDA = INGRESOSTOTAL -GASTOSTOTAL;
			if(DEUDA >=0 )  {
				$(".idDeuda").parent().parent().addClass("positivo");
				$(".idDeuda").addClass("txt-ingresos");
				$(".idDeuda").removeClass("txt-gastos");
			} else {
				$(".idDeuda").parent().parent().removeClass("positivo");
				$(".idDeuda").addClass("txt-gastos");
				$(".idDeuda").removeClass("txt-ingresos");
			}
			$(".GASTOSTOTAL").html(GASTOSTOTAL);
			$(".INGRESOSTOTAL").html(INGRESOSTOTAL);
			$(".DEUDA").html(formatoMoneda(DEUDA,1,0,3));


				$("#DEUDA0").val(formatoMoneda(datos.DEUDAPARAM[0],1,0,3));
				$("#DEUDA1").val(formatoMoneda(datos.DEUDAPARAM[1],1,0,3));
				$("#DEUDA2").val(formatoMoneda(datos.DEUDAPARAM[2],1,0,3));
//				$("#PROYMAX").html(datos.PROYMAX);
				var PROYMAX =parseFloat(datos.PROYMAX) ;
				if(PROYMAX>2049) {
					$("#PROYMAX").parent().parent().addClass("alert-warning");
					$("#PROYMAX").parent().parent().removeClass("alert-danger");
					$("#PROYMAX").parent().parent().html("Las Aportaciones Netas no disminuirían, al menos, hasta el 2050.");
				} else {
					$("#PROYMAX").parent().parent().addClass("alert-danger");
					$("#PROYMAX").parent().parent().removeClass("alert-warning");
					$("#PROYMAX").parent().parent().html('<span class="material-icons">warning</span><p>A partir del <span id="PROYMAX">'+ PROYMAX +'</span>, las <b>Aportaciones Netas</b> comienzan a DISMINUIR</p>');
				}
				if(datos.PROYSHRFSP1[parseInt(datos.ANIOBASE)-2013] > datos.PROYSHRFSP2[datos.PROYSHRFSP2.length-1]) {
					$("#textPROYSHRFSP").addClass("alert-secondary");
					$("#textPROYSHRFSP").removeClass("alert-danger");
					$("#textPROYSHRFSP").html('<p>Al ' + (datos.ANIOEND || 2032) + ', el indicador de la deuda sería menor que en ' + datos.ANIOBASE + '.</p>');
				}else {
					$("#textPROYSHRFSP").removeClass("alert-secondary");
					$("#textPROYSHRFSP").addClass("alert-danger");
					$("#textPROYSHRFSP").html('<span class="material-icons">warning</span><p>Al ' + (datos.ANIOEND || 2032) + ', el indicador de la deuda sería mayor que en ' + datos.ANIOBASE + '.</p>');
				}

			$(".IVA").each(function(index, element) {
                $( this ).html(datos.ISRTASA[index]);
            });
				
			$(".ISRCUFI").each(function(index, element) {
                $( this ).html(formatoMexico(datos.ISRCUFI[index]));
            });


			$(".valINCD").each(function(index, element) {
                $( this ).html(formatoMexico(datos.INCD[index]));
            });
			$(".valINCD2").each(function(index, element) {
                $( this ).html(formatoMexico(datos.INCD2[index]));
            });
			$(".valINCD3").each(function(index, element) {
                $( this ).html(formatoMexico(datos.INCD3[index]));
            });
			$(".INGRESOS").each(function(index, element) {
				switch (index) {
					case 6:
						$( this ).val(datos.INGRESOS[15]);
						break;
					case 7:
						$( this ).val(datos.INGRESOS[6]);
						break;
					case 8:
						$( this ).val(datos.INGRESOS[7]);
						break;
					case 9:
						$( this ).val(datos.INGRESOS[8]);
						break;
					case 10:
						$( this ).val(datos.INGRESOS[9]);
						break;
					case 11:
						$( this ).val(datos.INGRESOS[10]);
						break;
					case 12:
						$( this ).val(datos.INGRESOS[11]);
						break;
					case 13:
						$( this ).val(datos.INGRESOS[12]);
						break;
					case 14:
						$( this ).val(datos.INGRESOS[13]);
						break;
					case 15:
						$( this ).val(datos.INGRESOS[14]);
						break;
					case 16:
						$( this ).val(datos.INGRESOS[17]);  // DOM index 16 = CFE (id=INGRESOS17)
						break;
					case 17:
						$( this ).val(datos.INGRESOS[16]);  // DOM index 17 = Pemex (id=INGRESOS16)
						break;
					default:
						$( this ).val(datos.INGRESOS[index]);        
				}
            });
			$(".GASTOS").each(function(index, element) {
                $( this ).val(datos.GASTOS[index]);
            });

			$(".INGRESOSTEF").each(function(index, element) {
				switch (index) {
					case 6:
						$( this ).html(datos.INGRESOSTEF[15]);
						break;
					case 7:
						$( this ).val(datos.INGRESOSTEF[6]);
						break;
					case 8:
						$( this ).html(datos.INGRESOSTEF[7]);
						break;
					case 9:
						$( this ).html(datos.INGRESOSTEF[8]);
						break;
					case 10:
						$( this ).html(datos.INGRESOSTEF[9]);
						break;
					case 11:
						$( this ).html(datos.INGRESOSTEF[10]);
						break;
					case 12:
						$( this ).html(datos.INGRESOSTEF[11]);
						break;
					case 13:
						if(index == 13)
							$( this ).val(datos.INGRESOSTEF[12]);
						$( this ).html(datos.INGRESOSTEF[12]);
						break;
					case 14:
						$( this ).html(datos.INGRESOSTEF[13]);
						break;
					case 15:
						$( this ).html(datos.INGRESOSTEF[14]);
						break;
					case 16:
						$( this ).html(datos.INGRESOSTEF[17]);  // DOM index 16 = CFE (id=INGRESOSTEF17)
						break;
					case 17:
						$( this ).html(datos.INGRESOSTEF[16]);  // DOM index 17 = Pemex (id=INGRESOSTEF16)
						break;
					case 18:
						$( this ).val(datos.INGRESOSTEF[18]);
						break;
					default:
						if(index == 3)
							$( this ).val(datos.INGRESOSTEF[index]);
						$( this ).html(datos.INGRESOSTEF[index]);				
//						$( this ).val(datos.INGRESOSTEF[index]);        
				}
            });	
/*			$(".INGRESOSTEF").each(function(index, element) {
                if(index == 3 || index == 6 || index == 12 || index == 18)
					$( this ).val(datos.INGRESOSTEF[index]);
				$( this ).html(datos.INGRESOSTEF[index]);				
            });
*/			
//			$(".INPUTSI").each(function(index, element) {
//				$( this ).val(datos.INGRESOSTEF[index]);
//			});
			$(".INPUTSG").each(function(index, element) {
				switch(index) {
				case 38:
					$("#ingbasico18").attr('checked', datos.GASTOSPC[index]);
					break;
				case 39:
					$("#ingbasico65").attr('checked', datos.GASTOSPC[index]);
					break;
				default:
					$( this ).html(formatoMexico(Math.round(datos.GASTOSPC[index])));
				
				}
				
			});
			poblarConteos(datos);
			$(".ISRSUBS").each(function(index, element) {
				$( this ).val(datos.ISRSUBS[index]);
			});
			
  			$(".PROYSHRFSP3").each(function(index, element) {
				$( this ).html(formatoMexico(datos.PROYSHRFSP3[index]));
			});
			for(var index=0; index<=12;index++) {
				if(index==0 || index ==12) {
					$("#IVAT"+index).val(datos.IVA[index]);
				} else {
					var v=parseInt(datos.IVA[index]);
					switch (v) {
				  		case 1:
							$("#IVAT"+index+"a").attr('checked', true);
					    	break;
  						case 2:
							$("#IVAT"+index+"b").attr('checked', true);
					    	break;
  						default:
							$("#IVAT"+index+"c").attr('checked', true);
					}
					
				}
				
			}

		/****************** Actualiza valores Proyección de las aportaciones netas   *******************/
	 chartline1.updateSeries([{
				name: 'Aportaciones netas',
				//data: [ 1.308, 1.381, 1.483, 1.666, 1.953, 1.278, 1.577, 1.803, 1.847, 1.751, 1.539]
				data: datos.PROY
  
			}]);
		/****************** Fin de la actualización de Proyección de las aportaciones netas   *******************/
		/****************** Actualiza valores  Ingresos presupuestarios  *******************/

	 chartstacked1.updateSeries([{
          name: 'Al trabajo',
          data:  datos.PROYLABOR
        }, {
          name: 'Al consumo',
          data:  datos.PROYCONSU
        }, {
          name: 'Al capital',
          data:  datos.PROYCAPIT 
        }, {
          name: 'OyE públicas',
          data:  datos.PROYORGAN
			}]);


		/****************** Fin de la actualización Ingresos presupuestarios  *******************/
		/****************** Actualiza valores Gasto público   *******************/
	 chartstacked2.updateSeries([{
			  name: 'Educación',
			  data:  datos.PROYEDUCA
			}, {
			  name: 'Pensiones',
			  data:  datos.PROYPENSI
			}, {
			  name: 'Salud',
			  data:  datos.PROYSALUD
			}, {
			  name: 'Otros',
			  data:  datos.PROYOTROS
			}, {
			  name: 'Energía',
			  data:  datos.PROYENERG
			}, {
			  name: 'Inversión',
			  data:  datos.PROYINVER  
			}, {
			  name: 'Costo deuda',
			  data:  datos.PROYCOSTO 
			}]);

		/****************** Fin de la actualización  Gasto público *******************/
		/****************** Actualiza valores Proyección de la deuda   *******************/
	 chartarea2.updateSeries([{
          name: 'Reportado',
          data: datos.PROYSHRFSP1
        }, {
          name: 'Proyectado',
          data: datos.PROYSHRFSP2
			}]);

		/****************** Fin de la actualización Proyección de la deuda  *******************/
		/****************** Actualiza valores  Aportaciones netas  *******************/
	 chartduopt1.updateSeries([{
          name: 'Deciles I-V',
          data: datos.APORTHIV
        },	{
          name: 'VI-IX',
          data: datos.APORTHVIIX
        },  {
          name: 'X',
          data: datos.APORTHX
			}]);

	 chartduopt2.updateSeries([{
           name: 'Deciles I-V',
          data: datos.APORTMIV
        },	{
          name: 'VI-IX',
          data: datos.APORTMVIIX
        },  {
          name: 'X',
          data: datos.APORTMX
			}]);

		/****************** Fin de la actualización  Aportaciones netas *******************/

  

        },
 complete:function () {

	/****************** Actualiza valores   Redistribución de los recursos públicos *******************/
	$('#moduloCambio').val(0);
	$('#moduloCambioIva').val(0);

	// v8.2.0 fix: el refresh post-simulación solo pedía 2 de los 5 Sankeys
	// (decil y grupoedad; escol quedó comentado a medias) — escol, rural y
	// sexo se quedaban con el default de la carga inicial aunque Stata SÍ
	// regenera los 5 por sesión (Web.Stata.do §7.2). Misma lista que la
	// carga inicial.
	var sankeyRefresh = [
		{ renderAt: 'sankey-1', url: 'jsonSankey.php' },
		{ renderAt: 'sankey-2', url: 'jsonSankeyGrupoedad.php' },
		{ renderAt: 'sankey-3', url: 'jsonSankeyEscol.php' },
		{ renderAt: 'sankey-4', url: 'jsonSankeyRural.php' },
		{ renderAt: 'sankey-5', url: 'jsonSankeySexo.php' }
	];
	sankeyRefresh.forEach(function(cfg) {
		$.ajax({
			type: 'post',
			url: cfg.url,
			data: {
				'idSession': $("#idSession").val(),
			},
			success: function (dataSource) {
				FusionCharts.ready(function() {
					var myChart = new FusionCharts({
						type: "sankey",
						renderAt: cfg.renderAt,
						width: "100%",
						height: "100%",
						dataFormat: "json",
						dataSource
					}).render();
				});
			}
		});
	});

	$( ".table" ).addClass( "blink-1" );
	setTimeout(function() { 
		$(".table").removeClass( "blink-1" );
	}, 1500);

		$('#cargando-notify').removeClass('active');		
 		},
        error: function (request, status, error) {
            alert(jQuery.parseJSON(request.responseText).Message);
        }
 
	    });


    });

	// Handler para los botones de toggle 2027/Simulación
	$(document).on('click', '.toggle-data-btns .btn-toggle', function(e) {
		e.preventDefault();
		
		// Si el botón está deshabilitado, no hacer nada
		if($(this).hasClass('btn-disabled')) {
			alert('Es necesario realizar una simulación para mostrar los valores.');
			return;
		}
		
		// Si ya está activo, no hacer nada
		if($(this).hasClass('active')) return;
		
		var $btnGroup = $(this).parent();
		var section = $btnGroup.data('section');
		var view = $(this).data('view');
		var datos = (view === 'default') ? datosDefault : datosSimulacion;
		
		if(!datos) {
			alert('No hay datos disponibles para esta vista');
			return;
		}
		
		// Actualizar estado de botones
		$btnGroup.find('.btn-toggle').removeClass('active');
		$(this).addClass('active');
		
		// Actualizar datos según la sección
		actualizarSeccion(section, datos);
	});

});
