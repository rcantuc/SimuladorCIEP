// entidad.js — las páginas /entidades/<ABREV> (los cuatro productos + sellos) y el índice /entidades (v8.13.0).
//
// Cero números en este archivo: todo valor que se dibuja o se escribe viene de los JSON que sirve
// /jsonEntidad.php (users/<id>/<ABREV>/{meta.json, ciclo-vida.json, tasas-efectivas.json, sankey-<corte>.json}
// y users/<id>/entidades.json), sin redondeo ni transformación salvo el formato de presentación (unidades:
// bn = 1e9, mdp = 1e6, porcentajes con 1/2/3 decimales). Los sellos (celdas con n < sello_n o top-1 > sello_top1)
// se leen de meta.json: cada uno recibe una marca ⚠ en su gráfica, una línea en la lista bajo la gráfica y una
// nota al pie numerada (continuando la numeración de las notas de la página) con su n; nada se cablea aquí.
//
// entidadPagina(cfg)   cfg = {abrev, nombre, urls:{meta, ciclo, tasas, sankey (prefijo + corte)}, cortes, etiquetasCortes,
//                      excluirTasas, selector, ids:{…}} (lo escribe entidades/_entidad.php).
//   1. meta.json → llena los <span data-ent="ruta" data-ent-unidad="…"> y las notas de sellos.
//   2. Sankeys (FusionCharts, misma receta que la portada y /NTA): selector de corte (radios name=cfg.selector);
//      cada corte se pide una vez y se cachea; el dataSource recibido queda en window.entidadData.sankeys[corte].
//   3. Ciclo de vida (ApexCharts, la receta de «Tax burden by age» de la portada: barras horizontales apiladas por
//      grupo de deciles): dos gráficas, Hombres y Mujeres, categorías = quinquenios (del mayor al menor, como la
//      portada), valor = pct (% del neto de la entidad) tal cual viene; «⚠» en la etiqueta de las celdas selladas.
//   4. Tasas efectivas (SVG propio: la portada solo tiene PNG): barra = te de la entidad, marca = te nacional micro,
//      sin los impuestos de cfg.excluirTasas; rayado + ⚠ en los sellados.
//   5. Neto / PIBE (SVG propio): dos barras, entidad vs nacional, desde meta.json (pibe, nacional).
// entidadIndice(cfg)   cfg = {url, tabla}: llena la tabla de /entidades desde entidades.json.
// Todo lo recibido queda en window.entidadData (lo lee el gate 05_scripts/test-sitio-entidades.js).
window.entidadData = window.entidadData || {meta: null, ciclo: null, tasas: null, sankeys: {}, cicloSeries: {}, indice: null, notas: {}, corte: null};

var ENT_PALETA = ['#5d62b5', '#29c3be', '#f2726f', '#ffc533', '#62b58f', '#bc95df', '#67cdf2', '#8d95c7', '#f7a35c'];
var ENT_COLOR_SELLO = '#c0392b';

