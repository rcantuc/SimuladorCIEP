/* MUSEO (2026-10-01) — Reconstrucción del comportamiento de Biscuits.js (perdido en la captura):
   la barra de resultados (#biscuits .nav) se vuelve pegajosa al hacer scroll, la pestaña de la
   sección visible se "llena" con su color (color1..color9) y la barra adopta ese color; el nav
   superior compacto (#nav_sticky) aparece al bajar. Solo CSS inline + scroll listener. */
(function () {
  function init() {
    var nav = document.querySelector('#biscuits .nav'); if (!nav) return;
    var bg = nav.querySelector(':scope > .bg');
    var items = Array.prototype.slice.call(nav.querySelectorAll('ul.items > li'));
    var sticky = document.getElementById('nav_sticky');
    var secciones = items.map(function (li) {
      var a = li.querySelector('a'); var h = a && a.getAttribute('href') || '';
      var id = h.split('#')[1]; var sec = id && document.getElementById(id);
      var cbg = li.querySelector('.container > .bg'); var color = cbg ? getComputedStyle(cbg).backgroundColor : '';
      return { li: li, sec: sec, color: color, cbg: cbg, perso: li.querySelector('.perso') };
    });
    // transiciones suaves
    if (bg) bg.style.transition = 'background-color .45s ease';
    secciones.forEach(function (s) {
      if (s.cbg) s.cbg.style.transition = 'opacity .35s ease, transform .35s ease';
      if (s.perso) s.perso.style.transition = 'color .35s ease, opacity .35s ease';
      s.li.addEventListener('mouseenter', function () { if (s.cbg && !s.li.classList.contains('current')) s.cbg.style.opacity = '0.45'; });
      s.li.addEventListener('mouseleave', function () { if (s.cbg && !s.li.classList.contains('current')) s.cbg.style.opacity = '0'; });
    });
    var navTop = 0, placeholder = null;
    function medir() {
      var wasSticky = nav.classList.contains('sticky');
      if (wasSticky) nav.classList.remove('sticky');
      navTop = nav.getBoundingClientRect().top + window.pageYOffset;
      if (wasSticky) nav.classList.add('sticky');
    }
    var actual = -1;
    function onScroll() {
      var y = window.pageYOffset;
      var esSticky = y > navTop - 54;
      nav.classList.toggle('sticky', esSticky);
      if (sticky) sticky.style.display = esSticky ? 'block' : 'none';
      var linea = y + 54 + 57 + 40;  // debajo de nav_sticky + barra
      var idx = -1;
      secciones.forEach(function (s, i) { if (s.sec && s.sec.getBoundingClientRect().top + window.pageYOffset <= linea) idx = i; });
      if (idx === actual) return; actual = idx;
      secciones.forEach(function (s, i) {
        var on = i === idx;
        s.li.classList.toggle('current', on);
        if (s.cbg) s.cbg.style.opacity = on ? '1' : '0';
        if (s.perso) { s.perso.style.color = on ? '#fff' : ''; s.perso.style.opacity = on ? '1' : ''; }
      });
      if (bg) bg.style.backgroundColor = (idx >= 0 && secciones[idx].color) ? secciones[idx].color : '#fff';
    }
    // desplazamiento suave al pulsar una pestaña
    secciones.forEach(function (s) {
      var a = s.li.querySelector('a');
      if (a && s.sec) a.addEventListener('click', function (e) {
        e.preventDefault(); e.stopPropagation();
        var top = s.sec.getBoundingClientRect().top + window.pageYOffset - (54 + 57);
        window.scrollTo({ top: top, behavior: 'smooth' });
      }, true);
    });
    medir(); onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', function () { medir(); onScroll(); });
    setTimeout(function () { medir(); onScroll(); }, 1500);  // tras cargar gráficas/fuentes
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();
