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
// metodoSankeys([{renderAt: 'sankey-nta', url: '/jsonSankeyNTA.php?corte=v3-grupoedad'}, …])
//   Dibuja cada Sankey y deja el dataSource recibido en window.metodoSankeyData[renderAt]
//   (lo lee el gate 05_scripts/test-sitio-nta.js para comparar contra el JSON de origen).
//
// metodoCifras({url: '/jsonSankeyNTA.php?cuenta=grupoedad'})
//   Lee el JSON de la cuenta NTA por grupo (NTA.do §6.2) y llena cada <span data-nta="ruta.en.el.json"
//   data-nta-unidad="bn|pct|factor|mxn|texto"> del documento con el valor del archivo. Las rutas apuntan a
//   claves del JSON (p. ej. S_vs_B8n.S_sin_ajuste, grupos.0.Intra); si la clave no existe el span dice
//   «n/a». Deja el JSON en window.metodoCuentaData (para el gate).
//
// metodoPanel({url: '/jsonSankeyNTA.php?cuenta=panel-grupoedad-sexo', contenedor: 'nta-panel', selector: 'nta-sexo'})
//   (v8.12.6, NTA-3) Lee UNA vez el panel por grupo de edad × sexo (NTA.do §7c, esquema nta-panel/v1: 5 grupos ×
//   Total/Hombres/Mujeres) y dibuja un mini-Sankey por grupo (entradas → «grupo» → salidas; SVG propio, abajo) en los
//   cinco <div id="<contenedor>-<g>"> del documento, con el título (etiqueta del grupo tal cual la emite el motor) y el
//   pie (déficit de ciclo de vida C − YL y S, leídos del JSON) de cada uno. El selector (radios name=<selector>,
//   valores T/H/M) redibuja los cinco paneles, sin recarga: las tres variantes viajan en el mismo archivo. Cada cinta
//   lleva el valor del JSON tal cual (sin redondeo); los flujos en cero no se dibujan.
//   Deja el JSON en window.metodoPanelData y la celda y los flujos vigentes de cada grupo en window.metodoPanelSources[g].
window.metodoSankeyData = window.metodoSankeyData || {};
window.metodoCuentaData = window.metodoCuentaData || null;
window.metodoPanelData = window.metodoPanelData || null;
window.metodoPanelSources = window.metodoPanelSources || {};

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

// --- Panel por grupo de edad × sexo (v8.12.6, NTA-3) ---
// Los cinco mini-Sankeys NO usan FusionCharts: a ~200 px de ancho (cinco en fila) FusionCharts trunca toda etiqueta
// a unos 35 px («In…», «τ…») en cualquier posición (start/end/inside, márgenes a cero, fuente menor), y el panel existe
// para LEER la cuenta por grupo. Se dibujan con SVG propio: una columna de barras de entradas a la izquierda, la barra
// del grupo al centro, una columna de salidas a la derecha y una cinta por flujo; etiquetas completas (las del JSON)
// sobre las cintas y el valor en el tooltip (<title>). Cada cinta lleva data-from / data-to / data-value con el valor
// del JSON tal cual (lo lee el gate 05_scripts/test-sitio-nta.js). Paleta: la del tema «fusion» del Sankey principal.
var METODO_PALETA = ['#5d62b5', '#29c3be', '#f2726f', '#ffc533', '#62b58f', '#bc95df', '#67cdf2', '#8d95c7', '#f7a35c'];

