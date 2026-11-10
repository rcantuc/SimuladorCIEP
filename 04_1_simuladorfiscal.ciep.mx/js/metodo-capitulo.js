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
//
// Idioma (8.19): el de <html lang> (lo resuelve plantilla-metodo.php con ?lang=). En inglés lee /metodo/metodo-en.json (el
// mismo JSON con el texto pasado por 02_governance/metodo/traduccion-en.json, lo escribe metodo.py) y los rótulos de la
// interfaz salen de T.en; los enlaces internos conservan ?lang=en (el default de /metodo es español).
(function () {
	'use strict';

	var LANG = (document.documentElement.getAttribute('lang') || 'es').toLowerCase() === 'en' ? 'en' : 'es';
	var T = {
		es: {
			intro: 'Un capítulo por módulo del motor, en el orden en que <code>SIM.do</code> los invoca, con las diez secciones de la plantilla ',
			version: 'Versión', datos_al: 'datos al', anios: 'años del motor', paquete: 'Paquete', vp: 'valor presente',
			cols: ['#', 'Capítulo', 'Sección de SIM.do', 'Sello', 'Entradas', 'Anclas', 'Decisiones', 'Salidas', 'Identidades', 'FLAGs'],
			caption: 'Capítulos, en el orden de <code>SIM.do</code>',
			cap0: 'Capítulo 0', cap0_desc: 'lo que hace falta para replicar el simulador en otro país (una fila por elemento específico de México de cada capítulo).',
			nota: '<b>Nota.</b> Sello de un capítulo: rojo si le falta una sección obligatoria del header (§{obl}; FLAG «header incompleto») y, si no, el peor sello declarado en sus entradas (§2) y anclas (§5): ',
			s_verde: 'oficial y estable', s_amarillo: 'oficial con vintage ambiguo', s_rojo: 'reconstruida o imputada', s_sin: 'ninguna fila lo declara',
			n_caps: 'Capítulos', n_flags: 'FLAGs abiertos',
			sellos: {verde: 'verde', amarillo: 'amarillo', rojo: 'rojo', 'sin sello': 'sin sello'},
			salida_pub: 'salida publicada en', lineas: 'líneas', desde: 'línea <code>*! version</code> del header', ultima: 'última fecha citada en el header',
			vacia_flag: ': el header del módulo no trae esta sección; no se inventa texto.', vacia: 'Sin contenido en el repo para esta sección.',
			pasos_cols: ['Programa', '§', 'Qué hace (título de la sección del código)', 'Qué conserva', 'Dónde está'],
			pasos_cap: 'Bloques del código, uno por sección numerada («** N.N … **»); «qué conserva» solo donde el memo lo declara (tablas CUAD de esta sección)',
			dec_cols: ['Parámetro', 'Firmado / default', 'Alternativas', 'FLAG', 'Documento · memo', 'Qué hace', 'Lo lee'],
			dec_cap: 'Decisiones: parámetros con default y FLAG (header §4 del módulo y <code>SIM.do</code> §0.8–§0.8c; alternativas de las tablas §4 de los memos)',
			lim_cols: ['FLAG', 'Qué dice el header', 'Fuente'], lim_cap: 'FLAGs del header del módulo',
			sal_cols: ['Archivo / página', 'Qué contiene', 'Quién lo consume', 'Check'],
			pro_cols: ['Sección', 'Archivo', 'Líneas', 'Nota'], pro_cap: 'De dónde se generó cada sección (el capítulo no dice nada que estos archivos no digan)',
			fuente: 'Fuente', no_cap: 'No hay capítulo «{x}» en metodo.json.', indice: 'Índice', anterior: 'anterior', siguiente: 'siguiente',
			cap0_fuente: 'Cada fila nace de la sección 9 de un capítulo; la columna «Otro país» se publica vacía para que la llene quien replica.',
			bib: 'Bibliografía del método (fuentes congeladas)', error: 'No se pudo leer',
			meta: {modulo: 'modulo', archivo: 'archivo', orden: 'orden_en_SIM', desde: 'desde_version', ultima: 'ultima_decision', sello: 'sello'}
		},
		en: {
			intro: 'One chapter per engine module, in the order in which <code>SIM.do</code> calls them, with the ten sections of the template ',
			version: 'Version', datos_al: 'data as of', anios: 'engine years', paquete: 'Economic Package', vp: 'present value',
			cols: ['#', 'Chapter', 'SIM.do section', 'Seal', 'Inputs', 'Anchors', 'Decisions', 'Outputs', 'Identities', 'FLAGs'],
			caption: 'Chapters, in the order of <code>SIM.do</code>',
			cap0: 'Chapter 0', cap0_desc: 'what it takes to replicate the simulator in another country (one row per Mexico-specific element of each chapter).',
			nota: '<b>Note.</b> A chapter’s seal: red if the header lacks a mandatory section (§{obl}; FLAG “incomplete header”); otherwise, the worst seal declared in its inputs (§2) and anchors (§5): ',
			s_verde: 'official and stable', s_amarillo: 'official, ambiguous vintage', s_rojo: 'reconstructed or imputed', s_sin: 'no row declares one',
			n_caps: 'Chapters', n_flags: 'open FLAGs',
			sellos: {verde: 'green', amarillo: 'yellow', rojo: 'red', 'sin sello': 'no seal'},
			salida_pub: 'output published at', lineas: 'lines', desde: '<code>*! version</code> line of the header', ultima: 'latest date cited in the header',
			vacia_flag: ': the module header has no such section; no text is made up.', vacia: 'No content in the repository for this section.',
			pasos_cols: ['Program', '§', 'What it does (title of the code section)', 'What it preserves', 'Where'],
			pasos_cap: 'Code blocks, one per numbered section (“** N.N … **”); “what it preserves” only where the memo declares it (CUAD tables for this section)',
			dec_cols: ['Parameter', 'Signed / default', 'Alternatives', 'FLAG', 'Document · memo', 'What it does', 'Read by'],
			dec_cap: 'Decisions: parameters with default and FLAG (module header §4 and <code>SIM.do</code> §0.8–§0.8c; alternatives from the §4 tables of the memos)',
			lim_cols: ['FLAG', 'What the header says', 'Source'], lim_cap: 'FLAGs in the module header',
			sal_cols: ['File / page', 'What it contains', 'Who uses it', 'Check'],
			pro_cols: ['Section', 'File', 'Lines', 'Note'], pro_cap: 'Where each section was generated from (the chapter says nothing these files do not say)',
			fuente: 'Source', no_cap: 'There is no chapter “{x}” in metodo-en.json.', indice: 'Index', anterior: 'previous', siguiente: 'next',
			cap0_fuente: 'Each row comes from section 9 of a chapter; the “Other country” column is published empty, for whoever replicates the model to fill in.',
			bib: 'Bibliography of the method (frozen sources)', error: 'Could not read',
			meta: {modulo: 'module', archivo: 'file', orden: 'order in SIM.do', desde: 'since version', ultima: 'latest decision', sello: 'seal'}
		}
	}[LANG];
	// enlace interno dentro de /metodo, conservando el idioma (el default de /metodo es español)
	function url(ruta) { return LANG === 'en' ? ruta + '?lang=en' : ruta; }

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
		// el color sale de la primera palabra (verde/amarillo/rojo o green/yellow/red: una celda puede traer texto después,
		// «amarillo (vintage …)»); el rótulo es el sello en el idioma de la página, o la celda tal cual
		var primera = String(s).toLowerCase().split(/[\s(\/]/)[0];
		var clase = {verde: 'verde', amarillo: 'amarillo', rojo: 'rojo', green: 'verde', yellow: 'amarillo', red: 'rojo'}[primera] || 'sin';
		return '<span class="metodo-sello metodo-sello-' + clase + '" data-sello="' + esc(s) + '">' + esc(T.sellos[s] || s) + '</span>';
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
				celda.innerHTML = (/^(sello|seal)/i.test(c) && v) ? sello(String(v).replace(/\*/g, '').trim()) : md(v);
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
		return txt ? '<p class="metodo-fuente-bloque">' + T.fuente + ': ' + md(txt) + '</p>' : '';
	}

	// --- índice ----------------------------------------------------------------------------------------------------
	function pintaIndice(cont, d) {
		var h = '';
		h += '<p class="metodo-intro">' + T.intro +
			'(<code><span data-metodo="plantilla"></span></code>). ' +
			T.version + ' <b><span data-metodo="version"></span></b>, ' +
			'baseline <b><span data-metodo="baseline"></span></b>, ENIGH <span data-metodo="enigh_vintage"></span>, ' + T.datos_al + ' <span data-metodo="data_updated"></span>; ' +
			T.anios + ': ENIGH <span data-metodo="anios.anioenigh"></span>, ' + T.paquete + ' <span data-metodo="anios.anioPE"></span>, ' + T.vp + ' <span data-metodo="anios.aniovp"></span>.</p>';
		cont.innerHTML = h;
		var filas = d.capitulos.map(function (c) {
			return [String(c.orden_en_SIM), '<a href="' + url('/metodo/' + c.modulo + '/') + '">' + c.modulo + '</a>' + (c.pagina ? ' · <a href="' + c.pagina + (LANG === 'es' ? '?lang=es' : '') + '">' + c.pagina + '</a>' : ''),
				c.sim_seccion + (c.sim_linea ? ' (l. ' + c.sim_linea + ')' : ''), c.sello,
				String(c.conteos.entradas), String(c.conteos.anclas), String(c.conteos.decisiones), String(c.conteos.salidas), String(c.conteos.identidades),
				c.flags.length ? c.flags.join('; ') : '—'];
		});
		var cols = T.cols;
		var t = tabla(cols, filas, {caption: T.caption});
		// los enlaces y los sellos van sin escapar (los construye esta función, no el JSON)
		t.querySelectorAll('tbody tr').forEach(function (tr, i) {
			tr.children[1].innerHTML = filas[i][1];
			tr.children[3].innerHTML = sello(filas[i][3]);
			tr.setAttribute('data-capitulo', d.capitulos[i].modulo);
		});
		// Capítulo 0: primera fila de la tabla (una sola celda que ocupa el resto de las columnas)
		var tr0 = el('tr', {'class': 'metodo-cap0-fila', 'data-cap0': '1'});
		tr0.appendChild(el('td', {'data-col': '#'}, '0'));
		tr0.appendChild(el('td', {'colspan': String(cols.length - 1), 'data-col': cols[1]},
			'<a href="' + url('/metodo/cap0/') + '">' + T.cap0 + ' — ' + md(d.cap0.titulo) + '</a>: ' + T.cap0_desc));
		t.querySelector('tbody').insertBefore(tr0, t.querySelector('tbody').firstChild);
		cont.appendChild(t);
		var nota = el('div', null, '');
		h = '';
		h += '<p class="lead-nota metodo-nota-indice">' + T.nota.replace('{obl}', d.obligatorias.join(', §')) +
			sello('verde') + ' ' + T.s_verde + ' · ' + sello('amarillo') + ' ' + T.s_amarillo + ' · ' + sello('rojo') + ' ' + T.s_rojo + ' · ' + sello('sin sello') + ' ' + T.s_sin + '. ' +
			T.n_caps + ': <span data-metodo="resumen.capitulos"></span>; ' + T.n_flags + ': <span data-metodo="resumen.flags"></span>.</p>';
		nota.innerHTML = h;
		cont.appendChild(nota.firstChild);
		llena(cont, d);
	}

	// --- capítulo --------------------------------------------------------------------------------------------------
	function pintaEncabezado(c) {
		var h = '<dl class="metodo-meta">';
		h += '<dt>' + T.meta.modulo + '</dt><dd><code>' + esc(c.modulo) + '</code>' + (c.pagina ? ' · ' + T.salida_pub + ' <a href="' + esc(c.pagina) + (LANG === 'es' ? '?lang=es' : '') + '">' + esc(c.pagina) + '</a>' : '') + '</dd>';
		h += '<dt>' + T.meta.archivo + '</dt><dd>' + c.archivos.map(function (a) { return '<code>' + esc(a.ruta) + '</code> (sha256 <code>' + esc(a.sha256) + '</code>, ' + esc(a.lineas) + ' ' + T.lineas + ')'; }).join('<br>') + '</dd>';
		h += '<dt>' + T.meta.orden + '</dt><dd>' + esc(c.orden_en_SIM) + ' · <code>SIM.do</code> ' + esc(c.sim_seccion) + (c.sim_linea ? ' (l. ' + esc(c.sim_linea) + ')' : '') + '</dd>';
		h += '<dt>' + T.meta.desde + '</dt><dd>' + (c.desde_version ? esc(c.desde_version) + ' (' + T.desde + ')' : '—') + '</dd>';
		h += '<dt>' + T.meta.ultima + '</dt><dd>' + (c.ultima_decision ? esc(c.ultima_decision) + ' (' + T.ultima + ')' : '—') + '</dd>';
		h += '<dt>' + T.meta.sello + '</dt><dd>' + sello(c.sello) + (c.flags.length ? ' · FLAG: ' + c.flags.map(esc).join('; ') : '') + '</dd>';
		h += '</dl>';
		return h;
	}
	function pintaSeccion(cont, d, c, s) {
		var n = s.n, sec = c.secciones[String(n)];
		var caja = el('section', {'class': 'metodo-seccion', 'data-metodo-seccion': String(n), 'data-metodo-vacia': sec.vacia ? '1' : '0'});
		caja.appendChild(el('h2', null, esc(n) + '. ' + esc(s.titulo)));
		if (sec.vacia) {
			caja.appendChild(el('p', {'class': 'metodo-vacio'}, sec.flag ? 'FLAG ' + esc(sec.flag) + T.vacia_flag : T.vacia));
			cont.appendChild(caja);
			return;
		}
		(sec.texto || []).forEach(function (p) { caja.appendChild(el('p', {'class': 'metodo-parrafo'}, md(p))); });
		if (n === 3 && c.pasos.length) {
			caja.appendChild(tabla(T.pasos_cols,
				c.pasos.map(function (p) { return [p.programa, p.n, p.hace, p.conserva, p.archivo + ' ' + p.lineas]; }),
				{caption: T.pasos_cap}));
		}
		if (n === 4 && c.decisiones.length) {
			caja.appendChild(tabla(T.dec_cols,
				c.decisiones.map(function (p) { return ['`' + p.parametro + '`', p.firmado !== undefined ? p.firmado : p.default, p.alternativas || '', p.flag ? (LANG === 'en' ? '“' + p.flag + '”' : '«' + p.flag + '»') : '', [p.documento, p.memo].filter(Boolean).join(' · '), p.texto, p.lee || '']; }),
				{caption: T.dec_cap}));
		}
		if (n === 8 && c.limites.length) {
			caja.appendChild(tabla(T.lim_cols, c.limites.map(function (f) { return [f.flag, f.texto, f.fuente]; }), {caption: T.lim_cap}));
		}
		if (n === 6 && sec.lista.length) {
			caja.appendChild(tabla(T.sal_cols, sec.lista.map(function (f) { return [f.archivo, f.contiene, f.consume, f.check]; })));
		}
		if (n === 10 && c.procedencia.length) {
			caja.appendChild(tabla(T.pro_cols, c.procedencia.map(function (p) { return ['§' + p.seccion, p.archivo, p.lineas, p.nota]; }),
				{caption: T.pro_cap}));
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
		if (!c) { cont.innerHTML = '<p class="metodo-vacio">' + T.no_cap.replace('{x}', esc(slug)) + '</p>'; return false; }
		cont.innerHTML = pintaEncabezado(c);
		var nav = el('p', {'class': 'metodo-nav-caps'});
		var ant = d.capitulos[c.orden_en_SIM - 2], sig = d.capitulos[c.orden_en_SIM];
		nav.innerHTML = '<a href="' + url('/metodo/') + '">' + T.indice + '</a>' + (ant ? ' · ' + T.anterior + ': <a href="' + url('/metodo/' + esc(ant.modulo) + '/') + '">' + esc(ant.modulo) + '</a>' : '') + (sig ? ' · ' + T.siguiente + ': <a href="' + url('/metodo/' + esc(sig.modulo) + '/') + '">' + esc(sig.modulo) + '</a>' : '');
		cont.appendChild(nav);
		d.secciones.forEach(function (s) { pintaSeccion(cont, d, c, s); });
		return true;
	}

	// --- capítulo 0 -------------------------------------------------------------------------------------------------
	function pintaCap0(cont, d) {
		var c = d.cap0;
		cont.innerHTML = '<p class="metodo-intro">' + md(c.intro) + '</p><p class="lead-nota">' + T.fuente + ': <code>' + esc(c.archivo) + '</code> (sha256 <code>' + esc(c.sha256) + '</code>). ' + T.cap0_fuente + '</p>';
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
		bib.appendChild(el('h2', null, T.bib));
		bib.appendChild(tabla(d.bibliografia.columnas, d.bibliografia.filas));
		bib.insertAdjacentHTML('beforeend', fuente(d.bibliografia.fuente));
		cont.appendChild(bib);
	}

	// --- entrada --------------------------------------------------------------------------------------------------
	window.metodoCapitulo = function (cfg) {
		var cont = document.getElementById('metodo-contenido');
		if (!cont) return;
		var src = LANG === 'en' ? cfg.url.replace(/metodo\.json$/, 'metodo-en.json') : cfg.url;
		fetch(src, {credentials: 'same-origin'}).then(function (r) {
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
			cont.innerHTML = '<p class="metodo-vacio">' + T.error + ' <code>' + esc(src) + '</code>: ' + esc(e.message) + '.</p>';
			cont.setAttribute('data-metodo-estado', 'error');
		});
	};
})();
