// test-sitio-metodo.js <urlBase> <metodo.json> — /metodo con Chrome headless (puppeteer-core), 8.18.
// Abre el índice, el capítulo 0 y cada capítulo; espera a que js/metodo-capitulo.js termine (data-metodo-estado="ok") y comprueba:
//   - índice: cada <span data-metodo> se llenó (ninguno «—»); una fila por capítulo con su sello igual al del JSON; enlace al cap0;
//   - capítulo: la cabecera (dl.metodo-meta) y las diez secciones de la plantilla en orden; cada sección no vacía en el JSON trae
//     al menos una tabla o un párrafo y cada vacía su aviso con el FLAG; el sello de la cabecera es el del JSON;
//   - capítulo 0: tantas secciones como el JSON más la bibliografía; en la tabla de requerimientos la columna «Otro país» está vacía;
//   - cero errores de JS (pageerror / console.error) en todas las páginas;
//   - todo enlace interno (href que empieza con «/») de esas páginas responde 200 (una petición por URL distinta);
//   - inglés (8.19): /metodo/?lang=en, cap0 y el primer capítulo pintan desde metodo-en.json con html lang=en y enlaces ?lang=en.
// Salida: 0 todo verde; 1 algún aserto falló. Imprime una línea por aserto.
const fs = require('fs');
const http = require('http');
const puppeteer = require('puppeteer-core');
const [urlBase, rutaJson] = process.argv.slice(2);
const CHROME = process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
let fallos = 0;
const ok = (cond, msg) => { console.log((cond ? 'OK     ' : 'FALLO  ') + msg); if (!cond) fallos++; };
const d = JSON.parse(fs.readFileSync(rutaJson, 'utf8'));

function get(url) {
  return new Promise(resolve => {
    const req = http.get(url, res => {
      if ((res.statusCode === 301 || res.statusCode === 302) && res.headers.location) {
        res.resume();
        const dest = res.headers.location.startsWith('http') ? res.headers.location : urlBase + res.headers.location;
        return get(dest).then(resolve);
      }
      res.resume();
      resolve(res.statusCode);
    });
    req.on('error', () => resolve(0));
    req.setTimeout(20 * 1e3, () => { req.destroy(); resolve(0); });
  });
}

