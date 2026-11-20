// prueba-sitio-sellos.js <urlBase> <siteDir> <buildSello> [--json salida.json] [--solo <fragmento de ruta>] — sellos de versión del sitio (Chrome headless).
// Abre la portada, /metodo (índice, cap0 y un capítulo), /NTA, /entidades y una entidad, en español y en inglés, registra TODA petición
// propia (mismo origen) y exige que cada recurso propio de datos, CSS y JavaScript lleve un sello `?v=`:
//   - archivo estático del docroot (CSS, JS, JSON): v = primeros 10 hex del sha1 de SU contenido (un `?v=17` a mano no pasa);
//   - dato servido por un PHP (jsonEntidad.php, jsonSankeyNTA.php, …): v = sello del build (sha1 de DEPLOYED_COMMIT, 10 hex).
// Quedan fuera, y el reporte las lista aparte: plugins/ (terceros), las peticiones que no son GET (los POST de la portada hacia
// calculaStata.php, cargaDefault.php, jsonSankey*.php: un POST no se cachea, no hay nada que sellar), imágenes, fuentes e íconos.
// Salida: 0 todo sellado; 1 algún recurso propio sin sello o con sello que no corresponde. Una línea por petición dentro del alcance.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const puppeteer = require('puppeteer-core');
const args = process.argv.slice(2);
const [urlBase, siteDir, buildSello] = args;
const opt = (n) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : null; };
const salidaJson = opt('--json');
const solo = opt('--solo');
const CHROME = process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ORIGEN = new URL(urlBase).origin;

const PAGINAS = [
  ['portada', 'es', '/'], ['portada', 'en', '/index-en.php'],
  ['/metodo', 'es', '/metodo/'], ['/metodo', 'en', '/metodo/?lang=en'],
  ['/metodo/cap0', 'es', '/metodo/cap0/'], ['/metodo/cap0', 'en', '/metodo/cap0/?lang=en'],
  ['/metodo/PEF', 'es', '/metodo/PEF/'], ['/metodo/PEF', 'en', '/metodo/PEF/?lang=en'],
  ['/NTA', 'en', '/NTA/'], ['/NTA', 'es', '/NTA/?lang=es'],
  ['/entidades', 'en', '/entidades/'], ['/entidades', 'es', '/entidades/?lang=es'],
  ['/entidades/NL', 'en', '/entidades/NL/'], ['/entidades/NL', 'es', '/entidades/NL/?lang=es'],
].filter(p => !solo || p[2].indexOf(solo) === 0);

const GRAFICO = /\.(png|jpe?g|gif|svg|webp|ico|woff2?|ttf|eot|otf)$/i;
const sha10 = (buf) => crypto.createHash('sha1').update(buf).digest('hex').slice(0, 10);

function esperado(ruta) {
  const f = path.join(siteDir, decodeURIComponent(ruta));
  if (/\.php$/i.test(ruta)) return { tipo: 'build', sello: buildSello };
  if (fs.existsSync(f) && fs.statSync(f).isFile()) return { tipo: 'contenido', sello: sha10(fs.readFileSync(f)) };
  return { tipo: 'sin-archivo', sello: null };
}

function clasifica(r) {
  const u = new URL(r.url());
  if (u.protocol !== 'http:' && u.protocol !== 'https:') return null;
  if (u.origin !== ORIGEN) return null;
  const ruta = u.pathname;
  const ficha = { url: u.pathname + u.search, ruta, metodo: r.method(), tipoChrome: r.resourceType(), v: u.searchParams.get('v') };
  if (r.resourceType() === 'document' || r.isNavigationRequest()) return Object.assign(ficha, { grupo: 'documento' });
  if (ruta.indexOf('/plugins/') === 0) return Object.assign(ficha, { grupo: 'plugins' });
  if (ficha.metodo !== 'GET') return Object.assign(ficha, { grupo: 'no-GET' });
  if (GRAFICO.test(ruta)) return Object.assign(ficha, { grupo: 'grafico' });
  const clase = /\.css$/i.test(ruta) || r.resourceType() === 'stylesheet' ? 'css' : (/\.js$/i.test(ruta) || r.resourceType() === 'script' ? 'js' : 'datos');
  return Object.assign(ficha, { grupo: 'alcance', clase });
}

(async () => {
  const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox', '--disable-gpu'] });
  const censo = [];
  for (const [seccion, idioma, ruta] of PAGINAS) {
    const page = await browser.newPage();
    const vistas = new Map();
    page.on('request', r => { const c = clasifica(r); if (c) vistas.set(c.metodo + ' ' + c.url, c); });
    try { await page.goto(urlBase + ruta, { waitUntil: 'networkidle0', timeout: 60 * 1e3 }); } catch (e) { console.log('AVISO  ' + ruta + ': ' + e.message); }
    await new Promise(res => setTimeout(res, 1500));
    await page.close();
    censo.push({ seccion, idioma, ruta, peticiones: [...vistas.values()] });
  }
  await browser.close();

  let fallos = 0;
  const resumen = { alcance: 0, sellados: 0, sinSello: 0, noCoincide: 0, noGET: 0, plugins: 0, grafico: 0 };
  for (const p of censo) {
    console.log('## ' + p.ruta + '  (' + p.seccion + ', ' + p.idioma + ')');
    for (const q of p.peticiones) {
      if (q.grupo === 'documento') continue;
      if (q.grupo === 'plugins') { resumen.plugins++; continue; }
      if (q.grupo === 'no-GET') { resumen.noGET++; console.log('exento ' + q.metodo + ' ' + q.url + '  (no GET: no se cachea)'); continue; }
      if (q.grupo === 'grafico') { resumen.grafico++; continue; }
      resumen.alcance++;
      const e = esperado(q.ruta);
      let estado = 'OK    ';
      let nota = '';
      if (!q.v) { estado = 'FALLO '; nota = '  <- SIN SELLO'; resumen.sinSello++; fallos++; }
      else if (e.sello && q.v !== e.sello) { estado = 'FALLO '; nota = '  <- el sello (' + q.v + ') no es el ' + (e.tipo === 'build' ? 'del build' : 'del contenido') + ' (' + e.sello + ')'; resumen.noCoincide++; fallos++; }
      else resumen.sellados++;
      q.estado = estado.trim();
      console.log(estado + ' ' + q.clase.padEnd(5) + ' ' + q.url + nota);
    }
  }
  if (salidaJson) fs.writeFileSync(salidaJson, JSON.stringify(censo, null, 1));
  console.log('');
  console.log('RESUMEN: ' + resumen.alcance + ' peticiones propias de datos/CSS/JS (con repeticiones entre páginas): ' + resumen.sellados + ' selladas, ' + resumen.sinSello + ' sin sello, ' + resumen.noCoincide + ' con sello que no corresponde.');
  console.log('         fuera de alcance: ' + resumen.plugins + ' de plugins/, ' + resumen.noGET + ' no-GET, ' + resumen.grafico + ' imágenes/fuentes/íconos.');
  process.exit(fallos === 0 ? 0 : 1);
})();
