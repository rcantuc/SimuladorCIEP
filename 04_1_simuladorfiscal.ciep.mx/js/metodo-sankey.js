// metodo-sankey.js — Sankeys estáticos y cifras de las páginas de método (/NTA, …).
//
// Misma receta que los cinco Sankeys de la portada (js/stataCalcula.js, bloque
// "Carga valores iniciales de sankey"): $.ajax al PHP de datos → FusionCharts
// type "sankey", width/height 100 %, dataFormat json, dataSource tal cual llega.
// No se importa stataCalcula.js porque ese archivo es el controlador completo de
// la portada (formulario, cronómetro, «Calcular», 40+ gráficas) y asume su DOM;
// aquí solo hace falta esta receta. Cero números en este archivo: todo valor que
// se dibuja o se escribe viene del JSON del motor, sin redondeo ni transformación
// (la única constante es la unidad de presentación: miles de millones = 1e9).
//
// metodoSankeys([{renderAt: 'sankey-nta', url: '/jsonSankeyNTA.php?corte=v2-grupoedad'}, …])
//   Dibuja cada Sankey y deja el dataSource recibido en window.metodoSankeyData[renderAt]
//   (lo lee el gate 05_scripts/test-sitio-nta.js para comparar contra el JSON de origen).
//
// metodoCifras({url: '/jsonSankeyNTA.php?cuenta=grupoedad'})
//   Lee el JSON de la cuenta NTA por grupo (NTA.do §6.2) y llena cada <span data-nta="ruta.en.el.json"
//   data-nta-unidad="bn|pct|factor|mxn|texto"> del documento con el valor del archivo. Las rutas apuntan a
//   claves del JSON (p. ej. S_vs_B8n.S_sin_ajuste, grupos.0.Intra); si la clave no existe el span dice
//   «n/a». Deja el JSON en window.metodoCuentaData (para el gate).
window.metodoSankeyData = window.metodoSankeyData || {};
window.metodoCuentaData = window.metodoCuentaData || null;

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

// Formato de presentación de un valor del JSON. bn: MXN / 1e9 con un decimal (como nta-identidad.txt);
// pct: porcentaje con un decimal; factor: cuatro decimales; mxn: entero con separador de miles; texto: tal cual.
function metodoFormato(valor, unidad) {
	if (valor === undefined || valor === null) return 'n/a';
	if (unidad === 'texto') return String(valor);
	var v = Number(valor);
	if (isNaN(v)) return String(valor);
	var opts;
	if (unidad === 'bn') { v = v / 1e9; opts = {minimumFractionDigits: 1, maximumFractionDigits: 1}; }
	else if (unidad === 'pct') opts = {minimumFractionDigits: 1, maximumFractionDigits: 1};
	else if (unidad === 'factor') opts = {minimumFractionDigits: 4, maximumFractionDigits: 4};
	else opts = {maximumFractionDigits: 0};
	return v.toLocaleString('en-US', opts);
}

function metodoCifras(cfg) {
	var spans = document.querySelectorAll('[data-nta]');
	if (!spans.length) return;
	$.ajax({
		type: 'get',
		url: cfg.url,
		dataType: 'json',
		success: function (cuenta) {
			window.metodoCuentaData = cuenta;
			spans.forEach(function (el) {
				var valor = cuenta;
				el.getAttribute('data-nta').split('.').forEach(function (k) {
					valor = (valor !== undefined && valor !== null) ? valor[k] : undefined;
				});
				el.textContent = metodoFormato(valor, el.getAttribute('data-nta-unidad') || 'bn');
				el.classList.add('metodo-cifra-ok');
			});
		},
		error: function () {
			spans.forEach(function (el) { el.textContent = 'n/a'; el.classList.add('metodo-cifra-error'); });
		}
	});
}
