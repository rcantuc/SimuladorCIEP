/* ===========================================================================
   indicadores-decorador.js — decora los hashtags de ciep.mx con la cifra
   del motor (lector del contrato ciep.nodo.indicadores/v1).

   FUENTE versionada: 01_modulos/nodos/indicadores-decorador.js
   Copia servible (la hace el driver): <docroot>/indicadores/decorador.js
   Se encola con el mu-plugin ciep-indicadores.php (una línea de enqueue).

   Lenguaje visual (ronda de estilo de Ricardo): junto al
   hashtag va SOLO el número y el signo % — columna angosta, todo en blanco
   para que sobresalga (con una sombra sutil para no perderse sobre fondos
   claros). La información general que NO se repite por hashtag (unidad y
   corte) vive en una sola nota fija en la esquina superior derecha, leída
   del contrato. El detalle completo por concepto (fuente, clave SHCP, tipo
   de dato) va en el tooltip de cada cifra.

   Cómo funciona: los hashtags del home son anclas a /category/<slug>/.
   El slug es la llave del censo. Si el contrato trae el slug DISPONIBLE,
   se decora; los slugs fuera del contrato o no disponibles quedan INTACTOS.

   Este archivo NO CALCULA y NO CONTIENE CIFRAS: todo número viene del
   JSON. 05_scripts/verify_nodo.sh (regla 1) lo audita igual que a las
   páginas de los nodos.
   =========================================================================== */
(function () {
  'use strict';

  var RUTA = '/indicadores/statajson_indicadores.json';

  function fmt(v, spec) {
    if (v === null || v === undefined) return '';
    var m = /%\d*\.(\d+)f/.exec(spec || '');
    var dec = m ? parseInt(m[1], 10) : 1;
    return v.toLocaleString('es-MX', {
      minimumFractionDigits: dec, maximumFractionDigits: dec
    });
  }

  function slugDe(href) {
    var m = /\/category\/([^\/?#]+)\/?/i.exec(href || '');
    return m ? decodeURIComponent(m[1]).toLowerCase() : null;
  }

  /* La nota general (unidad + corte), una sola vez, esquina superior
     derecha. Solo aparece si algo se decoró. */
  function notaGeneral(D) {
    if (document.getElementById('ciep-ind-nota')) return;
    var n = document.createElement('div');
    n.id = 'ciep-ind-nota';
    n.textContent = D.presentacion.nota_general;
    n.title = 'Producido con Simulador Fiscal CIEP '
      + D.procedencia.version_simulador + ' · corte de datos '
      + D.procedencia.corte_datos + ' · ' + D.procedencia.origen;
    n.style.position = 'fixed';
    n.style.top = '8px';
    n.style.right = '8px';
    n.style.zIndex = '999';
    n.style.padding = '4px 10px';
    n.style.borderRadius = '6px';
    n.style.background = 'rgba(20,20,15,.78)';
    n.style.color = '#fff';
    n.style.font = '12px system-ui, sans-serif';
    n.style.pointerEvents = 'auto';
    document.body.appendChild(n);
  }

  /* Solo se decoran anclas cuyo texto ES un hashtag (empieza con #): así el
     menú y el footer, que enlazan a las mismas categorías con texto plano,
     quedan fuera. */
  function esHashtag(a) {
    return (a.textContent || '').trim().charAt(0) === '#';
  }

  function decorar(D, conteos) {
    var mapa = {};
    D.indicadores.forEach(function (ind) {
      if (ind.disponible) mapa[ind.slug] = ind;
    });
    var algo = false;
    var anclas = document.querySelectorAll('a[href*="/category/"]');
    anclas.forEach(function (a) {
      if (a.dataset.ciepInd) return;               /* idempotente */
      if (!esHashtag(a)) return;
      var slug = slugDe(a.getAttribute('href'));
      if (!slug) return;
      var ind = mapa[slug];
      var n = conteos[slug];
      if (!ind && n === undefined) return;
      a.dataset.ciepInd = slug;
      var s = document.createElement('span');
      s.className = 'ciep-indicador';
      /* SOLO el número y el % (y el conteo de investigaciones) — blanco,
         angosto, sin repetir unidad/corte */
      s.style.color = '#fff';
      s.style.textShadow = '0 1px 2px rgba(0,0,0,.45)';
      s.style.fontSize = 'smaller';
      s.style.fontWeight = 'normal';
      s.style.whiteSpace = 'nowrap';
      var texto = '';
      var tip = [];
      if (ind) {
        texto += ' ' + fmt(ind.pib, D.presentacion.formato_pib) + '%';
        tip.push(ind.etiqueta + ' · ' + fmt(ind.pib, D.presentacion.formato_pib)
          + ' ' + D.presentacion.unidad_pib + ' · corte ' + ind.corte
          + ' — ' + ind.fuente + ' — tipo de dato: ' + ind.tipo_dato);
      }
      if (n !== undefined) {
        texto += ' (' + n.toLocaleString('es-MX') + ')';
        tip.push(n.toLocaleString('es-MX') + ' investigaciones publicadas en esta categoría');
      }
      s.textContent = texto;
      s.title = tip.join(' · ');
      a.appendChild(s);
      algo = true;
    });
    if (algo) notaGeneral(D);
  }

  /* Conteo de investigaciones por categoría: dato VIVO de WordPress (API
     REST), no del contrato — nunca tecleado. Si la API falla, simplemente
     no hay conteos. */
  function cargarConteos() {
    var slugs = [];
    document.querySelectorAll('a[href*="/category/"]').forEach(function (a) {
      if (!esHashtag(a)) return;
      var s = slugDe(a.getAttribute('href'));
      if (s && slugs.indexOf(s) < 0) slugs.push(s);
    });
    if (!slugs.length) return Promise.resolve({});
    return fetch('/wp-json/wp/v2/categories?per_page=100&slug=' + slugs.join(','))
      .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
      .then(function (cats) {
        var m = {};
        cats.forEach(function (c) { m[c.slug.toLowerCase()] = c.count; });
        return m;
      })
      .catch(function () { return {}; });
  }

  fetch(RUTA)
    .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
    .then(function (D) {
      cargarConteos().then(function (conteos) { decorar(D, conteos); });
    })
    .catch(function () { /* sin contrato no se decora nada; la página queda tal cual */ });
})();