(async () => {
  const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox', '--disable-gpu'] });
  const enlaces = new Set();
  let erroresJs = [];
  async function abre(ruta) {
    const page = await browser.newPage();
    page.on('pageerror', e => erroresJs.push(ruta + ': ' + e.message));
    page.on('console', m => { if (m.type() === 'error') erroresJs.push(ruta + ': console ' + m.text()); });
    await page.goto(urlBase + ruta, { waitUntil: 'networkidle0' });
    let estado = '';
    try {
      await page.waitForFunction(() => { const c = document.getElementById('metodo-contenido'); return c && c.getAttribute('data-metodo-estado') !== 'cargando'; }, { timeout: 30 * 1e3 });
      estado = await page.$eval('#metodo-contenido', c => c.getAttribute('data-metodo-estado'));
    } catch (e) { estado = 'timeout'; }
    ok(estado === 'ok', ruta + ' pinta desde metodo.json (estado ' + estado + ')');
    (await page.$$eval('a[href^="/"]', as => as.map(a => a.getAttribute('href')))).forEach(h => enlaces.add(h.split('#')[0]));
    return page;
  }

  // índice
  let page = await abre('/metodo/');
  const vacios = await page.$$eval('[data-metodo]', ss => ss.filter(s => s.textContent === '—' || s.textContent === '').map(s => s.getAttribute('data-metodo')));
  ok(vacios.length === 0, 'índice: todos los <span data-metodo> se llenaron' + (vacios.length ? ' (vacíos: ' + vacios.join(', ') + ')' : ''));
  const filas = await page.$$eval('table.metodo-tabla-generada tbody tr[data-capitulo]', trs => trs.map(tr => ({ cap: tr.getAttribute('data-capitulo'), sello: (tr.querySelector('.metodo-sello') || {}).getAttribute ? tr.querySelector('.metodo-sello').getAttribute('data-sello') : '' })));
  ok(filas.length === d.capitulos.length && filas.every((f, i) => f.cap === d.capitulos[i].modulo && f.sello === d.capitulos[i].sello), 'índice: ' + filas.length + ' filas = ' + d.capitulos.length + ' capítulos, en el orden de SIM.do y con el sello del JSON');
  ok(await page.$('a[href="/metodo/cap0/"]') !== null, 'índice: enlace al capítulo 0');
  await page.close();

  // capítulo 0
  page = await abre('/metodo/cap0/');
  const nSec0 = await page.$$eval('section.metodo-seccion', s => s.length);
  ok(nSec0 === d.cap0.secciones.length + 1, 'cap0: ' + nSec0 + ' secciones = ' + d.cap0.secciones.length + ' del documento + bibliografía');
  const otroPais = await page.$$eval('td[data-col="Otro país"]', tds => ({ n: tds.length, llenas: tds.filter(t => t.textContent.trim() !== '').length }));
  ok(otroPais.n > 0 && otroPais.llenas === 0, 'cap0: la columna «Otro país» existe (' + otroPais.n + ' celdas) y va vacía (' + otroPais.llenas + ' llenas)');
  await page.close();

  // capítulos
  for (const c of d.capitulos) {
    const ruta = '/metodo/' + c.modulo + '/';
    page = await abre(ruta);
    const meta = await page.$eval('dl.metodo-meta', dl => dl ? dl.querySelectorAll('dt').length : 0).catch(() => 0);
    const selloPag = await page.$eval('dl.metodo-meta .metodo-sello', s => s.getAttribute('data-sello')).catch(() => '');
    const secs = await page.$$eval('section[data-metodo-seccion]', ss => ss.map(s => ({ n: s.getAttribute('data-metodo-seccion'), vacia: s.getAttribute('data-metodo-vacia'), tablas: s.querySelectorAll('table').length, parrafos: s.querySelectorAll('p.metodo-parrafo').length, aviso: (s.querySelector('p.metodo-vacio') || { textContent: '' }).textContent })));
    const ordenOk = secs.length === 10 && secs.every((s, i) => s.n === String(i + 1));
    let contenidoOk = true;
    secs.forEach(s => {
      const j = c.secciones[s.n];
      if (!j) { contenidoOk = false; return; }
      if (j.vacia) { if (!(s.aviso && (!j.flag || s.aviso.indexOf(j.flag) >= 0))) contenidoOk = false; }
      else if (!(s.tablas > 0 || s.parrafos > 0)) contenidoOk = false;
    });
    ok(meta >= 6 && selloPag === c.sello, '  ' + c.modulo + ': cabecera con ' + meta + ' campos y sello «' + selloPag + '» = JSON');
    ok(ordenOk && contenidoOk, '  ' + c.modulo + ': 10 secciones en orden; las no vacías con tabla o párrafo, las vacías con su FLAG (' + secs.filter(s => s.vacia === '1').length + ' vacías)');
    await page.close();
  }

  // inglés (8.19): ?lang=en pinta desde metodo-en.json, <html lang="en">, bandera EN activa y enlaces que conservan ?lang=en
  for (const ruta of ['/metodo/?lang=en', '/metodo/cap0/?lang=en', '/metodo/' + d.capitulos[0].modulo + '/?lang=en']) {
    const page = await browser.newPage();
    page.on('pageerror', e => erroresJs.push(ruta + ': ' + e.message));
    page.on('console', m => { if (m.type() === 'error') erroresJs.push(ruta + ': console ' + m.text()); });
    await page.goto(urlBase + ruta, { waitUntil: 'networkidle0' });
    let r = {};
    try {
      await page.waitForFunction(() => { const c = document.getElementById('metodo-contenido'); return c && c.getAttribute('data-metodo-estado') !== 'cargando'; }, { timeout: 30 * 1e3 });
      r = await page.evaluate(() => ({
        estado: document.getElementById('metodo-contenido').getAttribute('data-metodo-estado'),
        lang: document.documentElement.getAttribute('lang'),
        idioma: (window.metodoData || {}).idioma,
        bandera: (document.querySelector('.metodo-lang .lang-item.active') || {}).getAttribute ? document.querySelector('.metodo-lang .lang-item.active').getAttribute('hreflang') : '',
        internos: [...document.querySelectorAll('#metodo-contenido a[href^="/metodo/"]')].map(a => a.getAttribute('href')),
      }));
    } catch (e) { r = { estado: 'timeout' }; }
    const sinLang = (r.internos || []).filter(h => !/[?]lang=en/.test(h));
    ok(r.estado === 'ok' && r.lang === 'en' && r.idioma === 'en' && r.bandera === 'en' && sinLang.length === 0,
      ruta + ' en inglés: pinta desde metodo-en.json, html lang=en, bandera EN activa, ' + (r.internos || []).length + ' enlaces internos con ?lang=en' +
      (sinLang.length ? ' (sin ?lang: ' + sinLang.slice(0, 3).join(', ') + ')' : '') + ' [' + JSON.stringify({ estado: r.estado, lang: r.lang, idioma: r.idioma, bandera: r.bandera }) + ']');
    await page.close();
  }

  ok(erroresJs.length === 0, 'cero errores de JS en todas las páginas' + (erroresJs.length ? ': ' + erroresJs.slice(0, 5).join(' | ') : ''));

  // enlaces internos
  const lista = [...enlaces].filter(h => h && !h.startsWith('//') && !/^\/(jsonSankey|jsonEntidad|calculaStata|cargaDefault)/.test(h));
  let rotos = [];
  for (const h of lista) {
    const code = await get(urlBase + h);
    if (code !== 200) rotos.push(h + ' -> ' + code);
  }
  ok(rotos.length === 0, lista.length + ' enlaces internos distintos responden 200' + (rotos.length ? ' (rotos: ' + rotos.join(', ') + ')' : ''));

  await browser.close();
  process.exit(fallos ? 1 : 0);
})().catch(e => { console.log('FALLO  excepción: ' + e.message); process.exit(1); });
