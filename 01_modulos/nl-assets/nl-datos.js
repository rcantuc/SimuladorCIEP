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
  return { esc: esc, extract: extract, table: table, copyText: copyText, downloadCsv: downloadCsv, tools: tools };
})();
