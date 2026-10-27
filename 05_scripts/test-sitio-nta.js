// test-sitio-nta.js <urlBase> <jsonOrigen> [<png>] — la página /NTA con Chrome headless (puppeteer-core).
// La abre, espera al Sankey de FusionCharts y comprueba que lo que se dibuja es EXACTAMENTE lo que el
// motor emitió: cada enlace (from, to, value) del dataSource que recibió el navegador es igual, como
// cadena, al del users/…/SankeyNTA/sankey-grupoedad.json de origen (sin redondeo en PHP ni en JS), y los
// nodos son los mismos y en el mismo orden. Si se pasa <png>, guarda la captura de la página completa.
// Salida: 0 todo verde; 1 algún aserto falló. Imprime una línea por aserto.
const fs = require('fs');
const puppeteer = require('puppeteer-core');
const [urlBase, jsonOrigen, png] = process.argv.slice(2);
const CHROME = process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fallos = 0;
const ok = (cond, msg) => { console.log((cond ? 'OK     ' : 'FALLO  ') + msg); if (!cond) fallos++; };

// El archivo del motor es un fragmento JS (claves sin comillas); se leen nodos y enlaces con la misma
// gramática que lo escribe SankeySumSim.ado: {label:"…"} y {to:"…",value:"…",from:"…"}.
function leerOrigen(ruta) {
  const t = fs.readFileSync(ruta, 'utf8');
  const nodos = [...t.matchAll(/\{label:"([^"]*)"\}/g)].map(m => m[1]);
  const enlaces = [...t.matchAll(/\{to:"([^"]*)",value:"([^"]*)",from:"([^"]*)"\}/g)].map(m => ({ to: m[1], value: m[2], from: m[3] }));
  return { nodos, enlaces };
}

(async () => {
  const origen = leerOrigen(jsonOrigen);
  ok(origen.enlaces.length > 0 && origen.nodos.length > 0, `origen leído: ${origen.nodos.length} nodos, ${origen.enlaces.length} enlaces (${jsonOrigen})`);

  const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox', '--hide-scrollbars'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900 });
  const errores = [];
  page.on('pageerror', e => errores.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errores.push(m.text()); });
  const resp = await page.goto(`${urlBase}/NTA/`, { waitUntil: 'networkidle2', timeout: 90000 });
  ok(resp && resp.status() === 200, `GET /NTA/ responde 200 (${resp && resp.status()})`);

  // FusionCharts dibuja en SVG dentro del contenedor; se espera hasta 20 s
  let svg = 0;
  for (let i = 0; i < 100 && svg === 0; i++) {
    svg = await page.evaluate(() => document.querySelectorAll('#sankey-nta svg path').length);
    if (svg === 0) await sleep(200);
  }
  ok(svg > 0, `el Sankey se dibujó (#sankey-nta tiene ${svg} trazos SVG)`);

  const recibido = await page.evaluate(() => window.metodoSankeyData && window.metodoSankeyData['sankey-nta']);
  ok(!!recibido, 'el navegador recibió el dataSource del PHP (window.metodoSankeyData["sankey-nta"])');
  if (recibido) {
    const nodosRec = recibido.nodes.map(n => n.label);
    ok(JSON.stringify(nodosRec) === JSON.stringify(origen.nodos), `nodos idénticos y en el mismo orden (${nodosRec.length})`);
    ok(recibido.links.length === origen.enlaces.length, `mismo número de enlaces (${recibido.links.length} vs ${origen.enlaces.length})`);
    let distintos = [];
    origen.enlaces.forEach((e, i) => {
      const r = recibido.links[i] || {};
      if (r.from !== e.from || r.to !== e.to || String(r.value) !== e.value) distintos.push(`#${i} origen=${JSON.stringify(e)} recibido=${JSON.stringify(r)}`);
    });
    ok(distintos.length === 0, `cada enlace (from, to, value) es idéntico como cadena al del motor (${origen.enlaces.length - distintos.length}/${origen.enlaces.length})`);
    distintos.slice(0, 5).forEach(d => console.log('       ' + d));
    // y lo que FusionCharts tiene cargado es ese mismo dataSource (sin transformación intermedia)
    const enChart = await page.evaluate(() => {
      const c = FusionCharts.items['sankey-nta-chart'];
      return c ? c.getJSONData().links.map(l => String(l.value)) : null;
    });
    ok(Array.isArray(enChart) && enChart.every((v, i) => v === origen.enlaces[i].value), 'FusionCharts.getJSONData() devuelve los mismos valores que el origen');
  }
  const fuente = await page.evaluate(() => (document.querySelector('.metodo-fuente') || {}).textContent || '');
  ok(/Source/.test(fuente) && /ENIGH/.test(fuente), `pie de fuente presente (${fuente.trim().replace(/\s+/g, ' ').slice(0, 110)}…)`);
  ok(errores.length === 0, `sin errores de JS en la página${errores.length ? ': ' + errores.slice(0, 3).join(' | ') : ''}`);

  if (png) {
    await sleep(800);
    await page.screenshot({ path: png, fullPage: true });
    ok(fs.existsSync(png) && fs.statSync(png).size > 0, `captura guardada en ${png}`);
  }
  await browser.close();
  console.log(fallos === 0 ? 'RESULTADO: /NTA OK (0 fallos)' : `RESULTADO: ${fallos} fallo(s)`);
  process.exit(fallos === 0 ? 0 : 1);
})().catch(e => { console.error('FALLO  excepción: ' + e); process.exit(1); });
