// test-sitio-nta.js <urlBase> <jsonOrigen> <cuentaOrigen> <panelOrigen> [<png>] — la página /NTA con Chrome headless (puppeteer-core).
// La abre, espera al Sankey v3 de FusionCharts y comprueba que lo que se dibuja es EXACTAMENTE lo que el motor
// emitió: cada enlace (from, to, value, pctpib) del dataSource que recibió el navegador es igual, como cadena, al del
// users/…/SankeyNTA/sankey-v3-grupoedad.json de origen (sin redondeo en PHP ni en JS), los nodos son los mismos y en
// el mismo orden, y lo que FusionCharts tiene cargado (getJSONData) trae pctpib como value (NTA-4: el Sankey se dibuja en
// % del PIB), el MXN del motor en mxn y un tooltext con ambas unidades; al posar el cursor sobre un enlace el tooltip dice
// «% of GDP» y «bn MXN». Las cifras de «Anchoring and residual» (<span data-nta>) se llenaron desde
// users/…/NTA/nta-grupoedad.json (ninguna vacía ni «n/a») y la primera coincide con el archivo; las de % del PIB
// (<span data-pib>) desde nacional_pctpib / v3_mxn / pib del panel, y el año del encabezado de unidad es pib.anio.
// El panel (v8.12.6, NTA-3; NTA-4: nta-panel/v2): los cinco mini-Sankeys se dibujan desde
// users/…/NTA/nta-panel-grupoedad-sexo.json con los enlaces de las celdas Total (mismos valores, nada de flujos en cero;
// cada cinta con data-value y data-pctpib del JSON), los pies (déficit de ciclo de vida y S, en bn y en % del PIB) se
// llenaron y coinciden con el archivo, cada cinta SVG lleva su etiqueta completa; al elegir Hombres y Mujeres los
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
const pp = v => Number(v).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

// El archivo del motor es un fragmento JS (claves sin comillas); se leen nodos y enlaces con la misma
// gramática que lo escribe SankeySumSim.ado: {label:"…"} y {to:"…",value:"…",from:"…"}.
function leerOrigen(ruta) {
  const t = fs.readFileSync(ruta, 'utf8');
  const nodos = [...t.matchAll(/\{label:"([^"]*)"\}/g)].map(m => m[1]);
  const enlaces = [...t.matchAll(/\{to:"([^"]*)",value:"([^"]*)",from:"([^"]*)"(?:,pctpib:"([^"]*)")?\}/g)].map(m => ({ to: m[1], value: m[2], from: m[3], pctpib: m[4] }));
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
    const pct = {};
    if (tarjeta) tarjeta.querySelectorAll('[data-panel-pct]').forEach(el => { pct[el.getAttribute('data-panel-pct')] = el.textContent; });
    return { g, links: cintas.length ? cintas.map(p => ({ from: p.getAttribute('data-from'), to: p.getAttribute('data-to'), value: Number(p.getAttribute('data-value')), pctpib: p.hasAttribute('data-pctpib') ? Number(p.getAttribute('data-pctpib')) : undefined })) : null, svg: cintas.length, etiquetas, pie, pct };
  }));
}
// Los mismos enlaces en % del PIB (celda.pctpib), para comprobar data-pctpib en cada cinta.
function pctCelda(panel, celda) {
  const l = [];
  panel.entradas.forEach(e => { if (celda.entradas_flujos[e.id] > 0) l.push(celda.pctpib.entradas_flujos[e.id]); });
  panel.salidas.forEach(s => { if (celda.salidas_flujos[s.id] > 0) l.push(celda.pctpib.salidas_flujos[s.id]); });
  return l;
}
function panelesIguales(leidos, panel, s) {
  const malos = [];
  leidos.forEach(p => {
    const c = celda(panel, p.g, s);
    const esp = enlacesCelda(panel, c);
    const pct = pctCelda(panel, c);
    const rec = p.links || [];
    const igual = rec.length === esp.length && esp.every((e, i) => rec[i] && rec[i].from === e.from && rec[i].to === e.to && rec[i].value === e.value && rec[i].pctpib === pct[i]);
    if (!igual) malos.push(`g=${p.g}: ${rec.length} enlaces recibidos vs ${esp.length} esperados`);
  });
  return malos;
}

