// test-sitio-nta.js <urlBase> <jsonOrigen> <cuentaOrigen> <panelOrigen> [<png>] — la página /NTA con Chrome headless (puppeteer-core).
// La abre, espera al Sankey v3 de FusionCharts y comprueba que lo que se dibuja es EXACTAMENTE lo que el motor
// emitió: cada enlace (from, to, value) del dataSource que recibió el navegador es igual, como cadena, al del
// users/…/SankeyNTA/sankey-v3-grupoedad.json de origen (sin redondeo en PHP ni en JS), los nodos son los mismos y en
// el mismo orden, y lo que FusionCharts tiene cargado (getJSONData) trae esos mismos valores. Las cifras de
// «Anchoring and residual» (<span data-nta>) se llenaron desde users/…/NTA/nta-grupoedad.json (ninguna vacía ni «n/a»)
// y la primera coincide con el archivo. El panel (v8.12.6, NTA-3): los cinco mini-Sankeys se dibujan desde
// users/…/NTA/nta-panel-grupoedad-sexo.json con los enlaces de las celdas Total (mismos valores, nada de flujos en cero),
// los pies (déficit de ciclo de vida y S) se llenaron y coinciden con el archivo, cada cinta SVG lleva su etiqueta
// completa; al elegir Hombres y Mujeres los
// CINCO paneles cambian a las celdas H y M del mismo JSON sin recargar la página (una sola petición al endpoint del panel).
// Si se pasa <png>, guarda la captura de la página completa y, a su lado, <png sin .png>-v3.png (solo el Sankey v3) y
// <png sin .png>-panel.png (solo el panel en Total): la evidencia del PR.
// Salida: 0 todo verde; 1 algún aserto falló. Imprime una línea por aserto.
const fs = require('fs');
const puppeteer = require('puppeteer-core');
const [urlBase, jsonOrigen, cuentaOrigen, panelOrigen, png] = process.argv.slice(2);
const CHROME = process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fallos = 0;
const ok = (cond, msg) => { console.log((cond ? 'OK     ' : 'FALLO  ') + msg); if (!cond) fallos++; };
const bn = v => (v / 1e9).toLocaleString('en-US', { minimumFractionDigits: 1, maximumFractionDigits: 1 });

