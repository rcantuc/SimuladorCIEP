/* Museo de versiones · Simulador Fiscal CIEP (2026-10-01)
   - Franja inferior con la generación, el año y la vuelta a la galería.
   - Los botones y formularios de cálculo están inertes: en lugar de pedir a un
     PHP/Stata que ya no existe, muestran un aviso. No modifica el JS original. */
(function () {
  var s = document.currentScript || (function(){var x=document.getElementsByTagName('script');return x[x.length-1];})();
  var v = (s && s.getAttribute('data-version')) || '';
  var anio = (s && s.getAttribute('data-anio')) || '';
  var titulo = (s && s.getAttribute('data-titulo')) || '';
  function toast(msg) {
    var t = document.getElementById('museo-toast');
    if (!t) { t = document.createElement('div'); t.id = 'museo-toast'; document.body.appendChild(t); }
    t.textContent = msg; t.className = 'on';
    clearTimeout(t._h); t._h = setTimeout(function(){ t.className = ''; }, 3200);
  }
  function barra() {
    if (document.getElementById('museo-barra')) return;
    var b = document.createElement('div'); b.id = 'museo-barra';
    b.innerHTML = '<span><b>Pieza de museo</b> · Simulador Fiscal CIEP <b>' + v + '</b> (' + anio + ')' + (titulo ? ' · ' + titulo : '') +
      ' · Se muestra tal como se veía; los cálculos están inertes.</span>' +
      '<span><a href="../index.html">← Volver a la galería</a> &nbsp; <a href="https://simuladorfiscal.ciep.mx/">Simulador actual →</a> &nbsp; <button class="museo-x" title="Ocultar">×</button></span>';
    document.body.appendChild(b); document.body.className += ' museo-con-barra';
    b.querySelector('.museo-x').onclick = function(){ b.parentNode.removeChild(b); document.body.className = document.body.className.replace(' museo-con-barra',''); };
  }
  function inerte(e) {
    var el = e.target;
    while (el && el !== document) {
      if (el.getAttribute && el.getAttribute('data-museo-msg')) { e.preventDefault(); e.stopPropagation(); toast(el.getAttribute('data-museo-msg')); return; }
      var tag = (el.tagName || '').toLowerCase();
      var tipo = (el.getAttribute && el.getAttribute('type') || '').toLowerCase();
      var href = (el.getAttribute && el.getAttribute('href')) || '';
      if ((tag === 'input' && (tipo === 'submit' || tipo === 'button' || tipo === 'image')) ||
          (tag === 'button' && tipo !== 'reset') ||
          /\.php(\?|$)/.test(href) || /localhost|ddns/.test(href) ||
          (el.className && /\b(boton|btn-calcular|calcular|submit)\b/i.test(String(el.className)))) {
        e.preventDefault(); e.stopPropagation();
        toast('Pieza de museo: esta versión (' + v + ', ' + anio + ') ya no realiza cálculos. Para simular, usa el simulador actual.');
        return;
      }
      el = el.parentNode;
    }
  }
  function listo() {
    barra();
    document.addEventListener('click', inerte, true);
    document.addEventListener('submit', function(e){ e.preventDefault(); toast('Pieza de museo: formulario inerte (' + v + ', ' + anio + ').'); }, true);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', listo); else listo();
})();