(async () => {
  const origen = leerOrigen(jsonOrigen);
  ok(origen.enlaces.length > 0 && origen.nodos.length > 0, `origen leído: ${origen.nodos.length} nodos, ${origen.enlaces.length} enlaces (${jsonOrigen})`);
  ok(origen.enlaces.every(e => e.pctpib !== undefined && e.pctpib !== ''), 'cada enlace de origen trae pctpib (NTA-4)');
  const cuenta = JSON.parse(fs.readFileSync(cuentaOrigen, 'utf8'));
  ok(cuenta && cuenta.S_vs_B8n && typeof cuenta.S_vs_B8n.S_sin_ajuste === 'number', `cuenta leída: esquema ${cuenta.esquema}, ${(cuenta.grupos || []).length} grupos (${cuentaOrigen})`);
  const panel = JSON.parse(fs.readFileSync(panelOrigen, 'utf8'));
  ok(panel && panel.esquema === 'nta-panel/v2' && panel.celdas.length === 15 && panel.pib && panel.pib.valor > 0 && panel.nacional_pctpib && panel.v3_mxn, `panel leído: esquema ${panel.esquema}, ${(panel.celdas || []).length} celdas, PIB ${panel.pib && panel.pib.valor} (${panelOrigen})`);

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
      if (r.from !== e.from || r.to !== e.to || String(r.value) !== e.value || String(r.pctpib) !== e.pctpib) distintos.push(`#${i} origen=${JSON.stringify(e)} recibido=${JSON.stringify(r)}`);
    });
    ok(distintos.length === 0, `cada enlace (from, to, value, pctpib) es idéntico como cadena al del motor (${origen.enlaces.length - distintos.length}/${origen.enlaces.length})`);
    distintos.slice(0, 5).forEach(d => console.log('       ' + d));
    ok(recibido.chart && recibido.chart.unidad === 'pctpib', 'el PHP declara chart.unidad = pctpib para el v3 (se dibuja en % del PIB)');
    const hubs = recibido.nodes.filter(n => n.toolText).map(n => n.label).sort();
    ok(JSON.stringify(hubs) === JSON.stringify(['Activos', 'Gobierno', 'Ing nacional', 'Transferencias en efectivo']), `solo los cuatro hubs llevan el toolText «inflows = outflows» (${hubs.join(', ')})`);
    ok(recibido.nodes.filter(n => n.toolText).every(n => /% of GDP/.test(n.toolText)), 'el toolText de los hubs lee el total en % of GDP');
    ok(!nodosRec.some(n => /^(Ingreso|Consumo|Desahorro|Futuro) /.test(n) || /^Ancla S14/.test(n) || ['Familias', 'Salud pública', 'Educación pública', 'Otros en especie'].includes(n)) && ['Desahorro', 'Futuro', 'Colectivo', 'Ajuste a cuentas nacionales S14'].every(n => nodosRec.includes(n)),
      'el v3 (NTA-4): Desahorro, Futuro, Colectivo y Ajuste a cuentas nacionales S14 únicos; sin Ingreso <g> / Consumo <g> / Familias / Desahorro <g> / Futuro <g> / especie aparte / Ancla recorte+complemento');
    // lo que FusionCharts tiene cargado: los mismos nodos y enlaces, con pctpib como value (NTA-4), el MXN en mxn y un tooltext con ambas unidades
    const enChart = await page.evaluate(() => {
      const c = FusionCharts.items['sankey-nta-chart'];
      if (!c) return null;
      const d = c.getJSONData();
      return { values: d.links.map(l => String(l.value)), mxn: d.links.map(l => String(l.mxn)), froms: d.links.map(l => l.from), tos: d.links.map(l => l.to), labels: d.nodes.map(n => n.label), tips: d.links.map(l => String(l.tooltext || '')) };
    });
    ok(enChart && enChart.values.every((v, i) => v === origen.enlaces[i].pctpib) && enChart.mxn.every((v, i) => v === origen.enlaces[i].value) && enChart.froms.every((v, i) => v === origen.enlaces[i].from) && enChart.tos.every((v, i) => v === origen.enlaces[i].to) && JSON.stringify(enChart.labels) === JSON.stringify(origen.nodos),
      'FusionCharts.getJSONData() devuelve los mismos nodos y enlaces (from, to) que el origen, con pctpib como value y el MXN del motor en mxn');
    ok(enChart && enChart.tips.every((s, i) => /% of GDP/.test(s) && /bn MXN/.test(s) && s.indexOf(pp(origen.enlaces[i].pctpib)) >= 0 && s.indexOf(bn(Number(origen.enlaces[i].value))) >= 0), 'cada enlace lleva un tooltext con ambas unidades (% of GDP y bn MXN) formateadas desde los valores del motor');
    // el tooltip real: se lleva el Sankey a la pantalla, se posa el cursor sobre la cinta más alta y se lee lo que FusionCharts muestra
    const tip = await page.evaluate(async () => {
      const paths = [...document.querySelectorAll('#sankey-nta svg path')].filter(p => p.getBBox && p.getBBox().width > 60 && p.getBBox().height > 8);
      if (!paths.length) return null;
      const p = paths.sort((a, b) => b.getBBox().height - a.getBBox().height)[0];
      p.scrollIntoView({ block: 'center' });
      await new Promise(r => setTimeout(r, 300));
      const r = p.getBoundingClientRect();
      return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
    });
    let tooltip = '';
    if (tip) {
      await page.mouse.move(tip.x, tip.y);
      await page.mouse.move(tip.x + 2, tip.y + 1);
      await sleep(600);
      tooltip = await page.evaluate(() => [...document.querySelectorAll('[class*="tooltip"], [class*="fc__tooltip"]')].map(e => e.textContent).join(' | '));
    }
    ok(/% of GDP/.test(tooltip) && /MXN/.test(tooltip), `el tooltip de un enlace muestra ambas unidades (${tooltip.replace(/\s+/g, ' ').slice(0, 90)})`);
    // se retira el cursor (el hover atenúa las demás cintas) para que las capturas salgan con el Sankey completo
    await page.mouse.move(0, 0);
    await page.evaluate(() => window.scrollTo(0, 0));
    await sleep(400);
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
  // las cifras en % del PIB (<span data-pib>) se llenaron desde el panel (nacional_pctpib / v3_mxn / pib) y coinciden con el archivo
  let pibs = null;
  for (let i = 0; i < 50; i++) {
    pibs = await page.evaluate(() => [...document.querySelectorAll('[data-pib]')].map(el => ({ clave: el.getAttribute('data-pib'), bloque: el.getAttribute('data-pib-bloque') || 'nacional_pctpib', unidad: el.getAttribute('data-pib-unidad') || 'pctpib', texto: el.textContent })));
    if (pibs.length && pibs.every(c => c.texto !== '')) break;
    await sleep(200);
  }
  const pibVacias = (pibs || []).filter(c => c.texto === '' || c.texto === 'n/a');
  ok(pibs && pibs.length > 0 && pibVacias.length === 0, `las ${(pibs || []).length} cifras <span data-pib> se llenaron desde el panel${pibVacias.length ? ' (vacías o n/a: ' + pibVacias.map(c => c.bloque + '.' + c.clave).join(', ') + ')' : ''}`);
  const fmtPib = c => { const v = panel[c.bloque][c.clave]; return c.unidad === 'texto' ? String(v) : c.unidad === 'bn' ? bn(v) : pp(v); };
  const pibMal = (pibs || []).filter(c => !(c.bloque in panel) || !(c.clave in panel[c.bloque]) || c.texto !== fmtPib(c));
  ok(pibMal.length === 0, `cada cifra data-pib es la del archivo del panel formateada (${(pibs || []).length - pibMal.length}/${(pibs || []).length}${pibMal.length ? '; mal: ' + pibMal.slice(0, 3).map(c => c.bloque + '.' + c.clave + '=' + c.texto).join(', ') : ''})`);
  const unidadHdr = await page.evaluate(() => (document.querySelector('.metodo-unidad') || {}).textContent || '');
  ok(new RegExp('% of ' + panel.pib.anio + ' GDP; GDP = 100').test(unidadHdr), `el encabezado de unidad dice «% of ${panel.pib.anio} GDP; GDP = 100» con el año del archivo (${unidadHdr.trim().slice(0, 60)})`);

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
  const piesOk = paneles.every(p => { const c = celda(panel, p.g, 'T'); return p.pie.deficit_cv === bn(c.deficit_cv) && p.pie.S === bn(c.S) && p.pct.deficit_cv === pp(c.pctpib.deficit_cv) && p.pct.S === pp(c.pctpib.S); });
  ok(piesOk, `los pies (déficit de ciclo de vida C − YL y S) coinciden con el archivo en Total, en bn y en % del PIB (g=1: ${paneles[0].pct.deficit_cv} % / ${paneles[0].pie.deficit_cv} bn; S ${paneles[0].pct.S} % / ${paneles[0].pie.S} bn)`);
  const tipsPanel = await page.evaluate(() => [...document.querySelectorAll('#nta-panel-1 svg path[data-from] title')].map(t => t.textContent));
  ok(tipsPanel.length > 0 && tipsPanel.every(s => /% of GDP/.test(s) && /bn MXN/.test(s)), `las cintas del panel llevan tooltip con ambas unidades (${tipsPanel.length} en g=1)`);

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
    const piesS = leidos.every(p => { const c = celda(panel, p.g, s); return p.pie.deficit_cv === bn(c.deficit_cv) && p.pie.S === bn(c.S) && p.pct.deficit_cv === pp(c.pctpib.deficit_cv) && p.pct.S === pp(c.pctpib.S); });
    ok(piesS, `${s === 'H' ? 'Hombres' : 'Mujeres'}: los pies cambiaron con la celda, en ambas unidades (g=5: ${leidos[4].pct.deficit_cv} % / ${leidos[4].pie.deficit_cv} bn)`);
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
