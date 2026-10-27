// metodo-sankey.js — Sankeys estáticos de las páginas de método (/NTA, …).
//
// Misma receta que los cinco Sankeys de la portada (js/stataCalcula.js, bloque
// "Carga valores iniciales de sankey"): $.ajax al PHP de datos → FusionCharts
// type "sankey", width/height 100 %, dataFormat json, dataSource tal cual llega.
// No se importa stataCalcula.js porque ese archivo es el controlador completo de
// la portada (formulario, cronómetro, «Calcular», 40+ gráficas) y asume su DOM;
// aquí solo hace falta esta receta. Cero números en este archivo: todo valor que
// se dibuja viene del JSON del motor, sin redondeo ni transformación.
//
// metodoSankeys([{renderAt: 'sankey-nta', url: '/jsonSankeyNTA.php?corte=grupoedad'}, …])
// Deja cada dataSource recibido en window.metodoSankeyData[renderAt] (lo lee el
// gate 05_scripts/test-sitio-nta.js para comparar contra el JSON de origen).
window.metodoSankeyData = window.metodoSankeyData || {};

function metodoSankeys(lista) {
	(lista || []).forEach(function (cfg) {
		var contenedor = document.getElementById(cfg.renderAt);
		$.ajax({
			type: 'get',
			url: cfg.url,
			dataType: 'json',
			success: function (dataSource) {
				window.metodoSankeyData[cfg.renderAt] = dataSource;
				FusionCharts.ready(function () {
					new FusionCharts({
						id: cfg.renderAt + '-chart',
						type: 'sankey',
						renderAt: cfg.renderAt,
						width: '100%',
						height: '100%',
						dataFormat: 'json',
						dataSource: dataSource
					}).render();
				});
			},
			error: function (xhr) {
				var detalle = '';
				try { detalle = JSON.parse(xhr.responseText).error || ''; } catch (e) { detalle = xhr.statusText || ''; }
				if (contenedor) {
					contenedor.classList.add('metodo-sankey-error');
					contenedor.textContent = 'The chart data could not be loaded (' + cfg.url + '). ' + detalle;
				}
			}
		});
	});
}
