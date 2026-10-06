/* nl-datos.js — componente "modo datos" compartido de la capa NL (NL-0.3.0).
   Lo inyectan los drivers (PoblacionNL.do, PIBDeflactorNL.do) en la marca
   NL_DATOS_JS de cada plantilla: el HTML final sigue siendo UN archivo,
   inline y sin red. Regla dura: ningún extracto sale sin su encabezado de
   procedencia (líneas '#'; entrecomilladas en CSV). Los valores que se copian
   o descargan son los del canal, con precisión completa, sin recálculo. */
window.NLDatos = (function () {
  'use strict';
  function esc(s) { return String(s === null || s === undefined ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;'); }
  function raw(v) { return (v === null || v === undefined) ? '' : String(v); }
  /* Extracto TSV/CSV: encabezado de procedencia + encabezados de columna + filas. */
  function extract(cols, rows, provLines, sep) {
    var out = provLines.map(function (l) { return sep === ',' ? '"' + l.replace(/"/g, '""') + '"' : l; });
    out.push(cols.map(function (c) { return c[1]; }).join(sep));
    rows.forEach(function (r) { out.push(cols.map(function (c) { var v = typeof c[0] === 'function' ? c[0](r) : r[c[0]]; return raw(v); }).join(sep)); });
    return out.join('\n');
  }
  /* Tabla HTML con el encabezado de procedencia visible debajo. cols: [clave|fn, etiqueta, fmt]. */
  function table(cols, rows, provLines, rowClass) {
    var h = '<div class="tbl-wrap"><table><thead><tr>' + cols.map(function (c) { return '<th>' + esc(c[1]) + '</th>'; }).join('') + '</tr></thead><tbody>';
    rows.forEach(function (r) {
      h += '<tr class="' + (rowClass ? rowClass(r) : '') + '">' + cols.map(function (c) {
        var v = typeof c[0] === 'function' ? c[0](r) : r[c[0]];
        return '<td>' + esc(v === null || v === undefined ? '' : (c[2] ? c[2](v) : v)) + '</td>';
      }).join('') + '</tr>';
    });
    h += '</tbody></table></div><div class="prov">' + esc(provLines.join('\n')) + '</div>';
    return h;
  }
  /* Portapapeles con fallback (selección + execCommand; si falla, el texto queda seleccionado). */
  function copyText(txt, msgEl, fbEl) {
    function fallback() {
      fbEl.value = txt; fbEl.style.display = 'block'; fbEl.focus(); fbEl.select();
      var ok = false; try { ok = document.execCommand('copy'); } catch (e) { ok = false; }
      msgEl.textContent = ok ? 'Copiado (selección). Pega en Excel con Ctrl/Cmd+V.' : 'El navegador bloqueó el portapapeles: el texto está seleccionado abajo, usa Ctrl/Cmd+C.';
    }
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(txt).then(function () { msgEl.textContent = 'Tabla copiada (TSV con procedencia). Pega en Excel con Ctrl/Cmd+V.'; fbEl.style.display = 'none'; }, fallback);
    } else fallback();
  }
  /* Descarga CSV vía Blob; si el visor la bloquea, cae al copiado. */
  function downloadCsv(txt, name, msgEl, fbEl) {
    try {
      var blob = new Blob(['\ufeff' + txt], { type: 'text/csv;charset=utf-8' });
      var a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = name; document.body.appendChild(a); a.click(); document.body.removeChild(a);
      setTimeout(function () { URL.revokeObjectURL(a.href); }, 2000);
      msgEl.textContent = 'CSV generado: ' + name + '. Si el visor bloqueó la descarga, usa "Copiar tabla".';
    } catch (e) { msgEl.textContent = 'Descarga bloqueada por el visor; copiando al portapapeles.'; copyText(txt, msgEl, fbEl); }
  }
  /* Barra de herramientas de un panel: Gráfica | Tabla · Copiar tabla · Descargar CSV. */
  function tools(el, opts) {
    el.innerHTML = '<div class="seg2"><button data-m="grafica"' + (opts.modo === 'grafica' ? ' class="on"' : '') + '>Gráfica</button><button data-m="tabla"' + (opts.modo === 'tabla' ? ' class="on"' : '') + '>Tabla</button></div><button data-a="copy">Copiar tabla</button><button data-a="csv">Descargar CSV</button>';
    Array.prototype.forEach.call(el.querySelectorAll('.seg2 button'), function (b) { b.addEventListener('click', function () { opts.onModo(b.getAttribute('data-m')); }); });
    el.querySelector('[data-a="copy"]').addEventListener('click', function () { var x = opts.data(); copyText(extract(x.cols, x.rows, x.prov, '\t'), opts.msg(), opts.fb()); });
    el.querySelector('[data-a="csv"]').addEventListener('click', function () { var x = opts.data(); downloadCsv(extract(x.cols, x.rows, x.prov, ','), x.name, opts.msg(), opts.fb()); });
  }
  /* Carga el bloque <script type="application/json" id=...> y lo parsea. Nunca devuelve un error
     genérico: dice si falta el bloque, si quedó una marca de inyección o en qué posición falla el JSON. */
  function load(id) {
    var el = document.getElementById(id);
    if (!el) return { error: 'falta el bloque de datos #' + id + ' en el HTML' };
    var t = (el.textContent || '').trim();
    if (!t) return { error: 'el bloque de datos #' + id + ' está vacío (la inyección no ocurrió)' };
    if (t.indexOf('/*__') === 0) return { error: 'marca de inyección sin reemplazar (' + t.slice(0, 24) + '): este archivo es la PLANTILLA, no el endpoint generado' };
    try { return { data: JSON.parse(t), bytes: t.length }; } catch (e) { return { error: 'JSON inválido en #' + id + ' (' + t.length + ' bytes): ' + e.message }; }
  }
  return { esc: esc, extract: extract, table: table, copyText: copyText, downloadCsv: downloadCsv, tools: tools, load: load };
})();
/* NLEstilo — identidad visual de la capa NL (NL-0.4.1; pasada BrandBook 2023 en NL-0.5.1): 100 % Consejo Nuevo León.
   ÚNICO lugar donde viven los tokens de color, la tipografía y el bloque de atribución; cada plantilla llama
   NLEstilo.apply() y consume var(--nl), var(--nac), var(--banda), var(--recibe), var(--paga), var(--paquete),
   var(--proy), var(--nowcast), var(--acento), var(--h), var(--m), var(--ink), var(--mut), var(--line), var(--bg).
   Fuente de los valores (nl-estilo.md §6.6c): Manual de Identidad 2023 (Brandital, v3.0) §5 Paleta de color —
   morado #5A2248 (90,34,72) · turquesa #00B1AF (0,177,175) · amarillo #FCB817 (252,184,23); secundarios #872675,
   #0A6DB6, #A2DCE9, #E76B24, #189347, #E13758, #F27794 (idénticos a los del sitio). El manual manda sobre lo
   inferido de conl.mx (#5a2148 / #fbb818 eran ±1 por canal) y sobre el RGB del BrandBook 2020.
   Semántica (no cambia): NL = morado primario (sujeto); nacional = gris de referencia; recibe = aqua (símbolo del
   logo); paga = naranja (daltonismo: aqua/naranja ΔE 60/75 protan/deutan; el rojo queda para alertas); Paquete =
   amarillo (p2 del motor); proyección y nowcast = el mismo morado atenuado (eco del fintensity del motor);
   acento = púrpura con borde aqua (patrón .btn-morado del sitio); H/M = azul/rosa.
   Tipografía: Poppins (titulares) e Inter (cuerpos de texto, textos pequeños y legales) = §4 del manual 2023;
   Poppins SemiBold + Inter Regular/SemiBold, SIL OFL 1.1, embebidas como subsets desde NLEstiloAssets.
   Logo: imagotipo 2023 (isotipo + logotipo + eslogan "Para la planeación estratégica") en su versión completa,
   que el manual exige "siempre en documentos oficiales y publicaciones" (§1); vector del propio BrandBook, en color
   y en blanco (co-branding 2025: la versión depende del fondo); nunca modificado, distorsionado ni redibujado.
   Área de protección (§2 y co-branding): X = grosor del isotipo = 0.535 × alto del imagotipo; nada dentro de X.
   Atribución = lockup de co-branding "socio principal" (guía 2025, versión 2 — marcas externas tecleadas):
   imagotipo a color a la izquierda · ½X · línea negra ≤ 2 px · ½X · texto en Inter Regular. */
window.NLEstilo = (function () {
  'use strict';
  var T = {
    nl: 'rgb(90,34,72)', nac: 'rgb(127,127,127)', banda: 'rgba(90,34,72,0.25)',
    recibe: 'rgb(0,177,175)', recibeTexto: 'rgb(0,131,129)', paga: 'rgb(231,107,36)', pagaTexto: 'rgb(199,81,8)',
    paquete: 'rgb(252,184,23)', proy: 'rgba(90,34,72,0.55)', nowcast: 'rgba(90,34,72,0.7)',
    acento: 'rgb(135,38,117)', acento2: 'rgb(0,177,175)', alerta: 'rgb(213,43,77)',
    h: 'rgb(10,109,182)', m: 'rgb(242,119,148)',
    ink: '#212121', mut: '#666666', line: '#d0d0d0', bg: '#f6f6f6', card: '#ffffff',
    fuenteTitulo: '"Poppins", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
    fuenteCuerpo: '"Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif'
  };
  var A = window.NLEstiloAssets || null;
  function apply() {
    var r = document.documentElement.style;
    Object.keys(T).forEach(function (k) { r.setProperty('--' + k, T[k]); });
    if (A && !document.getElementById('nl-estilo-fuentes')) {
      var css = '';
      if (A.poppins600) css += '@font-face{font-family:"Poppins";font-style:normal;font-weight:600;font-display:swap;src:url(' + A.poppins600 + ') format("woff2")}';
      if (A.inter400) css += '@font-face{font-family:"Inter";font-style:normal;font-weight:400;font-display:swap;src:url(' + A.inter400 + ') format("woff2")}';
      if (A.inter600) css += '@font-face{font-family:"Inter";font-style:normal;font-weight:600;font-display:swap;src:url(' + A.inter600 + ') format("woff2")}';
      var st = document.createElement('style'); st.id = 'nl-estilo-fuentes'; st.textContent = css; document.head.appendChild(st);
    }
  }
  function esc(s) { return String(s === null || s === undefined ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;'); }
  /* Imagotipo 2023 (versión completa con eslogan) como <img> data: URI. variante: 'blanco' (fondo morado) |
     'color' (fondo claro). X = grosor del isotipo = 0.535 × alto: la zona de protección la aporta el padding del
     contenedor (>= X), el ½X del lockup de co-branding lo aporta el gap. Alturas: cabecera 50 px (= conl.mx,
     125 px de ancho), atribución 72 px (el eslogan mide 9.4 % del alto: 6.8 px, legible; a 36 px no lo era). */
  var X_RATIO = 0.535;
  function logo(variante, h) {
    if (!A) return '';
    var src = variante === 'blanco' ? A.logoBlanco : A.logo;
    if (!src) return '';
    return '<img class="nl-logo" src="' + src + '" alt="Consejo Nuevo León. Para la planeación estratégica" style="height:' + (h || 50) + 'px;width:auto;display:block">';
  }
  function X(h) { return Math.round(h * X_RATIO); }
  /* Cabecera común: imagotipo blanco sobre morado + título + subtítulo (la leyenda de _NLidentidad, tal cual).
     El gap título-logo y el padding son >= X (área de protección del manual §2). */
  function cabecera(el, titulo, sub) {
    var h = 50, x = X(h);
    el.innerHTML = '<div class="nl-cab" style="gap:' + x + 'px;padding:' + x + 'px 28px">' + logo('blanco', h) + '<div><h1 id="titulo">' + esc(titulo) + '</h1><p class="sub" id="subtitulo">' + esc(sub) + '</p></div></div>';
  }
  /* Bloque de atribución (intocable en su contenido): producto — módulo · "construido sobre el Simulador Fiscal CIEP
     v<motor>" (tal cual de _NLidentidad, viaja en D.subtitulo) · capa NL-x.y.z · GitHub (enlace, no carga) · corrida ·
     log · driver. Forma (NL-0.5.1) = lockup de co-branding "socio principal, marcas externas tecleadas": imagotipo a
     color con eslogan · ½X · línea negra de 1 px (<= 2 px) del alto del logo · ½X · texto en Inter Regular. */
  function atribucion(D) {
    var P = (D && D.procedencia) || {};
    var repo = P.repositorio || '';
    var hl = 72, x = X(hl), mx = Math.round(x / 2);
    var h = '<div class="nl-atrib" style="padding:' + x + 'px 0 ' + x + 'px">' + logo('color', hl) + '<div class="nl-atrib-sep" style="margin:0 ' + mx + 'px;height:' + hl + 'px"></div><div class="nl-atrib-txt">';
    h += '<p class="nl-atrib-1">' + esc(D.producto || 'Simulador Fiscal NL') + (D.titulo && D.producto && D.titulo.indexOf(D.producto) === 0 ? esc(D.titulo.slice(D.producto.length)) : '') + '</p>';
    h += '<p class="nl-atrib-2">' + esc(D.subtitulo || '') + ' · capa <code>' + esc(P.version_capa_nl || '—') + '</code> · motor <code>' + esc(P.version_motor || '—') + '</code>' + (repo ? ' · <a href="' + esc(repo) + '" rel="noopener">GitHub ↗</a>' : '') + '</p>';
    h += '<p class="nl-atrib-3">corrida ' + esc(P.generado_en || '—') + ' · log <code>' + esc(P.log || '—') + '</code> · ' + esc(P.driver || '') + (P.modo ? ' · modo <code>' + esc(P.modo) + '</code>' : '') + '</p>';
    h += '</div></div>';
    return h;
  }
  /* CSS común de cabecera/pie/tipografía: lo inyecta apply() para que las tres plantillas compartan la misma ropa. */
  function cssComun() {
    return 'body{font-family:var(--fuenteCuerpo)}h1,h2,.card .v{font-family:var(--fuenteTitulo)}' +
      'table,.card .v,.card .n,.card .d,.tip,.nodo text,.tick{font-variant-numeric:tabular-nums}' +
      'header{background:var(--nl);color:#fff;padding:0}.nl-cab{max-width:1240px;margin:0 auto;display:flex;align-items:center}' +
      '.nl-cab h1{margin:0;font-size:22px;font-weight:600;color:#fff}.nl-cab .sub{margin:4px 0 0;font-size:13px;opacity:.92}' +
      '.nl-atrib{display:flex;align-items:center;border-top:3px solid var(--nl);margin-top:14px;font-family:var(--fuenteCuerpo);font-weight:400}' +
      '.nl-atrib-sep{flex:0 0 1px;width:1px;background:#000}.nl-atrib-txt{min-width:0}' +
      '.nl-atrib p{margin:2px 0;font-weight:400}.nl-atrib-1{font-size:14px;color:var(--ink)}.nl-atrib-2{font-size:12.5px;color:var(--ink)}.nl-atrib-3{font-size:12px;color:var(--mut)}' +
      '.nl-atrib code{font-weight:400}.nl-atrib a{color:var(--acento);text-decoration:underline;font-weight:400}' +
      'footer{color:var(--mut)}footer a{color:var(--acento)}';
  }
  function applyAll() { apply(); if (!document.getElementById('nl-estilo-comun')) { var st = document.createElement('style'); st.id = 'nl-estilo-comun'; st.textContent = cssComun(); document.head.appendChild(st); } }
  return { tokens: T, apply: applyAll, logo: logo, cabecera: cabecera, atribucion: atribucion, assets: A ? A.meta : null,
    estado: 'identidad CoNL según el Manual de Identidad 2023 (nl-estilo.md §6.6c, NL-0.5.1): hex #5A2248/#00B1AF/#FCB817, imagotipo 2023 con eslogan, lockup de co-branding en la atribución; tipografía Poppins/Inter OFL embebida' };
})();
