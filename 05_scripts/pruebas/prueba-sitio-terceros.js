// prueba-sitio-terceros.js <urlBase> <fijados.json> [--solo <fragmento de ruta>] — scripts de terceros del sitio (Chrome headless).
// Abre las mismas páginas que prueba-sitio-sellos.js (portada, /metodo, /NTA, /entidades y una entidad; es y en), registra
// TODA petición a otro origen y lee el DOM ya dibujado. Exige, en cada página:
//   1. cero peticiones a una URL con `/latest/` (ni de FusionCharts ni de nadie);
//   2. todo <script src> y <link rel=stylesheet> de otro origen trae integrity + crossorigin="anonymous", salvo los exentos
//      (Google Tag Manager y el CSS de Google Fonts: los dos cambian por diseño y no admiten SRI);
//   3. ninguna petición a un host fuera de HOSTS; a cdn.fusioncharts.com, solo las URL de terceros.php (fijados.json): un
//      módulo que FusionCharts pida por su cuenta llegaría sin integrity;
//   4. ninguna petición fallida, ninguna respuesta 4xx/5xx, ningún error de JS ni de consola (un integrity que no coincide
//      sale como error de consola y como petición bloqueada);
//   5. FusionCharts cargado en la versión fijada y, donde la página tiene gráficas, al menos una dibujada.
// Salida: 0 sin fallos; 1 con alguno. Una línea por hallazgo.
const fs = require('fs');
const puppeteer = require('puppeteer-core');
const args = process.argv.slice(2);
const [urlBase, fijadosJson] = args;
const opt = (n) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : null; };
const solo = opt('--solo');
const CHROME = process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ORIGEN = new URL(urlBase).origin;
const FIJADOS = JSON.parse(fs.readFileSync(fijadosJson, 'utf8')); // {version, urls: {url: sri}}

// Hosts de terceros permitidos. Google Tag Manager y lo que él pide (Analytics) quedan como están, sin SRI.
const HOSTS = ['cdn.fusioncharts.com', 'fonts.googleapis.com', 'fonts.gstatic.com', 'www.googletagmanager.com',
  'www.google-analytics.com', 'analytics.google.com', 'region1.google-analytics.com', 'stats.g.doubleclick.net'];
const ANALITICA = /^(www\.googletagmanager\.com|(www\.|region1\.)?google-analytics\.com|analytics\.google\.com|stats\.g\.doubleclick\.net)$/;
const EXENTOS_SRI = (u) => u.host === 'www.googletagmanager.com' || u.host === 'fonts.googleapis.com';

// [ruta, ¿debe dibujar al menos una gráfica?]
const PAGINAS = [
  ['/', true], ['/index-en.php', true],
  ['/metodo/', false], ['/metodo/?lang=en', false],
  ['/metodo/cap0/', false], ['/metodo/cap0/?lang=en', false],
  ['/metodo/PEF/', false], ['/metodo/PEF/?lang=en', false],
  ['/NTA/', true], ['/NTA/?lang=es', true],
  ['/entidades/', false], ['/entidades/?lang=es', false],
  ['/entidades/NL/', true], ['/entidades/NL/?lang=es', true],
].filter(p => !solo || p[0].indexOf(solo) === 0);

(async () => {
  const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox', '--disable-gpu'] });
  let fallos = 0;
  let nTerceros = 0;
  const falla = (ruta, msg) => { fallos++; console.log('FALLO  ' + ruta + ': ' + msg); };
  for (const [ruta, conGraficas] of PAGINAS) {
    const page = await browser.newPage();
    const pet = [];
    const errores = [];
    page.on('request', r => pet.push(r.url()));
    page.on('requestfailed', r => {
      const u = new URL(r.url());
      // la analítica de Google falla sin red de salida o con un bloqueador: no es asunto de este gate
      if (!ANALITICA.test(u.host)) errores.push('petición fallida ' + r.url() + ' (' + (r.failure() && r.failure().errorText) + ')');
    });
    page.on('response', r => { if (r.status() >= 400) errores.push('HTTP ' + r.status() + ' ' + r.url()); });
    page.on('console', m => { if (m.type() === 'error') errores.push('console.error ' + m.text()); });
    page.on('pageerror', e => errores.push('error de JS ' + e.message));
    try { await page.goto(urlBase + ruta, { waitUntil: 'networkidle0', timeout: 90e3 }); } catch (e) { errores.push('carga: ' + e.message); }
    await new Promise(res => setTimeout(res, 2500));
    const dom = await page.evaluate(() => {
      const ext = [];
      document.querySelectorAll('script[src], link[rel~="stylesheet"][href]').forEach(el => {
        const url = el.src || el.href;
        ext.push({ etiqueta: el.tagName.toLowerCase(), url, integrity: el.getAttribute('integrity'), crossorigin: el.getAttribute('crossorigin') });
      });
      const fc = window.FusionCharts;
      const items = fc ? Object.values(fc.items || {}) : [];
      return { ext, fcVersion: fc ? [].concat(fc.version).join('.') : null, graficas: items.length,
        dibujadas: items.filter(c => { const el = document.getElementById(c.options && c.options.containerElementId); return el && el.querySelector('svg'); }).length };
    });
    await page.close();

    const antes = fallos;
    for (const u of pet) {
      let url; try { url = new URL(u); } catch (e) { continue; }
      if (!/^https?:$/.test(url.protocol) || url.origin === ORIGEN) continue;
      nTerceros++;
      if (/\/latest\//i.test(url.pathname)) falla(ruta, 'petición a «latest»: ' + u);
      if (HOSTS.indexOf(url.host) < 0) falla(ruta, 'host fuera de la lista: ' + u);
      if (url.host === 'cdn.fusioncharts.com' && !(u in FIJADOS.urls)) falla(ruta, 'FusionCharts pidió un archivo que terceros.php no fija (llega sin integrity): ' + u);
    }
    for (const e of dom.ext) {
      const url = new URL(e.url, urlBase);
      if (url.origin === ORIGEN || EXENTOS_SRI(url)) continue;
      if (!e.integrity) falla(ruta, '<' + e.etiqueta + '> sin integrity: ' + e.url);
      if (e.crossorigin !== 'anonymous') falla(ruta, '<' + e.etiqueta + '> sin crossorigin="anonymous": ' + e.url);
      if (FIJADOS.urls[e.url] && e.integrity !== FIJADOS.urls[e.url]) falla(ruta, 'integrity distinto al de terceros.php: ' + e.url);
    }
    for (const e of errores) falla(ruta, e);
    if (dom.fcVersion !== FIJADOS.version) falla(ruta, 'FusionCharts ' + dom.fcVersion + ' en lugar de ' + FIJADOS.version);
    if (conGraficas && dom.dibujadas < 1) falla(ruta, 'ninguna gráfica de FusionCharts dibujada (' + dom.graficas + ' creadas)');
    if (fallos === antes) console.log('OK     ' + ruta + '  (FusionCharts ' + dom.fcVersion + ', ' + dom.dibujadas + ' gráfica(s) dibujada(s), ' + dom.ext.filter(e => new URL(e.url, urlBase).origin !== ORIGEN).length + ' etiqueta(s) de terceros)');
  }
  await browser.close();
  console.log('');
  console.log('RESUMEN: ' + PAGINAS.length + ' páginas, ' + nTerceros + ' peticiones a terceros (con repeticiones), ' + fallos + ' fallo(s).');
  process.exit(fallos === 0 ? 0 : 1);
})();
