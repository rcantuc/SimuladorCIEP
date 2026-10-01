/* MUSEO (2026-10-01) — Reconstrucción del comportamiento de Biscuits.js (perdido en la captura):
   la barra de resultados (#biscuits .nav) se vuelve pegajosa al hacer scroll, la pestaña de la
   sección visible se "llena" con su color (color1..color9) y la barra adopta ese color; el nav
   superior compacto (#nav_sticky) aparece al bajar.
   Nota: en esta plantilla el scroll ocurre dentro de #main (overflow-x:hidden lo vuelve contenedor
   de scroll), no en la ventana: se escucha al contenedor real y todo se mide contra el viewport. */
(function () {
  var TOP = 54, BARRA = 57;
  function scrollParent(el) {
    for (var p = el.parentElement; p; p = p.parentElement) {
      var cs = getComputedStyle(p);
      if (/(auto|scroll)/.test(cs.overflowY + cs.overflow + cs.overflowX) && p.scrollHeight > p.clientHeight) return p;
    }
    return null;
  }
  function init() {
    var biscuits = document.getElementById('biscuits'); var nav = biscuits && biscuits.querySelector('.nav'); if (!nav) return;
    var bg = nav.querySelector(':scope > .bg');
    var items = Array.prototype.slice.call(nav.querySelectorAll('ul.items > li'));
    var sticky = document.getElementById('nav_sticky');
    var cont = scrollParent(biscuits);
    var secciones = items.map(function (li) {
      var a = li.querySelector('a'); var h = a && a.getAttribute('href') || '';
      var id = h.split('#')[1]; var sec = id && document.getElementById(id);
      var cbg = li.querySelector('.container > .bg'); var color = cbg ? getComputedStyle(cbg).backgroundColor : '';
      return { li: li, a: a, sec: sec, color: color, cbg: cbg, perso: li.querySelector('.perso') };
    });
    if (bg) bg.style.transition = 'background-color .45s ease';
    secciones.forEach(function (s) {
      if (s.cbg) s.cbg.style.transition = 'opacity .35s ease';
      if (s.perso) s.perso.style.transition = 'color .35s ease, opacity .35s ease';
      s.li.addEventListener('mouseenter', function () { if (s.cbg && !s.li.classList.contains('current')) s.cbg.style.opacity = '0.45'; });
      s.li.addEventListener('mouseleave', function () { if (s.cbg && !s.li.classList.contains('current')) s.cbg.style.opacity = '0'; });
      if (s.a && s.sec) s.a.addEventListener('click', function (e) {
        e.preventDefault(); e.stopPropagation();
        var delta = s.sec.getBoundingClientRect().top - (TOP + BARRA);
        if (cont) cont.scrollBy({ top: delta, behavior: 'smooth' }); else window.scrollBy({ top: delta, behavior: 'smooth' });
      }, true);
    });
    var actual = -1, ticking = false;
    function aplicar() {
      ticking = false;
      // posición natural de la barra = borde superior de #biscuits (la barra cuelga 57px por encima)
      var natural = biscuits.getBoundingClientRect().top - BARRA;
      var esSticky = natural <= TOP;
      nav.classList.toggle('sticky', esSticky);
      if (sticky) sticky.style.display = esSticky ? 'block' : 'none';
      var linea = TOP + BARRA + 40, idx = -1;
      secciones.forEach(function (s, i) { if (s.sec && s.sec.getBoundingClientRect().top <= linea) idx = i; });
      if (idx === actual) return; actual = idx;
      secciones.forEach(function (s, i) {
        var on = i === idx;
        s.li.classList.toggle('current', on);
        if (s.cbg) s.cbg.style.opacity = on ? '1' : '0';
        if (s.perso) { s.perso.style.color = on ? '#fff' : ''; s.perso.style.opacity = on ? '1' : ''; }
      });
      if (bg) bg.style.backgroundColor = (idx >= 0 && secciones[idx].color) ? secciones[idx].color : '#fff';
    }
    function onScroll() { if (!ticking) { ticking = true; requestAnimationFrame(aplicar); } }
    (cont || window).addEventListener('scroll', onScroll, { passive: true });
    if (cont) window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll);
    aplicar(); setTimeout(aplicar, 1500);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();