function entidadEscapa(s) {
	return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

// Formato de presentación. bn: MXN / 1e9 con un decimal; mdp: MXN / 1e6 sin decimales; pct: 1 decimal; pct2: 2;
// pct3: 3; share: fracción × 100 con 2 decimales; signo-pct2: 2 decimales con signo; entero: separador de miles;
// top1: 1 decimal; coincide: texto según true/false/null; texto: tal cual.
function entidadFormato(valor, unidad) {
	if (valor === undefined || valor === null) return 'n/a';
	if (unidad === 'texto') return String(valor);
	if (unidad === 'coincide') return valor === true ? ' (they coincide)' : (valor === false ? ' (they differ in this run: see the deploy report)' : '');
	var v = Number(valor);
	if (isNaN(v)) return String(valor);
	var opts = {maximumFractionDigits: 0}, signo = false;
	if (unidad === 'bn') { v = v / 1e9; opts = {minimumFractionDigits: 1, maximumFractionDigits: 1}; }
	else if (unidad === 'mdp') { v = v / 1e6; }
	else if (unidad === 'pct' || unidad === 'top1') opts = {minimumFractionDigits: 1, maximumFractionDigits: 1};
	else if (unidad === 'pct2') opts = {minimumFractionDigits: 2, maximumFractionDigits: 2};
	else if (unidad === 'pct3') opts = {minimumFractionDigits: 3, maximumFractionDigits: 3};
	else if (unidad === 'share') { v = v * 100; opts = {minimumFractionDigits: 2, maximumFractionDigits: 2}; }
	else if (unidad === 'signo-pct2') { opts = {minimumFractionDigits: 2, maximumFractionDigits: 2}; signo = true; }
	var s = v.toLocaleString('en-US', opts);
	if (signo && v > 0) s = '+' + s;
	return s;
}

function entidadLee(obj, ruta) {
	var v = obj;
	String(ruta).split('.').forEach(function (k) { v = (v !== undefined && v !== null) ? v[k] : undefined; });
	return v;
}

// Llena los <span data-<attr>="ruta" data-<attr>-unidad="…"> dentro de raiz con los valores de datos.
function entidadLlena(raiz, attr, datos) {
	raiz.querySelectorAll('[' + attr + ']').forEach(function (el) {
		var v = entidadLee(datos, el.getAttribute(attr));
		el.textContent = entidadFormato(v, el.getAttribute(attr + '-unidad') || 'texto');
		el.classList.add(v === undefined || v === null ? 'metodo-cifra-nd' : 'metodo-cifra-ok');
	});
}

function entidadAjax(url, ok, err) {
	$.ajax({type: 'get', url: url, dataType: 'json', success: ok, error: function (xhr) {
		var detalle = '';
		try { detalle = JSON.parse(xhr.responseText).error || ''; } catch (e) { detalle = xhr.statusText || ''; }
		err(detalle, xhr);
	}});
}

function entidadError(id, url, detalle) {
	var caja = document.getElementById(id);
	if (caja) { caja.classList.add('metodo-sankey-error'); caja.textContent = 'The data could not be loaded (' + url + '). ' + detalle; }
}

// --- sellos: catálogo de celdas selladas de la entidad (meta.json), con su número de nota al pie ---
// Devuelve la lista [{clave, producto, corte, celda, n, top1, motivo, nota}] en el orden de la página
// (Sankeys por corte, ciclo, tasas). La numeración continúa la de las notas ya escritas en <ol class="metodo-notas">.
function entidadSellos(meta, cfg) {
	var lista = [];
	var S = meta.sellos || {};
	(cfg.cortes || []).forEach(function (c) {
		var sk = S.sankeys && S.sankeys[c];
		if (!sk) return;
		(sk.sellados || []).forEach(function (l) {
			lista.push({clave: 'sankey:' + c + ':' + l.from + '→' + l.to, producto: 'sankey', corte: c, celda: l.from.trim() + ' → ' + l.to.trim(), n: l.n, top1: l.top1, motivo: l.motivo});
		});
	});
	(S.ciclo || []).forEach(function (x) {
		lista.push({clave: 'ciclo:' + x.sexo + ':' + x.quinquenio, producto: 'ciclo', sexo: x.sexo, s: x.s, quinquenio: x.quinquenio, celda: x.sexo + ' ' + x.quinquenio, n: x.n, top1: Math.max(x.top1_aporta, x.top1_recibe), motivo: x.motivo});
	});
	(S.tasas || []).forEach(function (t) {
		lista.push({clave: 'tasas:' + t.impuesto, producto: 'tasas', impuesto: t.impuesto, celda: t.impuesto, n: t.n, top1: t.top1, motivo: t.motivo});
	});
	var ol = document.querySelector('ol.metodo-notas');
	var base = ol ? ol.querySelectorAll('li').length : 0;
	lista.forEach(function (x, i) { x.nota = base + i + 1; window.entidadData.notas[x.clave] = x; });
	return lista;
}

function entidadTextoSello(x) {
	var t = 'n = ' + entidadFormato(x.n, 'entero') + ' in this cell';
	if (x.motivo && x.motivo.indexOf('top1') >= 0) t += (x.motivo === 'top1' ? ', and' : ';') + ' one person accounts for ' + entidadFormato(x.top1, 'top1') + ' % of its amount';
	return t + '; read as indicative.';
}

function entidadNotaRef(x) {
	return '<sup class="metodo-nota-ref" id="ref-' + x.nota + '"><a href="#nota-' + x.nota + '" aria-label="Note ' + x.nota + '">' + x.nota + '</a></sup>';
}

// Escribe las notas al pie de los sellos a continuación de las de la página.
function entidadNotasSellos(lista, cfg) {
	var ol = document.querySelector('ol.metodo-notas');
	if (!ol) return;
	var nombres = {sankey: 'Sankey', ciclo: 'Lifecycle', tasas: 'Effective rate'};
	lista.forEach(function (x) {
		var li = document.createElement('li');
		li.id = 'nota-' + x.nota; li.value = x.nota;
		li.setAttribute('data-sello', x.clave); li.setAttribute('data-producto', x.producto); li.setAttribute('data-n', String(x.n));
		var donde = x.producto === 'sankey' ? ' (' + ((cfg.etiquetasCortes || {})[x.corte] || x.corte) + ')' : '';
		li.innerHTML = '<b>⚠ Thin cell — ' + nombres[x.producto] + donde + ': ' + entidadEscapa(x.celda) + '.</b> ' + entidadEscapa(entidadTextoSello(x)) + ' <a class="metodo-nota-volver" href="#ref-' + x.nota + '" aria-label="Back to the text">&#8617;</a>';
		ol.appendChild(li);
	});
}

// La lista bajo una gráfica: las celdas selladas de ese producto (y corte), cada una con su superíndice.
function entidadListaSellos(id, items, titulo) {
	var caja = document.getElementById(id);
	if (!caja) return;
	if (!items.length) { caja.innerHTML = '<p class="ent-sellos-ninguno">No sealed cells in this chart.</p>'; return; }
	var h = '<p class="ent-sellos-titulo">' + entidadEscapa(titulo) + ' (' + items.length + '):</p><ul>';
	items.forEach(function (x) {
		h += '<li data-sello="' + entidadEscapa(x.clave) + '" data-n="' + entidadEscapa(String(x.n)) + '"><span class="ent-sello-marca">⚠</span> ' + entidadEscapa(x.celda) + ' — n = ' + entidadEscapa(entidadFormato(x.n, 'entero')) + (x.motivo && x.motivo.indexOf('top1') >= 0 ? ', top-1 ' + entidadEscapa(entidadFormato(x.top1, 'top1')) + ' %' : '') + entidadNotaRef(x) + '</li>';
	});
	caja.innerHTML = h + '</ul>';
}

// --- 2. Sankeys con selector de corte (FusionCharts) ---
function entidadSankeys(cfg, sellos) {
	var id = cfg.ids.sankey, radios = document.querySelectorAll('input[name="' + cfg.selector + '"]');
	var D = window.entidadData;
	var pintar = function (corte) {
		var ds = D.sankeys[corte];
		D.corte = corte;
		FusionCharts.ready(function () {
			var previo = FusionCharts.items[id + '-chart'];
			if (previo) previo.dispose();
			new FusionCharts({id: id + '-chart', type: 'sankey', renderAt: id, width: '100%', height: '100%', dataFormat: 'json', dataSource: ds}).render();
		});
		entidadListaSellos(cfg.ids.sankeySellos, sellos.filter(function (x) { return x.producto === 'sankey' && x.corte === corte; }), 'Sealed links in this cut');
	};
	var carga = function (corte) {
		if (D.sankeys[corte]) { pintar(corte); return; }
		entidadAjax(cfg.urls.sankey + encodeURIComponent(corte), function (ds) { D.sankeys[corte] = ds; pintar(corte); }, function (det) { entidadError(id, cfg.urls.sankey + corte, det); });
	};
	var elegido = function () {
		var r = [].filter.call(radios, function (x) { return x.checked; })[0];
		return r ? r.value : (cfg.cortes || [])[0];
	};
	radios.forEach(function (r) { r.addEventListener('change', function () { carga(elegido()); }); });
	carga(elegido());
}

// --- 3. Ciclo de vida (ApexCharts, receta de la portada) ---
function entidadCiclo(cfg, sellos) {
	var D = window.entidadData;
	entidadAjax(cfg.urls.ciclo, function (ciclo) {
		D.ciclo = ciclo;
		var etiquetas = ciclo.grupos.etiquetas;
		[['Hombres', 'H', cfg.ids.cicloH], ['Mujeres', 'M', cfg.ids.cicloM]].forEach(function (par) {
			var sexo = par[0], s = par[1], id = par[2];
			var celdas = ciclo.celdas.filter(function (c) { return c.sexo === sexo; }).sort(function (a, b) { return b.g - a.g; });
			var sellados = {};
			sellos.forEach(function (x) { if (x.producto === 'ciclo' && x.sexo === sexo) sellados[x.quinquenio] = x; });
			var categorias = celdas.map(function (c) { return c.quinquenio + (sellados[c.quinquenio] ? ' ⚠' : ''); });
			var series = etiquetas.map(function (et) {
				return {name: et, data: celdas.map(function (c) {
					var g = (c.grupos || []).filter(function (x) { return x.grupo === et; })[0];
					return g ? g.pct : null;
				})};
			});
			D.cicloSeries[s] = {categorias: categorias, series: series, quinquenios: celdas.map(function (c) { return c.quinquenio; })};
			var el = document.getElementById(id);
			if (!el) return;
			var opciones = {
				series: series,
				chart: {id: id, type: 'bar', fontFamily: 'Roboto Mono, monospace', height: el.clientHeight || el.offsetHeight, stacked: true, animations: {enabled: false}, toolbar: {show: false}},
				colors: ENT_PALETA.slice(0, etiquetas.length),
				plotOptions: {bar: {horizontal: true, barHeight: '90%'}},
				dataLabels: {enabled: false},
				stroke: {width: 1, colors: ['#fff']},
				grid: {xaxis: {lines: {show: false}}},
				xaxis: {categories: categorias, title: {text: (s === 'H' ? 'Men' : 'Women') + ': % of the state\'s net contribution'}, labels: {style: {colors: '#404040', fontSize: '9px'}}},
				yaxis: {labels: {style: {fontSize: '9px'}}},
				tooltip: {shared: false, y: {formatter: function (val) { return entidadFormato(val, 'pct3') + ' % of the state net'; }}},
				legend: {position: 'top'}
			};
			new ApexCharts(el, opciones).render();
		});
		entidadListaSellos(cfg.ids.cicloSellos, sellos.filter(function (x) { return x.producto === 'ciclo'; }), 'Sealed cells (sex × five-year group)');
	}, function (det) { entidadError(cfg.ids.cicloH, cfg.urls.ciclo, det); entidadError(cfg.ids.cicloM, cfg.urls.ciclo, det); });
}

// --- 4. Tasas efectivas (SVG propio) ---
function entidadTasas(cfg, sellos) {
	var D = window.entidadData;
	var caja = document.getElementById(cfg.ids.tasas);
	entidadAjax(cfg.urls.tasas, function (tasas) {
		D.tasas = tasas;
		if (!caja) return;
		var excl = cfg.excluirTasas || [];
		var filas = tasas.impuestos.filter(function (i) { return excl.indexOf(i.impuesto) < 0; });
		var sellados = {};
		sellos.forEach(function (x) { if (x.producto === 'tasas') sellados[x.impuesto] = x; });
		var W = caja.clientWidth || 700, filaH = 30, pad = 6, etqW = 150, valW = 190, barMax = Math.max(60, W - etqW - valW - 2 * pad), fuente = 11;
		var H = pad * 2 + filaH * filas.length + 18;
		var maximo = 0;
		filas.forEach(function (i) { maximo = Math.max(maximo, Math.abs(i.te), Math.abs(i.te_nacional_micro)); });
		var k = maximo > 0 ? barMax / maximo : 0;
		var svg = ['<svg width="' + W + '" height="' + H + '" viewBox="0 0 ' + W + ' ' + H + '" role="img" aria-label="Effective tax rates of the state vs national">'];
		svg.push('<defs><pattern id="ent-rayado" width="6" height="6" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="6" height="6" fill="' + ENT_PALETA[0] + '"/><line x1="0" y1="0" x2="0" y2="6" stroke="#fff" stroke-width="3"/></pattern></defs>');
		filas.forEach(function (i, j) {
			var y = pad + j * filaH, sel = sellados[i.impuesto];
			var x0 = pad + etqW, w = Math.max(1, Math.abs(i.te) * k), xn = x0 + Math.abs(i.te_nacional_micro) * k;
			svg.push('<text class="ent-tasas-etiqueta" x="' + (x0 - 6) + '" y="' + (y + filaH / 2 + 4) + '" text-anchor="end">' + entidadEscapa(i.impuesto) + (sel ? ' ⚠' : '') + '</text>');
			svg.push('<rect class="ent-tasas-barra" x="' + x0 + '" y="' + (y + 5) + '" width="' + w + '" height="' + (filaH - 10) + '" fill="' + (sel ? 'url(#ent-rayado)' : ENT_PALETA[0]) + '" data-impuesto="' + entidadEscapa(i.impuesto) + '" data-te="' + entidadEscapa(String(i.te)) + '" data-te-nacional="' + entidadEscapa(String(i.te_nacional_micro)) + '" data-sello="' + (sel ? '1' : '0') + '"><title>' + entidadEscapa(i.impuesto + ': state ' + entidadFormato(i.te, 'pct3') + ' % vs national ' + entidadFormato(i.te_nacional_micro, 'pct3') + ' % (' + entidadFormato(i.rel_vs_nac, 'signo-pct2') + ' pp)' + (sel ? ' — ⚠ ' + entidadTextoSello(sel) : '')) + '</title></rect>');
			svg.push('<line class="ent-tasas-nacional" x1="' + xn + '" y1="' + (y + 2) + '" x2="' + xn + '" y2="' + (y + filaH - 2) + '" stroke="#000" stroke-width="2"><title>' + entidadEscapa('national micro rate ' + entidadFormato(i.te_nacional_micro, 'pct3') + ' %') + '</title></line>');
			svg.push('<text class="ent-tasas-valor" x="' + (x0 + barMax + 8) + '" y="' + (y + filaH / 2 + 4) + '">' + entidadEscapa(entidadFormato(i.te, 'pct3') + ' % (nat. ' + entidadFormato(i.te_nacional_micro, 'pct3') + ' %)') + '</text>');
		});
		svg.push('<text class="ent-tasas-leyenda" x="' + (pad + etqW) + '" y="' + (H - 4) + '">bar = state effective rate (micro / micro, by residence) · tick = national micro rate · ⚠ = sealed</text>');
		svg.push('</svg>');
		caja.innerHTML = svg.join('');
		caja.setAttribute('data-filas', String(filas.length));
		entidadListaSellos(cfg.ids.tasasSellos, sellos.filter(function (x) { return x.producto === 'tasas'; }), 'Sealed rates');
	}, function (det) { entidadError(cfg.ids.tasas, cfg.urls.tasas, det); });
}

// --- 5. Neto del ciclo / PIBE (SVG propio, desde meta.json) ---
function entidadNeto(cfg, meta) {
	var caja = document.getElementById(cfg.ids.neto), cifra = document.getElementById(cfg.ids.netoCifra), nd = document.getElementById(cfg.ids.netoNd);
	if (!meta.pibe) {
		if (cifra) cifra.hidden = true;
		if (nd) nd.hidden = false;
		if (caja) caja.innerHTML = '';
		return;
	}
	if (!caja) return;
	var filas = [
		{etiqueta: meta.entidad.nombre + ' (net / PIBE)', v: meta.pibe.neto_pct_pibe, color: ENT_PALETA[0]},
		{etiqueta: 'National (net / GDP)', v: meta.nacional.neto_pct_pib, color: '#999'}
	];
	var W = caja.clientWidth || 700, filaH = 34, pad = 6, etqW = 230, valW = 90, barMax = Math.max(60, W - etqW - valW - 2 * pad);
	var H = pad * 2 + filaH * filas.length;
	var maximo = 0;
	filas.forEach(function (f) { maximo = Math.max(maximo, Math.abs(f.v)); });
	var k = maximo > 0 ? barMax / maximo : 0, hayNeg = filas.some(function (f) { return f.v < 0; });
	var cero = pad + etqW + (hayNeg ? barMax / 2 : 0), escala = hayNeg ? k / 2 : k;
	var svg = ['<svg width="' + W + '" height="' + H + '" viewBox="0 0 ' + W + ' ' + H + '" role="img" aria-label="Net lifecycle contribution as % of GDP: state vs national">'];
	filas.forEach(function (f, j) {
		var y = pad + j * filaH, w = Math.abs(f.v) * escala, x = f.v < 0 ? cero - w : cero;
		svg.push('<text class="ent-tasas-etiqueta" x="' + (pad + etqW - 6) + '" y="' + (y + filaH / 2 + 4) + '" text-anchor="end">' + entidadEscapa(f.etiqueta) + '</text>');
		svg.push('<rect class="ent-neto-barra" x="' + x + '" y="' + (y + 6) + '" width="' + Math.max(1, w) + '" height="' + (filaH - 12) + '" fill="' + f.color + '" data-value="' + entidadEscapa(String(f.v)) + '"><title>' + entidadEscapa(f.etiqueta + ': ' + entidadFormato(f.v, 'pct3') + ' %') + '</title></rect>');
		svg.push('<text class="ent-tasas-valor" x="' + (f.v < 0 ? cero + 6 : cero + w + 6) + '" y="' + (y + filaH / 2 + 4) + '">' + entidadEscapa(entidadFormato(f.v, 'pct3') + ' %') + '</text>');
	});
	svg.push('<line x1="' + cero + '" y1="' + pad + '" x2="' + cero + '" y2="' + (H - pad) + '" stroke="#000" stroke-width="1"/>');
	svg.push('</svg>');
	caja.innerHTML = svg.join('');
}

function entidadPagina(cfg) {
	var D = window.entidadData;
	entidadAjax(cfg.urls.meta, function (meta) {
		D.meta = meta;
		entidadLlena(document, 'data-ent', meta);
		var sellos = entidadSellos(meta, cfg);
		D.sellos = sellos;
		entidadNotasSellos(sellos, cfg);
		entidadNeto(cfg, meta);
		entidadSankeys(cfg, sellos);
		entidadCiclo(cfg, sellos);
		entidadTasas(cfg, sellos);
	}, function (det) {
		document.querySelectorAll('[data-ent]').forEach(function (el) { el.textContent = 'n/a'; el.classList.add('metodo-cifra-error'); });
		[cfg.ids.sankey, cfg.ids.cicloH, cfg.ids.cicloM, cfg.ids.tasas, cfg.ids.neto].forEach(function (id) { entidadError(id, cfg.urls.meta, det); });
	});
}

// --- /entidades: la tabla de las 32 desde entidades.json ---
function entidadIndice(cfg) {
	var D = window.entidadData;
	var tabla = document.getElementById(cfg.tabla);
	entidadAjax(cfg.url, function (indice) {
		D.indice = indice;
		entidadLlena(document, 'data-ind', indice);
		if (!tabla) return;
		var por = {};
		(indice.entidades || []).forEach(function (e) { por[e.abrev] = e; });
		tabla.querySelectorAll('tbody tr[data-abrev]').forEach(function (tr) {
			var e = por[tr.getAttribute('data-abrev')];
			tr.querySelectorAll('td[data-col]').forEach(function (td) {
				var col = td.getAttribute('data-col'), u = td.getAttribute('data-col-unidad') || 'texto';
				if (!e) { td.textContent = 'n/a'; td.classList.add('metodo-cifra-nd'); return; }
				if (col === 'top1') {
					var t = e.top1_n100 || {};
					td.textContent = t.pct !== undefined && t.pct !== null ? entidadFormato(t.pct, 'top1') + ' % · ' + (t.donde || '') : 'n/a';
				} else {
					td.textContent = entidadFormato(entidadLee(e, col), u);
				}
				td.classList.add('metodo-cifra-ok');
			});
			if (e && e.tabla_32_coincide === false) tr.classList.add('ent-fila-aviso');
		});
		tabla.setAttribute('data-filas-llenas', String((indice.entidades || []).length));
	}, function (det) {
		if (tabla) tabla.querySelectorAll('td[data-col]').forEach(function (td) { td.textContent = 'n/a'; td.classList.add('metodo-cifra-error'); });
		var p = document.getElementById('ent-indice-estado');
		if (p) p.textContent = 'The index data could not be loaded (' + cfg.url + '). ' + det;
	});
}
