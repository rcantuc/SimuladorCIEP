function makeid()
{
    var text = "";
    var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    for( var i=0; i < 8; i++ )
        text += possible.charAt(Math.floor(Math.random() * possible.length));

    return text;
}

<!-- Botones + / - -->
$(document).ready(function() {
	var tiepoVidaCookieDias =7; 
	var nivelPEF =0;
	var entradasPEF = ['N0','N1','N2','N3','N4','N1_1','N1_2','N1_3','N1_4','N1_5','N1_6','N1_7','N1_8','N2_1','N2_2','N2_3','N2_4','N2_5','N2_6','N2_7','N2_8','N3_1','N3_2','N3_3','N3_4','N4_1','N4_2','N4_3','N4_4','N4_5','N4_6','N4_7'];
	var idSession=makeid(); 		

	if($.cookie('idSession') == undefined) {
		idSession=makeid(); 		
	} else 
		idSession=$.cookie('idSession');
	$.cookie("idSession", idSession, { expires: tiepoVidaCookieDias });

	var entradas = [];
	location.search.replace('?', '').split('&').forEach(function (val) {
		split = val.split("=", 2);
		entradas[split[0]] = split[1];
	});
	
	$.ajax({ // lectura y almacenamiento de PEF
			url: "pefNombres.php?idSession="+idSession,	
			
			async:false,

			//GET method is used
			type: "GET",
			
			//Do not cache the page
			cache: false,
			
			//success
			success: function (data) {	

				$(data).find("*").each(function(){  /*********************cargar valor de cookies cuando alla***************************/
				
					var aEvaluar = (this.tagName + " = " + this.innerHTML);

					eval(aEvaluar);
				});

			
		}
	});

	
	
	$('.mas').click(function () {
		var NN; // valor del padre
		var Nactual=0;
		var suma = 0;
		var valorid= $(this).parent().parent().parent().parent().attr('id');

		var N=valorid.replace("valor", ""); 
		var nActual=valorid.replace("valor", "N"); 
		
		
		if(N.length==1) { NN="N0";Nactual=N.substring(0, 1); }// N=='1' || N=='2' || N=='3' || N=='4')  NN="N0";
		if(N.length==3) { NN="N"+N.substring(0, 1);Nactual=N.substring(2, 3);} 
		if(N.length==5) { NN="N"+N.substring(0, 3); Nactual=N.substring(4, 5);}

		var t = parseInt(Nactual)-1;

		var NValores=eval(eval("NN"));

		var nit = NValores[t]; //eval(eval("NN")+"[t]");

		var nuevoMonto= parseInt(nit)*1.05;
		NValores[t]=nuevoMonto;

		eval(eval("NN")+"=NValores");

//		$.cookie(eval("NN"), "["+NValores+"]", {expires:tiepoVidaCookieDias});
		// falta guardar  SUMA como el padre de ejem 1_1_1 se reduce la suma = 1_1 y lo mismo para 1_1 suma=1  		$.cookie(eval("NN"), escape(NValores.join(',')), {expires:tiepoVidaCookieDias});
		padre(nActual,nuevoMonto);

		recalculaCuadro();
//		console.log( nActual + ":" + padre(nActual)  + ":" + eval(padre(nActual)));

	});
	
	$('.menos').click(function () {	
		var NN; // valor del padre
		var Nactual=0;
		var suma = 0;
		var valorid= $(this).parent().parent().parent().parent().attr('id');

		var N=valorid.replace("valor", ""); 
		var nActual=valorid.replace("valor", "N"); 

		if(N.length==1) { NN="N0";Nactual=N.substring(0, 1); }// N=='1' || N=='2' || N=='3' || N=='4')  NN="N0";
		if(N.length==3) { NN="N"+N.substring(0, 1);Nactual=N.substring(2, 3);} 
		if(N.length==5) { NN="N"+N.substring(0, 3); Nactual=N.substring(4, 5);}

		var t = parseInt(Nactual)-1;


		var NValores=eval(eval("NN"));
		var NValores=eval(eval("NN"));

		var nit = NValores[t]; //eval(eval("NN")+"[t]");

		var nuevoMonto= parseInt(nit)*0.95;
		NValores[t]=nuevoMonto;

		eval(eval("NN")+"=NValores");
//		$.cookie(eval("NN"), "["+NValores+"]", {expires:tiepoVidaCookieDias}); //borrado por redundante se guarda en padre

		padre(nActual,nuevoMonto);

		recalculaCuadro();
	});
	
	function padre(hijo, nuevoValor) {

		if(hijo == 'N0') return false;  // caso base

		if(hijo.length == 2) {
			var tt = hijo.substring(hijo.length-1,hijo.length);
			tt=parseInt(tt)-1;
			N0[tt]=nuevoValor;
			$.cookie("N0", "["+N0+"]", {expires:tiepoVidaCookieDias});
//			console.log(  "N0:"+N0) ;
			return 'N0';  // caso base
		}

		var t = eval(hijo.substring(0,hijo.length-2));
		var tt = hijo.substring(hijo.length-1,hijo.length)-1;
		t[tt]=nuevoValor;
		suma=0;
		for(i=0;i<t.length;i++)
			suma+=t[i];

		$.cookie(hijo.substring(0,hijo.length-2), "["+t+"]", {expires:tiepoVidaCookieDias});
//		console.log( hijo.substring(0,hijo.length-2) + ":"+t+ ":=>"+suma) ;
		padre(hijo.substring(0,hijo.length-2),suma);
		return hijo.substring(0, hijo.length-2); 

	}
	
	function recalculaCuadro() {
		var gasto = ((N0[0]+N0[1]+N0[2]+N0[3]) / 1000000).toFixed(2);
		gasto = formato(gasto,true);
		$('#gastoSimulado').html(gasto+" <span> mdp </span>");
		$('#gastoValor').html(gasto+" <span> mdp </span>");
		pefAprobado= $('#gastoAprobado').text().replace(",", "").replace(",", "").replace("mdp", "");
		pefSimulado= $('#gastoSimulado').text().replace(",", "").replace(",", "").replace("mdp", "");
		$('#diferenciaSimulado').html(formato(pefAprobado-pefSimulado,true)+" <span> mdp </span>");

		$('.tabla.valorid').each(function(index, element) {
			
			var NN; // valor del padre
			var Nactual=0;
			var suma = 0;
			var valorid= $(this).attr('id');

			var N=valorid.replace("valor", ""); 
			if(N.length==1) { NN="N0";Nactual=N.substring(0, 1); }// N=='1' || N=='2' || N=='3' || N=='4')  NN="N0";
			if(N.length==3) { NN="N"+N.substring(0, 1);Nactual=N.substring(2, 3);} 
			if(N.length==5) { NN="N"+N.substring(0, 3); Nactual=N.substring(4, 5);}

			var t = parseInt(Nactual)-1;

			var NValores=eval(eval("NN"));
			var NValores=eval(eval("NN"));

			var nit = NValores[t]; //eval(eval("NN")+"[t]");

			var nuevoMonto= parseInt(nit);
			
			for (var i = 0; i < NValores.length; i++) {
				suma += NValores[i];
			}

			$('#'+valorid + ' .monto').html( "$" + (nuevoMonto/1000000).toFixed(2) + " mdp" );
			$('#'+valorid + ' .porcentaje').html(  (nuevoMonto/suma*100 ).toFixed(1) + "%");
			var alto =nuevoMonto/suma*600;
			$('#'+valorid).height(alto);			
			
        });
		
	};


	$('.masInfor').click(function () {	
//		$('.tablafinal').toggle();
		$("#tablaIncidencia").find("tr:gt(0)").remove();
		var idtabla= $(this).attr('id');
		$('#nombreTablaIncidencia').text($("#"+idtabla).text());
		$(".crumbs").append("<span class='link-out'>"+$("#"+idtabla).text()+"</span>")

		var idN=eval("N"+idtabla);
		$.ajax({ // lectura y almacenamiento de PEF
		url: "pefNombre.php?idNombre=NOM_N"+idtabla+"&idIndice=all",	
		//"pefNombre.php?idNombre=NOM_N1_7_1&idIndice=all",

		
		async:false,

		//GET method is used
		type: "GET",
		
		//Do not cache the page
		cache: false,
		
		//success
		success: function (data) {	
			var datos=eval(data);
			var suma=0;
			for(i=0;i<idN.length;i++) {
				suma+=idN[i];
			}
			var fileParNon='';
			for(i=0;i<datos.length;i++) {
				a=$('<div/>').html(datos[i]).text();
				porcentaje=idN[i]/suma*100;
				if(i%2)
				 	fileParNon="par";
				else 
					fileParNon="non";
				idNimdp=idN[i]/1000000;	
				idNimdpbis=idNimdp+2;
				var esigual='azul';
				if(idNimdp!=idNimdpbis)
					esigual='rojo';
					
				$('#tablaIncidencia').append('<tr class="'+fileParNon+'"><td class="col_1" >'+a+'</td><td class="col_2 azul" >'+porcentaje.toFixed(4)+'<span>%</span></td><td class="col_3 azul">$'+idNimdp.toFixed(2)+'<span>mdp</span></td><td class="col_4 '+esigual+'">$ 0.0 <span>mdp</span></td></tr>');
			}
		}
	});

	$('#wrapper').html( $(".tablafinal").html());

	});
		
});
