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
/* NLEstilo — tokens de color de la capa NL (NL-0.4.0). ÚNICO lugar donde viven: cada plantilla
   llama NLEstilo.apply() y consume var(--nl), var(--nac), var(--banda), var(--recibe), var(--paga),
   var(--paquete), var(--proy), var(--acento), var(--h), var(--m), var(--ink), var(--mut), var(--line).
   Valores PROVISIONALES = propuesta de nl-estilo.md §3 (derivados de scheme-ciep: p11 azul CIEP
   profundo, p23 gris, p10 jade, p6 rojo institucional, p2 amarillo, p1 naranja). La pasada de estilo
   de Ricardo cambia AQUÍ los valores y todos los endpoints los heredan sin retrabajo. */
window.NLEstilo = (function () {
  'use strict';
  var T = {
    nl: 'rgb(0,78,198)', nac: 'rgb(175,174,180)', banda: 'rgba(0,78,198,0.25)',
    recibe: 'rgb(0,179,147)', paga: 'rgb(186,34,64)', paquete: 'rgb(255,189,0)', proy: 'rgba(255,128,0,0.55)',
    acento: '#d76f33', h: 'rgb(23,151,201)', m: 'rgb(150,6,92)',
    ink: '#1F1F1F', mut: 'rgb(111,111,111)', line: 'rgb(200,200,200)', bg: '#f7f8fa', card: '#ffffff'
  };
  function apply() { var r = document.documentElement.style; Object.keys(T).forEach(function (k) { r.setProperty('--' + k, T[k]); }); }
  return { tokens: T, apply: apply, estado: 'provisional: nl-estilo.md §3, pendiente de la pasada de estilo' };
})();
