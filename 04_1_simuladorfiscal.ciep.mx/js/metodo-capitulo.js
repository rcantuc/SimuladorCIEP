// metodo-capitulo.js — pinta /metodo (índice, capítulo 0 y un capítulo por módulo) desde /metodo/metodo.json (8.18).
//
// Regla de la sección de método (la misma que /NTA y /entidades, arquitectura.md §6.3.1): la página no trae ni una
// frase ni un número del método; todo viene del JSON que genera 05_scripts/metodo.py leyendo el repo (headers de los
// módulos, SIM.do §0.8, memos CUAD-*, scn-celdas.md, manifest.json, fixtures). Este archivo solo sabe PINTAR: títulos de
// sección (los lee del JSON: vienen de plantilla-capitulo.md), tablas, listas y los rótulos de la interfaz. Cero literales
// numéricos de 4+ dígitos aquí (test-sitio-metodo.sh lo exige). Lo cargado queda en window.metodoData (lo lee el gate
// 05_scripts/test-sitio-metodo.js) y el contenedor marca data-metodo-estado="ok" cuando terminó de pintar.
//
// metodoCapitulo({url: '/metodo/metodo.json', pagina: 'indice' | 'capitulo' | 'cap0', capitulo: '<Modulo>'})
(function () {
	'use strict';

	// --- utilidades -----------------------------------------------------------------------------------------------
	function esc(s) {
		return String(s === undefined || s === null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
	}
	// Markdown mínimo de los memos y headers: `código`, **negrita**, *cursiva*, [texto](url) interno. Todo escapado antes.
	function md(s) {
		var h = esc(s);
		h = h.replace(/`([^`]+)`/g, function (m, c) { return '<code>' + c + '</code>'; });
		h = h.replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>');
		h = h.replace(/(^|[\s(])\*([^*\s][^*]*?)\*(?=[\s).,;:]|$)/g, '$1<i>$2</i>');
		h = h.replace(/\[([^\]]+)\]\((\/[^)\s]+)\)/g, '<a href="$2">$1</a>');
		return h;
	}
	function el(tag, attrs, html) {
		var e = document.createElement(tag);
		if (attrs) Object.keys(attrs).forEach(function (k) { e.setAttribute(k, attrs[k]); });
		if (html !== undefined) e.innerHTML = html;
		return e;
	}
	function sello(s) {
		var clase = {verde: 'verde', amarillo: 'amarillo', rojo: 'rojo'}[s] || 'sin';
		return '<span class="metodo-sello metodo-sello-' + clase + '" data-sello="' + esc(s) + '">' + esc(s) + '</span>';
	}
	function tabla(columnas, filas, opciones) {
		opciones = opciones || {};
		var t = el('table', {'class': 'table table-sm metodo-tabla metodo-tabla-generada'});
		if (opciones.caption) t.appendChild(el('caption', null, opciones.caption));
		var thead = el('thead'), tr = el('tr');
		columnas.forEach(function (c) { tr.appendChild(el('th', null, md(c))); });
		thead.appendChild(tr); t.appendChild(thead);
		var tbody = el('tbody');
		filas.forEach(function (f) {
			var r = el('tr');
			columnas.forEach(function (c, i) {
				var v = f[i] === undefined ? '' : f[i];
				var celda = el('td', {'data-col': esc(c)});
				celda.innerHTML = (c.toLowerCase().indexOf('sello') === 0 && v) ? sello(String(v).replace(/\*/g, '').trim()) : md(v);
				r.appendChild(celda);
			});
			tbody.appendChild(r);
		});
		t.appendChild(tbody);
		var caja = el('div', {'class': 'table-responsive metodo-tabla-caja'});
		caja.appendChild(t);
		return caja;
	}
	function llena(raiz, data) {
		// <span data-metodo="ruta.en.el.json"> → texto del JSON (como metodoCifras en /NTA)
		raiz.querySelectorAll('[data-metodo]').forEach(function (s) {
			var v = data;
			s.getAttribute('data-metodo').split('.').forEach(function (k) { v = (v !== undefined && v !== null) ? v[k] : undefined; });
			if (v === undefined || v === null || v === '') { s.textContent = '—'; s.classList.add('metodo-cifra-nd'); }
			else { s.textContent = String(v); s.classList.add('metodo-cifra-ok'); }
		});
	}
	function fuente(txt) {
		return txt ? '<p class="metodo-fuente-bloque">Fuente: ' + md(txt) + '</p>' : '';
	}

	// --- índice ----------------------------------------------------------------------------------------------------
	function pintaIndice(cont, d) {
		var h = '';
		h += '<p class="metodo-intro">Un capítulo por módulo del motor, en el orden en que <code>SIM.do</code> los invoca, con las diez secciones de la plantilla ' +
			'(<code><span data-metodo="plantilla"></span></code>). Cada capítulo se genera del repositorio (<code><span data-metodo="generador"></span></code>): ' +
			'headers de los módulos, <code>SIM.do</code> §0.8, memos CUAD, inventario del SCN, manifest y fixtures de la última corrida. Versión <b><span data-metodo="version"></span></b>, ' +
			'baseline <b><span data-metodo="baseline"></span></b>, ENIGH <span data-metodo="enigh_vintage"></span>, datos al <span data-metodo="data_updated"></span>; ' +
			'años del motor: ENIGH <span data-metodo="anios.anioenigh"></span>, Paquete <span data-metodo="anios.anioPE"></span>, valor presente <span data-metodo="anios.aniovp"></span>.</p>';
		h += '<p class="lead-nota">Sello de un capítulo: rojo si le falta una sección obligatoria del header (§' + d.obligatorias.join(', §') + '; FLAG «header incompleto») y, si no, el peor sello declarado en sus entradas (§2) y anclas (§5): ' +
			sello('verde') + ' oficial y estable · ' + sello('amarillo') + ' oficial con vintage ambiguo · ' + sello('rojo') + ' reconstruida o imputada · ' + sello('sin sello') + ' ninguna fila lo declara. ' +
			'Capítulos: <span data-metodo="resumen.capitulos"></span>; FLAGs abiertos: <span data-metodo="resumen.flags"></span>.</p>';
		cont.innerHTML = h;
		var filas = d.capitulos.map(function (c) {
			return [String(c.orden_en_SIM), '<a href="/metodo/' + c.modulo + '/">' + c.modulo + '</a>' + (c.pagina ? ' · <a href="' + c.pagina + '">' + c.pagina + '</a>' : ''),
				c.sim_seccion + (c.sim_linea ? ' (l. ' + c.sim_linea + ')' : ''), c.sello,
				String(c.conteos.entradas), String(c.conteos.anclas), String(c.conteos.decisiones), String(c.conteos.salidas), String(c.conteos.identidades),
				c.flags.length ? c.flags.join('; ') : '—'];
		});
		var cols = ['#', 'Capítulo', 'Sección de SIM.do', 'Sello', 'Entradas', 'Anclas', 'Decisiones', 'Salidas', 'Identidades', 'FLAGs'];
		var t = tabla(cols, filas, {caption: 'Capítulos, en el orden de <code>SIM.do</code>'});
		// los enlaces y los sellos van sin escapar (los construye esta función, no el JSON)
		t.querySelectorAll('tbody tr').forEach(function (tr, i) {
			tr.children[1].innerHTML = filas[i][1];
			tr.children[3].innerHTML = sello(filas[i][3]);
			tr.setAttribute('data-capitulo', d.capitulos[i].modulo);
		});
		cont.appendChild(t);
		var c0 = el('p', {'class': 'metodo-cap0-enlace'});
		c0.innerHTML = '<a href="/metodo/cap0/">Capítulo 0 — ' + esc(d.cap0.titulo) + '</a>: lo que hace falta para replicar el simulador en otro país (una fila por elemento específico de México de cada capítulo).';
		cont.appendChild(c0);
		llena(cont, d);
	}

	// --- capítulo --------------------------------------------------------------------------------------------------
	function pintaEncabezado(c) {
		var h = '<dl class="metodo-meta">';
		h += '<dt>modulo</dt><dd><code>' + esc(c.modulo) + '</code>' + (c.pagina ? ' · salida publicada en <a href="' + esc(c.pagina) + '">' + esc(c.pagina) + '</a>' : '') + '</dd>';
		h += '<dt>archivo</dt><dd>' + c.archivos.map(function (a) { return '<code>' + esc(a.ruta) + '</code> (sha256 <code>' + esc(a.sha256) + '</code>, ' + esc(a.lineas) + ' líneas)'; }).join('<br>') + '</dd>';
		h += '<dt>orden_en_SIM</dt><dd>' + esc(c.orden_en_SIM) + ' · <code>SIM.do</code> ' + esc(c.sim_seccion) + (c.sim_linea ? ' (l. ' + esc(c.sim_linea) + ')' : '') + '</dd>';
		h += '<dt>desde_version</dt><dd>' + (c.desde_version ? esc(c.desde_version) + ' (línea <code>*! version</code> del header)' : '—') + '</dd>';
		h += '<dt>ultima_decision</dt><dd>' + (c.ultima_decision ? esc(c.ultima_decision) + ' (última fecha citada en el header)' : '—') + '</dd>';
		h += '<dt>sello</dt><dd>' + sello(c.sello) + (c.flags.length ? ' · FLAG: ' + c.flags.map(esc).join('; ') : '') + '</dd>';
		h += '</dl>';
		return h;
	}
	function pintaSeccion(cont, d, c, s) {
		var n = s.n, sec = c.secciones[String(n)];
		var caja = el('section', {'class': 'metodo-seccion', 'data-metodo-seccion': String(n), 'data-metodo-vacia': sec.vacia ? '1' : '0'});
		caja.appendChild(el('h2', null, esc(n) + '. ' + esc(s.titulo)));
		if (sec.vacia) {
			caja.appendChild(el('p', {'class': 'metodo-vacio'}, sec.flag ? 'FLAG ' + esc(sec.flag) + ': el header del módulo no trae esta sección; no se inventa texto.' : 'Sin contenido en el repo para esta sección.'));
			cont.appendChild(caja);
			return;
		}
		(sec.texto || []).forEach(function (p) { caja.appendChild(el('p', {'class': 'metodo-parrafo'}, md(p))); });
		if (n === 3 && c.pasos.length) {
			caja.appendChild(tabla(['Programa', '§', 'Qué hace (título de la sección del código)', 'Qué conserva', 'Dónde está'],
				c.pasos.map(function (p) { return [p.programa, p.n, p.hace, p.conserva, p.archivo + ' ' + p.lineas]; }),
				{caption: 'Bloques del código, uno por sección numerada («** N.N … **»); «qué conserva» solo donde el memo lo declara (tablas CUAD de esta sección)'}));
		}
		if (n === 4 && c.decisiones.length) {
			caja.appendChild(tabla(['Parámetro', 'Firmado / default', 'Alternativas', 'FLAG', 'Documento · memo', 'Qué hace', 'Lo lee'],
				c.decisiones.map(function (p) { return ['`' + p.parametro + '`', p.firmado !== undefined ? p.firmado : p.default, p.alternativas || '', p.flag ? '«' + p.flag + '»' : '', [p.documento, p.memo].filter(Boolean).join(' · '), p.texto, p.lee || '']; }),
				{caption: 'Decisiones: parámetros con default y FLAG (header §4 del módulo y <code>SIM.do</code> §0.8–§0.8c; alternativas de las tablas §4 de los memos)'}));
		}
		if (n === 8 && c.limites.length) {
			caja.appendChild(tabla(['FLAG', 'Qué dice el header', 'Fuente'], c.limites.map(function (f) { return [f.flag, f.texto, f.fuente]; }), {caption: 'FLAGs del header del módulo'}));
		}
		if (n === 6 && sec.lista.length) {
			caja.appendChild(tabla(['Archivo / página', 'Qué contiene', 'Quién lo consume', 'Check'], sec.lista.map(function (f) { return [f.archivo, f.contiene, f.consume, f.check]; })));
		}
		if (n === 10 && c.procedencia.length) {
			caja.appendChild(tabla(['Sección', 'Archivo', 'Líneas', 'Nota'], c.procedencia.map(function (p) { return ['§' + p.seccion, p.archivo, p.lineas, p.nota]; }),
				{caption: 'De dónde se generó cada sección (el capítulo no dice nada que estos archivos no digan)'}));
		}
		(sec.tablas || []).forEach(function (tb) {
			var cap = (tb.titulo ? md(tb.titulo) : '') + (tb.nota ? ' — ' + md(tb.nota) : '');
			caja.appendChild(tabla(tb.columnas, tb.filas, {caption: cap}));
			if (tb.fuente) caja.insertAdjacentHTML('beforeend', fuente(tb.fuente));
		});
		cont.appendChild(caja);
	}
	function pintaCapitulo(cont, d, slug) {
		var c = null;
		d.capitulos.forEach(function (x) { if (x.modulo === slug) c = x; });
		if (!c) { cont.innerHTML = '<p class="metodo-vacio">No hay capítulo «' + esc(slug) + '» en metodo.json.</p>'; return false; }
		cont.innerHTML = pintaEncabezado(c);
		var nav = el('p', {'class': 'metodo-nav-caps'});
		var ant = d.capitulos[c.orden_en_SIM - 2], sig = d.capitulos[c.orden_en_SIM];
		nav.innerHTML = '<a href="/metodo/">Índice</a>' + (ant ? ' · anterior: <a href="/metodo/' + esc(ant.modulo) + '/">' + esc(ant.modulo) + '</a>' : '') + (sig ? ' · siguiente: <a href="/metodo/' + esc(sig.modulo) + '/">' + esc(sig.modulo) + '</a>' : '');
		cont.appendChild(nav);
		d.secciones.forEach(function (s) { pintaSeccion(cont, d, c, s); });
		return true;
	}

	// --- capítulo 0 -------------------------------------------------------------------------------------------------
	function pintaCap0(cont, d) {
		var c = d.cap0;
		cont.innerHTML = '<p class="metodo-intro">' + md(c.intro) + '</p><p class="lead-nota">Fuente: <code>' + esc(c.archivo) + '</code> (sha256 <code>' + esc(c.sha256) + '</code>). Cada fila nace de la sección 9 de un capítulo; la columna «Otro país» se publica vacía para que la llene quien replica.</p>';
		c.secciones.forEach(function (s) {
			var caja = el('section', {'class': 'metodo-seccion', 'data-metodo-seccion': s.titulo.split(' ')[0]});
			caja.appendChild(el('h2', null, esc(s.titulo)));
			s.bloques.forEach(function (b) {
				if (b.tipo === 'texto') caja.appendChild(el('p', {'class': 'metodo-parrafo'}, md(b.texto)));
				else {
					caja.appendChild(tabla(b.columnas, b.filas, {caption: b.nota ? md(b.nota) : ''}));
					caja.insertAdjacentHTML('beforeend', fuente(b.fuente));
				}
			});
			cont.appendChild(caja);
		});
		var bib = el('section', {'class': 'metodo-seccion', 'data-metodo-seccion': 'bibliografia'});
		bib.appendChild(el('h2', null, 'Bibliografía del método (fuentes congeladas)'));
		bib.appendChild(tabla(d.bibliografia.columnas, d.bibliografia.filas));
		bib.insertAdjacentHTML('beforeend', fuente(d.bibliografia.fuente));
		cont.appendChild(bib);
	}

	// --- entrada --------------------------------------------------------------------------------------------------
	window.metodoCapitulo = function (cfg) {
		var cont = document.getElementById('metodo-contenido');
		if (!cont) return;
		fetch(cfg.url, {credentials: 'same-origin'}).then(function (r) {
			if (!r.ok) throw new Error('HTTP ' + r.status);
			return r.json();
		}).then(function (d) {
			window.metodoData = d;
			var ok = true;
			if (cfg.pagina === 'indice') pintaIndice(cont, d);
			else if (cfg.pagina === 'cap0') pintaCap0(cont, d);
			else ok = pintaCapitulo(cont, d, cfg.capitulo);
			cont.setAttribute('data-metodo-estado', ok ? 'ok' : 'error');
		}).catch(function (e) {
			cont.innerHTML = '<p class="metodo-vacio">No se pudo leer <code>' + esc(cfg.url) + '</code>: ' + esc(e.message) + '.</p>';
			cont.setAttribute('data-metodo-estado', 'error');
		});
	};
})();