// El archivo del motor es un fragmento JS (claves sin comillas); se leen nodos y enlaces con la misma
// gramática que lo escribe SankeySumSim.ado: {label:"…"} y {to:"…",value:"…",from:"…"}.
function leerOrigen(ruta) {
  const t = fs.readFileSync(ruta, 'utf8');
  const nodos = [...t.matchAll(/\{label:"([^"]*)"\}/g)].map(m => m[1]);
  const enlaces = [...t.matchAll(/\{to:"([^"]*)",value:"([^"]*)",from:"([^"]*)"\}/g)].map(m => ({ to: m[1], value: m[2], from: m[3] }));
  return { nodos, enlaces };
}

// Enlaces esperados de una celda del panel, con la misma regla que js/metodo-sankey.js (flujos > 0, en el orden del catálogo).
function enlacesCelda(panel, celda) {
  const l = [];
  panel.entradas.forEach(e => { const v = celda.entradas_flujos[e.id]; if (v > 0) l.push({ from: e.etiqueta, to: celda.grupo, value: v }); });
  panel.salidas.forEach(s => { const v = celda.salidas_flujos[s.id]; if (v > 0) l.push({ from: celda.grupo, to: s.etiqueta, value: v }); });
  return l;
}
const celda = (panel, g, s) => panel.celdas.find(c => String(c.g) === String(g) && c.s === s);

async function leerPaneles(page) {
  // lo dibujado en cada uno de los cinco paneles: una cinta SVG por flujo con data-from / data-to / data-value, y los pies
  return page.evaluate(() => [1, 2, 3, 4, 5].map(g => {
    const caja = document.getElementById('nta-panel-' + g);
    const cintas = caja ? [...caja.querySelectorAll('svg path[data-from]')] : [];
    const tarjeta = caja && caja.closest('.metodo-panel-celda');
    const pie = {};
    if (tarjeta) tarjeta.querySelectorAll('[data-panel]').forEach(el => { pie[el.getAttribute('data-panel')] = el.textContent; });
    const etiquetas = caja ? [...caja.querySelectorAll('svg text[data-etiqueta]')].map(t => t.getAttribute('data-etiqueta')) : [];
    return { g, links: cintas.length ? cintas.map(p => ({ from: p.getAttribute('data-from'), to: p.getAttribute('data-to'), value: Number(p.getAttribute('data-value')) })) : null, svg: cintas.length, etiquetas, pie };
  }));
}
function panelesIguales(leidos, panel, s) {
  const malos = [];
  leidos.forEach(p => {
    const esp = enlacesCelda(panel, celda(panel, p.g, s));
    const rec = p.links || [];
    const igual = rec.length === esp.length && esp.every((e, i) => rec[i] && rec[i].from === e.from && rec[i].to === e.to && rec[i].value === e.value);
    if (!igual) malos.push(`g=${p.g}: ${rec.length} enlaces recibidos vs ${esp.length} esperados`);
  });
  return malos;
}

(async () => {
  const origen = leerOrigen(jsonOrigen);
  ok(origen.enlaces.length > 0 && origen.nodos.length > 0, `origen leído: ${origen.nodos.length} nodos, ${origen.enlaces.length} enlaces (${jsonOrigen})`);
  const cuenta = JSON.parse(fs.readFileSync(cuentaOrigen, 'utf8'));
  ok(cuenta && cuenta.S_vs_B8n && typeof cuenta.S_vs_B8n.S_sin_ajuste === 'number', `cuenta leída: esquema ${cuenta.esquema}, ${(cuenta.grupos || []).length} grupos (${cuentaOrigen})`);
  const panel = JSON.parse(fs.readFileSync(panelOrigen, 'utf8'));
  ok(panel && panel.esquema === 'nta-panel/v1' && panel.celdas.length === 15, `panel leído: esquema ${panel.esquema}, ${(panel.celdas || []).length} celdas (${panelOrigen})`);

  const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox', '--hide-scrollbars'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900 });
  const errores = [];
  const peticionesPanel = [];
  page.on('pageerror', e => errores.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errores.push(m.text()); });
  page.on('request', r => { if (/cuenta=panel-grupoedad-sexo/.test(r.url())) peticionesPanel.push(r.url()); });
  const resp = await page.goto(`${urlBase}/NTA/`, { waitUntil: 'networkidle2', timeout: 90000 });
  ok(resp && resp.status() === 200, `GET /NTA/ responde 200 (${resp && resp.status()})`);

  // FusionCharts dibuja en SVG dentro del contenedor; se espera hasta 20 s
  let svg = 0;
  for (let i = 0; i < 100 && svg === 0; i++) {
    svg = await page.evaluate(() => document.querySelectorAll('#sankey-nta svg path').length);
    if (svg === 0) await sleep(200);
  }
  ok(svg > 0, `el Sankey v3 se dibujó (#sankey-nta tiene ${svg} trazos SVG)`);

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
    const hubs = recibido.nodes.filter(n => n.toolText).map(n => n.label).sort();
    ok(JSON.stringify(hubs) === JSON.stringify(['Activos', 'Gobierno', 'Ing nacional', 'Transferencias en efectivo']), `solo los cuatro hubs llevan el toolText «inflows = outflows» (${hubs.join(', ')})`);
    ok(!nodosRec.some(n => /^(Ingreso|Consumo) /.test(n) || n === 'Familias'), 'el v3 no trae Ingreso <g>, Consumo <g> ni Familias (edades solo al inicio y al final)');
    // y lo que FusionCharts tiene cargado es ese mismo dataSource (sin transformación intermedia)
    const enChart = await page.evaluate(() => {
      const c = FusionCharts.items['sankey-nta-chart'];
      if (!c) return null;
      const d = c.getJSONData();
      return { values: d.links.map(l => String(l.value)), froms: d.links.map(l => l.from), tos: d.links.map(l => l.to), labels: d.nodes.map(n => n.label) };
    });
    ok(enChart && enChart.values.every((v, i) => v === origen.enlaces[i].value) && enChart.froms.every((v, i) => v === origen.enlaces[i].from) && enChart.tos.every((v, i) => v === origen.enlaces[i].to) && JSON.stringify(enChart.labels) === JSON.stringify(origen.nodos),
      'FusionCharts.getJSONData() devuelve los mismos nodos y enlaces (from, to, value) que el origen');
  }

  // las cifras de «Anchoring and residual» se llenaron desde la cuenta
  let cifras = null;
  for (let i = 0; i < 50; i++) {
    cifras = await page.evaluate(() => [...document.querySelectorAll('[data-nta]')].map(el => ({ ruta: el.getAttribute('data-nta'), unidad: el.getAttribute('data-nta-unidad') || 'bn', texto: el.textContent })));
    if (cifras.length && cifras.every(c => c.texto !== '')) break;
    await sleep(200);
  }
  const vacias = (cifras || []).filter(c => c.texto === '' || c.texto === 'n/a');
  ok(cifras && cifras.length > 0 && vacias.length === 0, `las ${(cifras || []).length} cifras <span data-nta> se llenaron desde la cuenta${vacias.length ? ' (vacías o n/a: ' + vacias.map(c => c.ruta).join(', ') + ')' : ''}`);
  const esperado = bn(cuenta.S_vs_B8n.S_sin_ajuste);
  const primera = (cifras || []).find(c => c.ruta === 'S_vs_B8n.S_sin_ajuste');
  ok(primera && primera.texto === esperado, `Σ S sin ancla en la página = ${primera && primera.texto} bn (archivo: ${esperado})`);
  const enCuenta = await page.evaluate(() => window.metodoCuentaData && window.metodoCuentaData.procedencia && window.metodoCuentaData.procedencia.modulo);
  ok(enCuenta === cuenta.procedencia.modulo, `la cuenta recibida es la del archivo (procedencia: ${enCuenta})`);

  // el panel: cinco mini-Sankeys desde el JSON del panel, celdas Total
  let paneles = null;
  for (let i = 0; i < 100; i++) {
    paneles = await leerPaneles(page);
    if (paneles.every(p => p.svg > 0 && p.links && p.pie.deficit_cv && p.pie.deficit_cv !== '')) break;
    await sleep(200);
  }
  ok(paneles.every(p => p.svg > 0), `los cinco mini-Sankeys del panel se dibujaron (cintas SVG: ${paneles.map(p => p.svg).join(', ')})`);
  const etiquetasOk = paneles.every(p => { const c = celda(panel, p.g, 'T'); const esp = enlacesCelda(panel, c).map(l => l.from === c.grupo ? l.to : l.from); return JSON.stringify(p.etiquetas) === JSON.stringify(esp); });
  ok(etiquetasOk, 'cada flujo lleva su etiqueta completa (la del JSON), sin truncar, en el orden del catálogo');
  const enPanel = await page.evaluate(() => window.metodoPanelData && window.metodoPanelData.procedencia && window.metodoPanelData.procedencia.modulo);
  ok(enPanel === panel.procedencia.modulo, `el panel recibido es el del archivo (procedencia: ${enPanel})`);
  let malos = panelesIguales(paneles, panel, 'T');
  ok(malos.length === 0, `Total: cada panel trae exactamente los enlaces (from, to, value) de su celda T del JSON${malos.length ? ' — ' + malos.join('; ') : ''}`);
  const titulos = paneles.map(p => p.pie.grupo);
  ok(JSON.stringify(titulos) === JSON.stringify(panel.grupos.map(g => g.grupo)), `los títulos de los paneles son las etiquetas del motor (${titulos.join(' · ')})`);
  const piesOk = paneles.every(p => { const c = celda(panel, p.g, 'T'); return p.pie.deficit_cv === bn(c.deficit_cv) && p.pie.S === bn(c.S); });
  ok(piesOk, `los pies (déficit de ciclo de vida C − YL y S) coinciden con el archivo en Total (g=1: ${paneles[0].pie.deficit_cv} / ${paneles[0].pie.S} bn)`);

  if (png) {
    await sleep(800);
    await page.screenshot({ path: png, fullPage: true });
    ok(fs.existsSync(png) && fs.statSync(png).size > 0, `captura de la página completa guardada en ${png}`);
    const base = png.replace(/\.png$/i, '');
    const wrap = await page.$('.metodo-sankey-wrap');
    if (wrap) { await wrap.screenshot({ path: base + '-v3.png' }); ok(fs.existsSync(base + '-v3.png'), `captura del Sankey v3 guardada en ${base}-v3.png`); }
    const pan = await page.$('.metodo-panel-wrap');
    if (pan) { await pan.screenshot({ path: base + '-panel.png' }); ok(fs.existsSync(base + '-panel.png'), `captura del panel (Total) guardada en ${base}-panel.png`); }
  }

  // el selector cambia los cinco paneles sin recargar: Hombres y Mujeres
  const antes = peticionesPanel.length;
  for (const s of ['H', 'M']) {
    await page.click(`input[name="nta-sexo"][value="${s}"]`);
    let leidos = null;
    for (let i = 0; i < 50; i++) {
      leidos = await leerPaneles(page);
      if (panelesIguales(leidos, panel, s).length === 0) break;
      await sleep(200);
    }
    malos = panelesIguales(leidos, panel, s);
    ok(malos.length === 0, `${s === 'H' ? 'Hombres' : 'Mujeres'}: los cinco paneles cambiaron a las celdas ${s} del JSON${malos.length ? ' — ' + malos.join('; ') : ''}`);
    const piesS = leidos.every(p => { const c = celda(panel, p.g, s); return p.pie.deficit_cv === bn(c.deficit_cv) && p.pie.S === bn(c.S); });
    ok(piesS, `${s === 'H' ? 'Hombres' : 'Mujeres'}: los pies cambiaron con la celda (g=5: ${leidos[4].pie.deficit_cv} / ${leidos[4].pie.S} bn)`);
  }
  ok(peticionesPanel.length === antes && antes === 1, `el panel se pidió una sola vez (${peticionesPanel.length} peticiones): el selector no recarga`);
  const distintosHM = [1, 2, 3, 4, 5].every(g => JSON.stringify(enlacesCelda(panel, celda(panel, g, 'H'))) !== JSON.stringify(enlacesCelda(panel, celda(panel, g, 'M'))));
  ok(distintosHM, 'las celdas H y M difieren en los cinco grupos (el cambio es visible)');

  const fuente = await page.evaluate(() => (document.querySelector('.metodo-fuente') || {}).textContent || '');
  ok(/Source/.test(fuente) && /ENIGH/.test(fuente), `pie de fuente presente (${fuente.trim().replace(/\s+/g, ' ').slice(0, 110)}…)`);
  ok(errores.length === 0, `sin errores de JS en la página${errores.length ? ': ' + errores.slice(0, 3).join(' | ') : ''}`);

  await browser.close();
  console.log(fallos === 0 ? 'RESULTADO: /NTA OK (0 fallos)' : `RESULTADO: ${fallos} fallo(s)`);
  process.exit(fallos === 0 ? 0 : 1);
})().catch(e => { console.error('FALLO  excepción: ' + e); process.exit(1); });
