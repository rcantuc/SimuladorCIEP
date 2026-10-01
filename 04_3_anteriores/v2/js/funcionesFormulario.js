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
	
/********************  Funciones para el manejo del menu  ******************************/

	var sele =  { "iva":'menu-left-iva.php', "isr":'menu-left-isr-fisicas.php' , "isr_pm": 'menu-left-isr-morales.php', "imss":'menu-left-seguridad-social-imss.php' , "issste":'menu-left-seguridad-social-issste.php',  "ieps":"menu-left-ieps-no-petrolero.php",
		"pec":'menu-left-escuelas-de-calidad.php', "pes":'menu-left-escuela-segura.php' , "petc":'menu-left-escuelas-de-tiempo-completo.php', "pfcie":'menu-left-fortalecimiento-de-la-calidad.php' , "piee":'menu-left-inclusion-y-equidad.php',  "pfceb":"menu-left-fortalecimiento-de-la-calidad-basica.php",  "pdpd":"menu-left-desarrollo-profesional-docente.php",  "pnb":"menu-left-nacional-de-becas.php","kstc5":"menu-left-colectivo-metro.php","kturi6":"menu-left-infraestructura-turismo.php","kaereo7":"menu-left-infraestructura-aeropuertos.php","kcar1":"menu-left-infraestructura-carreteras-conservacion.php","kcar2":"menu-left-carreteras-alimentadoras-rurales.php","kelec3":"menu-left-electricidad-pidiregas.php","koil9":"menu-left-infraestructura-hidrocarburos.php","kasis8":"menu-left-proyectos-asistencia-seguridad2.php","menu-left-seguro-siglo-xxi.php":"sigloxxi","sica":"menu-left-sistema-calidad-salud.php","comunidades":"menu-left-programa-comunidades-saludables.php","caravanas":"menu-left-caravanas-de-la-salud.php" ,"pension_nc":"menu-left-pension-adultos-universal.php","seguro_jefas":"menu-left-seguro-jefas-familia.php", "oportunidades_educacion":"menu-left-programa-oportunidades-educacion.php",
		"oportunidades_salid":"menu-left-programa-oportunidades-salud.php","oportunidades_alim":"menu-left-programa-oportunidades-alim"
		,"proagro":"menu-left-fomento-agricultura.php","progan":"menu-left-fomento-ganadero.php"};

	var sel =  {'menu-left-iva.php': "iva", 'menu-left-isr-fisicas.php': "isr", 'menu-left-isr-morales.php': "isr_pm", 'menu-left-seguridad-social-imss.php': "cuotas_imss", 'menu-left-seguridad-social-issste.php': "cuotas_issste", "menu-left-ieps-no-petrolero.php": "ieps_total",'menu-left-escuelas-de-calidad.php':"pec", 'menu-left-escuela-segura.php':"pes" , 'menu-left-escuelas-de-tiempo-completo.php':"petc", 'menu-left-fortalecimiento-de-la-calidad.php':"pfcie" , 'menu-left-inclusion-y-equidad.php':"piee",  "menu-left-fortalecimiento-de-la-calidad-basica.php":"pfceb",  "menu-left-desarrollo-profesional-docente.php":"pdpd",  "menu-left-nacional-de-becas.php":"pnb",
	'menu-left-escuelas-de-calidad.php':"pec", 'menu-left-escuela-segura.php':"pes" , 'menu-left-escuelas-de-tiempo-completo.php':"petc", 'menu-left-fortalecimiento-de-la-calidad.php':"pfcie" , 'menu-left-inclusion-y-equidad.php':"piee",  "menu-left-fortalecimiento-de-la-calidad-basica.php":"pfceb",  "menu-left-desarrollo-profesional-docente.php":"pdpd",  "menu-left-nacional-de-becas.php":"pnb","menu-left-colectivo-metro.php":'kstc5',"menu-left-infraestructura-turismo.php":"kturi6","menu-left-infraestructura-aeropuertos.php":"kaereo7","menu-left-infraestructura-carreteras-conservacion.php":"kcar1","menu-left-carreteras-alimentadoras-rurales.php":"kcar2","menu-left-electricidad-pidiregas.php":"kelec3","menu-left-infraestructura-hidrocarburos.php":"koil9","menu-left-proyectos-asistencia-seguridad2.php":"kasis8","menu-left-seguro-siglo-xxi.php":"sigloxxi","menu-left-sistema-calidad-salud.php":"sica","menu-left-programa-comunidades-saludables.php":"comunidades","menu-left-caravanas-de-la-salud.php":"caravanas","menu-left-pension-adultos-universal.php":"pension_nc","menu-left-seguro-jefas-familia.php":"seguro_jefas", "menu-left-programa-oportunidades-educacion.php":"oportunidades_educacion","menu-left-programa-oportunidades-salud.php":"oportunidades_salid","menu-left-programa-oportunidades-alim":"oportunidades_alim"
	,"menu-left-fomento-agricultura.php":"proagro","menu-left-fomento-ganadero.php":"progan"};

	var selNombre =  {'menu-left-iva.php': "IVA", 'menu-left-isr-fisicas.php': "ISR", 'menu-left-isr-morales.php': "ISR%20Personas%20morales", 'menu-left-seguridad-social-imss.php': "IMSS", 'menu-left-seguridad-social-issste.php': "ISSSTE", "menu-left-ieps-no-petrolero.php": "IEPS"
	,'menu-left-escuelas-de-calidad.php':"Escuelas%20de%20Calidad"
	,'menu-left-escuela-segura.php':"Programa%20Escuela%20Segura" 
	,'menu-left-escuelas-de-tiempo-completo.php':"Programa%20Escuelas%20de%20Tiempo%20Completo"
	,'menu-left-fortalecimiento-de-la-calidad.php':"Programa%20de%20fortalecimiento%20de%20la%20calidad%20en%20instituciones%20educativas" 
	,'menu-left-inclusion-y-equidad.php':"Programa%20para%20la%20Inclusión%20y%20la%20Equidad%20Educativa"
	,"menu-left-fortalecimiento-de-la-calidad-basica.php":"Programa%20de%20Fortalecimiento%20de%20la%20Calidad%20en%20Educación%20Básica"
	,"menu-left-desarrollo-profesional-docente.php":"Programa%20para%20el%20Desarrollo%20Profesional%20Docente"
	,"menu-left-nacional-de-becas.php":"Programa%20Nacional%20de%20Becas"
	,"menu-left-colectivo-metro.php":"Sistema%20de%20Transporte%20Colectivo%20(METRO)"
	,"menu-left-infraestructura-turismo.php":"Proyectos%20de%20infraestructura%20de%20turismo"
	,"menu-left-infraestructura-aeropuertos.php":"Proyectos%20de%20infraestructura%20económica%20de%20aeropuertos"
	,"menu-left-infraestructura-carreteras-conservacion.php":"Proyectos%20de%20infraestructura%20económica%20de%20carreteras%20+%20Conservación%20de%20Infraestructura%20Carretera"
	,"menu-left-carreteras-alimentadoras-rurales.php":"Proyectos%20de%20infraestructura%20económica%20de%20carreteras%20alimentadoras%20y%20caminos%20rurales"
	,"menu-left-electricidad-pidiregas.php":"Proyectos%20de%20infraestructura%20económica%20de%20electricidad%20+%20PIDIREGAS"
	,"menu-left-infraestructura-hidrocarburos.php":"Proyectos%20de%20infraestructura%20económica%20de%20hidrocarburos"
	,"menu-left-proyectos-asistencia-seguridad2.php":"Proyectos%20de%20infraestructura%20social%20de%20asistencia%20y%20seguridad%20social"
	,"menu-left-seguro-siglo-xxi.php":"Seguro%20Médico%20Siglo%20XXI"
	,"menu-left-sistema-calidad-salud.php":"Sistema%20Integral%20de%20Calidad%20en%20Salud"
	,"menu-left-programa-comunidades-saludables.php":"Programa%20Comunidades%20Saludables"
	,"menu-left-caravanas-de-la-salud.php":"Caravanas%20de%20la%20Salud"
	,"menu-left-pension-adultos-universal.php":"Pensión%20para%20Adultos%20Mayores%20mas%20Pensión%20Universal"
	,"menu-left-seguro-jefas-familia.php":"Seguro%20de%20vida%20para%20jefas%20de%20familia"
	,"menu-left-programa-oportunidades-educacion.php":"Programa%20de%20Desarrollo%20Humano%20Oportunidades%20(Educación)"
	,"menu-left-programa-oportunidades-salud.php":"Programa%20de%20Desarrollo%20Humano%20Oportunidades%20(Salud)"
	,"menu-left-programa-oportunidades-alim":"Programa%20de%20Desarrollo%20Humano%20Oportunidades%20(Alimentario)"
	,"menu-left-fomento-agricultura.php":"Programa%20de%20Fomento%20a%20la%20Agricultura"
	,"menu-left-fomento-ganadero.php":"Programa%20de%20Fomento%20Ganadero"
	};


	if($("#iframeMenu").attr('name')!='' && $("#iframeMenu").attr('name')!= undefined) {
		var tmpNombrePhp = sele[$("#iframeMenu").attr('name')];
		var tmpNombre = sel[tmpNombrePhp];
		var tmpNombreCompleto = selNombre[tmpNombrePhp];
		$("#iframeMenu").load("parts/menu-left-iva.html") /* MUSEO: menú estático reconstruido */;
		$("#PTI").load("parts/tabla-incidencia-del-modulo.html") /* MUSEO: parte estática reconstruida (solo IVA) */;
		$("#PTII").load("parts/perfil-generacional.html") /* MUSEO: parte estática reconstruida (solo IVA) */;		
		$("#pt2").load("parts/tabla-recaudacion-modulo.html") /* MUSEO: parte estática reconstruida (solo IVA) */;		
	} else {
		var href = $(location).attr('href');
		href= href.split('/');
		href=href[href.length-1]; 

		if(getCookie("ciepLast")!=null && sele[getCookie("ciepLast")]!= undefined ) {
//			if( sele[getCookie("ciepLast")]== undefined)

			var tmpNombrePhp = sele[getCookie("ciepLast")];
			var tmpNombre = sel[tmpNombrePhp];
			var tmpNombreCompleto = selNombre[tmpNombrePhp];
			console.log("Leer cookie: "+tmpNombrePhp+":="+tmpNombre);
			$("#iframeMenu").load("parts/menu-left-iva.html") /* MUSEO: menú estático reconstruido */;
			if(href!='inicio0.php') {
				$("#PTI").load("parts/tabla-incidencia-del-modulo.html") /* MUSEO: parte estática reconstruida (solo IVA) */;
				$("#PTII").load("parts/perfil-generacional.html") /* MUSEO: parte estática reconstruida (solo IVA) */;		
				$("#pt2").load("parts/tabla-recaudacion-modulo.html") /* MUSEO: parte estática reconstruida (solo IVA) */;				
			}
//			$("#PTI").load("parts/tabla-incidencia-del-modulo.html") /* MUSEO: parte estática reconstruida (solo IVA) */;
//			$("#PTII").load("parts/perfil-generacional.html") /* MUSEO: parte estática reconstruida (solo IVA) */;		
//			$("#pt2").load("parts/tabla-recaudacion-modulo.html") /* MUSEO: parte estática reconstruida (solo IVA) */;		
		} else {
		
			$("#iframeMenu").load("parts/menu-left-ingresos.html");	
			if(href!='inicio0.php') {
				$("#PTI").load("parts/tabla-incidencia-del-modulo.html");
				$("#PTII").load("parts/perfil-generacional.html");		
				$("#pt2").load("parts/tabla-recaudacion-modulo.html");				
			}
		}
	}


	var quitaEfecto =  function() {
            $( '#btn-toggle' ).removeClass("btn-activo" );
          $( "#iframeMenu" ).removeClass( "blur" );
		  $( "#content" ).removeClass( "blur" );
		  $( "#top" ).removeClass( "hide-elements" );
		  $( "#cargador" ).removeClass( "visible" );
		  $( "#trama-negra" ).removeClass( "visible" );
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
		$('#tasaIEPSR2').text(Number($('#tasaIEPS6').val())*0.16-Number($('#tasaIEPS5').val()) * 0.16);
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
	$('.currency').numeric({prefix:'<span>$</span> ', cents: true});
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