function metodoEscapa(s) {
	return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

// Flujos > 0 de una celda, en el orden del catálogo del JSON (entradas y salidas).
function metodoPanelFlujos(panel, celda) {
	var ent = panel.entradas.map(function (e) { return {id: e.id, label: e.etiqueta, v: celda.entradas_flujos[e.id]}; }).filter(function (x) { return x.v > 0; });
	var sal = panel.salidas.map(function (s) { return {id: s.id, label: s.etiqueta, v: celda.salidas_flujos[s.id]}; }).filter(function (x) { return x.v > 0; });
	return {entradas: ent, salidas: sal};
}

// Dibuja el mini-Sankey de una celda en el contenedor (ancho y alto del contenedor; se redibuja al cambiar de tamaño).
function metodoMiniSankey(caja, panel, celda) {
	var W = caja.clientWidth || 200;
	var H = caja.clientHeight || 360;
	var f = metodoPanelFlujos(panel, celda);
	var ent = f.entradas, sal = f.salidas;
	var pad = 6, barW = 8, gap = 5, minH = 1.5, fuente = 10, linea = 10, anchoCar = 6;
	// etiquetas confinadas a su mitad del ancho (las de entrada a la izquierda del centro, las de salida a la derecha),
	// partidas por palabras en hasta dos líneas de maxCar caracteres (Roboto Mono 10 px ≈ 6 px por carácter)
	var maxCar = Math.max(6, Math.floor((W / 2 - barW - 12) / anchoCar));
	function partir(label) {
		var lineas = [], actual = '';
		String(label).split(' ').forEach(function (p) {
			if (actual === '') actual = p;
			else if ((actual + ' ' + p).length <= maxCar) actual += ' ' + p;
			else { lineas.push(actual); actual = p; }
		});
		if (actual !== '') lineas.push(actual);
		if (lineas.length > 2) { lineas = lineas.slice(0, 2); lineas[1] = lineas[1].slice(0, Math.max(1, maxCar - 1)) + '…'; }
		return lineas.map(function (l) { return l.length > maxCar ? l.slice(0, Math.max(1, maxCar - 1)) + '…' : l; });
	}
	var sumaEnt = ent.reduce(function (a, x) { return a + x.v; }, 0);
	var sumaSal = sal.reduce(function (a, x) { return a + x.v; }, 0);
	var tot = Math.max(sumaEnt, sumaSal);
	var n = Math.max(ent.length, sal.length);
	var k = tot > 0 ? (H - 2 * pad - gap * (n - 1)) / tot : 0;
	// alturas y posiciones de cada columna (una pasada; la barra del centro acumula sin huecos)
	function columna(lista) {
		var y = pad, cy = pad, out = [];
		lista.forEach(function (x) {
			var h = Math.max(x.v * k, minH);
			out.push({id: x.id, label: x.label, v: x.v, y0: y, y1: y + h, c0: cy, c1: cy + h});
			y += h + gap; cy += h;
		});
		return out;
	}
	var E = columna(ent), S = columna(sal);
	var cH = Math.max(E.length ? E[E.length - 1].c1 : pad, S.length ? S[S.length - 1].c1 : pad) - pad;
	var cx = W / 2 - barW / 2;
	var xl = pad, xr = W - pad - barW;
	// etiquetas: centradas en su barra, sin encimarse (se empujan hacia abajo y, si se salen por abajo, suben solo las necesarias);
	// cada una sabe sus líneas y la y (baseline) de la primera
	function etiquetas(col) {
		var out = [], fondo = -Infinity;
		col.forEach(function (b) {
			var lineas = partir(b.label);
			var alto = lineas.length * linea;
			var top = (b.y0 + b.y1) / 2 - alto / 2;
			if (top < fondo + 2) top = fondo + 2;
			out.push({lineas: lineas, top: top, alto: alto, label: b.label});
			fondo = top + alto;
		});
		// segunda pasada, desde abajo: la que se sale del alto sube, y empuja hacia arriba solo a las que estorban
		var limite = H - 2;
		for (var i = out.length - 1; i >= 0; i--) {
			if (out[i].top + out[i].alto > limite) out[i].top = limite - out[i].alto;
			limite = out[i].top - 2;
		}
		return out;
	}
	function texto(x, anchor, o) {
		var s = '';
		o.lineas.forEach(function (l, j) {
			s += '<text class="metodo-mini-etiqueta" x="' + x + '" y="' + (o.top + fuente * 0.8 + j * linea) + '" text-anchor="' + anchor + '"' + (j === 0 ? ' data-etiqueta="' + metodoEscapa(o.label) + '"' : '') + '>' + metodoEscapa(l) + '</text>';
		});
		return s;
	}
	var yE = etiquetas(E), yS = etiquetas(S);
	// (sin xmlns: el SVG entra por innerHTML en un documento HTML, que ya lo conoce; así el archivo sigue sin literales numéricos)
	var svg = ['<svg width="' + W + '" height="' + H + '" viewBox="0 0 ' + W + ' ' + H + '" role="img" aria-label="' + metodoEscapa(celda.grupo + ' · ' + celda.sexo) + '">'];
	function cinta(x0, a0, a1, x1, b0, b1, color, from, to, v) {
		var xm = (x0 + x1) / 2;
		var d = 'M' + x0 + ',' + a0 + ' C' + xm + ',' + a0 + ' ' + xm + ',' + b0 + ' ' + x1 + ',' + b0 + ' L' + x1 + ',' + b1 + ' C' + xm + ',' + b1 + ' ' + xm + ',' + a1 + ' ' + x0 + ',' + a1 + ' Z';
		svg.push('<path class="metodo-mini-flujo" d="' + d + '" fill="' + color + '" fill-opacity="0.3" data-from="' + metodoEscapa(from) + '" data-to="' + metodoEscapa(to) + '" data-value="' + metodoEscapa(String(v)) + '"><title>' + metodoEscapa(from + ' → ' + to + ': ' + metodoFormato(v, 'bn') + ' bn MXN') + '</title></path>');
	}
	E.forEach(function (b, i) {
		var color = METODO_PALETA[i % METODO_PALETA.length];
		cinta(xl + barW, b.y0, b.y1, cx, b.c0, b.c1, color, b.label, celda.grupo, b.v);
		svg.push('<rect class="metodo-mini-barra" x="' + xl + '" y="' + b.y0 + '" width="' + barW + '" height="' + (b.y1 - b.y0) + '" fill="' + color + '"><title>' + metodoEscapa(b.label + ': ' + metodoFormato(b.v, 'bn') + ' bn MXN') + '</title></rect>');
		svg.push(texto(xl + barW + 4, 'start', yE[i]));
	});
	S.forEach(function (b, i) {
		var color = METODO_PALETA[(i + E.length) % METODO_PALETA.length];
		cinta(cx + barW, b.c0, b.c1, xr, b.y0, b.y1, color, celda.grupo, b.label, b.v);
		svg.push('<rect class="metodo-mini-barra" x="' + xr + '" y="' + b.y0 + '" width="' + barW + '" height="' + (b.y1 - b.y0) + '" fill="' + color + '"><title>' + metodoEscapa(b.label + ': ' + metodoFormato(b.v, 'bn') + ' bn MXN') + '</title></rect>');
		svg.push(texto(xr - 4, 'end', yS[i]));
	});
	svg.push('<rect class="metodo-mini-centro" x="' + cx + '" y="' + pad + '" width="' + barW + '" height="' + cH + '" fill="' + '#333' + '"><title>' + metodoEscapa(celda.grupo + ' (' + celda.sexo + '): inflows = outflows = ' + metodoFormato(tot, 'bn') + ' bn MXN') + '</title></rect>');
	svg.push('</svg>');
	caja.innerHTML = svg.join('');
	return f;
}

function metodoPanel(cfg) {
	var contenedor = cfg.contenedor || 'nta-panel';
	var selector = cfg.selector || 'nta-sexo';
	var celdaDe = function (panel, g, s) {
		return panel.celdas.filter(function (c) { return String(c.g) === String(g) && c.s === s; })[0];
	};
	var pintar = function (panel, s) {
		panel.grupos.forEach(function (gr) {
			var g = gr.g;
			var celda = celdaDe(panel, g, s);
			var caja = document.getElementById(contenedor + '-' + g);
			if (!caja || !celda) return;
			var tarjeta = caja.closest('.metodo-panel-celda') || caja.parentNode;
			tarjeta.querySelectorAll('[data-panel]').forEach(function (el) {
				var clave = el.getAttribute('data-panel');
				el.textContent = clave === 'grupo' || clave === 'sexo' ? String(celda[clave]) : metodoFormato(celda[clave], el.getAttribute('data-panel-unidad') || 'bn');
				el.classList.add('metodo-cifra-ok');
			});
			window.metodoPanelSources[g] = {celda: celda, flujos: metodoMiniSankey(caja, panel, celda)};
		});
	};
	$.ajax({
		type: 'get',
		url: cfg.url,
		dataType: 'json',
		success: function (panel) {
			window.metodoPanelData = panel;
			var radios = document.querySelectorAll('input[name="' + selector + '"]');
			var sexo = function () {
				var r = [].filter.call(radios, function (x) { return x.checked; })[0];
				return r ? r.value : 'T';
			};
			pintar(panel, sexo());
			radios.forEach(function (r) { r.addEventListener('change', function () { pintar(panel, sexo()); }); });
			var temporizador = null;
			window.addEventListener('resize', function () {
				clearTimeout(temporizador);
				temporizador = setTimeout(function () { pintar(panel, sexo()); }, 150);
			});
		},
		error: function (xhr) {
			var detalle = '';
			try { detalle = JSON.parse(xhr.responseText).error || ''; } catch (e) { detalle = xhr.statusText || ''; }
			var caja = document.getElementById(contenedor);
			if (caja) { caja.classList.add('metodo-sankey-error'); caja.textContent = 'The panel data could not be loaded (' + cfg.url + '). ' + detalle; }
		}
	});
}
