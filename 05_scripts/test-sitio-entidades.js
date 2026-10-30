// test-sitio-entidades.js <urlBase> <dirUsers> "<ABREV ABREV …>" [<dirPng>] — las páginas /entidades/<ABREV> y el índice
// /entidades con Chrome headless (puppeteer-core). Para cada entidad abre la página, espera a los cuatro productos y
// comprueba que lo dibujado es EXACTAMENTE lo que el motor emitió y lo que meta.json declara:
//   - Sankey (FusionCharts): cada enlace (from, to, value) del dataSource recibido es igual, como cadena, al del
//     users/…/<ABREV>/sankey-quintil.json de origen; nodos iguales y en el mismo orden; lo que FusionCharts tiene cargado
//     (getJSONData) trae esos valores; los enlaces con sello=1 llevan toolText; al elegir «Age group» el selector pide
//     grupoedad UNA vez y redibuja con los enlaces de ese archivo.
//   - Ciclo de vida (ApexCharts): las series de Hombres y Mujeres son los pct de las celdas del ciclo-vida.json (por grupo
//     de deciles, del quinquenio mayor al menor), número a número, y lo que ApexCharts tiene cargado también; las
//     categorías llevan «⚠» exactamente en las celdas con sello=1 del archivo (y en ninguna otra).
//   - Tasas efectivas (SVG propio): una barra por impuesto salvo los excluidos (ISAN, IMPORT), con data-te igual al te del
//     tasas-efectivas.json y data-sello=1 exactamente en los impuestos con sello=1.
//   - Neto / PIBE (SVG + cifras): la cifra de la página es el escalar NetoCicloPIBE<ABREV> de users/…/<ABREV>/neto-pibe.json
//     (contrato-32.do §4b, dividido en Stata y exportado con scalarjson) con el formato de la página, la barra lleva el valor
//     tal cual, y meta.json lo transcribe igual; si no hay neto-pibe.json, la página lo declara («not available»).
//   - Sellos: el conjunto de celdas con marca (listas bajo las gráficas, li[data-sello]) y el de notas al pie agregadas
//     (ol.metodo-notas li[data-sello]) son EXACTAMENTE el conjunto de celdas selladas de meta.json, que a su vez es el de
//     los JSON del motor (sankeys: enlaces sello="1" en los 5 cortes; ciclo: celdas sello=1; tasas: impuestos sello=1);
//     cada nota dice «n = <n>»; la numeración continúa la de las notas de método.
//   - Encabezado y cifras: todos los <span data-ent> se llenaron (ninguno vacío; «n/a» solo en pibe.* cuando no hay PIBE);
//     el n ENIGH del encabezado es el de meta.json; NL muestra la frase fija del espejo CoNL (sin enlace) y las demás no.
//   - Sin errores de JS. Si se da <dirPng>, guarda <dirPng>/<ABREV>.png (página completa) y <dirPng>/indice.png.
// Índice: 32 filas; las de las entidades de prueba llenas con los valores de entidades.json; sin errores.
// Salida: 0 todo verde; 1 algún aserto falló. Imprime una línea por aserto.
const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer-core');
const [urlBase, dirUsers, listaEnt, dirPng] = process.argv.slice(2);
const ENTIDADES = String(listaEnt || '').trim().split(/\s+/).filter(Boolean);
const EXCLUIR_TASAS = ['ISAN', 'IMPORT'];
const CHROME = process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fallos = 0;
const ok = (cond, msg) => { console.log((cond ? 'OK     ' : 'FALLO  ') + msg); if (!cond) fallos++; };
const fmt = (v, min, max) => Number(v).toLocaleString('en-US', { minimumFractionDigits: min, maximumFractionDigits: max });
const igual = (a, b) => JSON.stringify(a) === JSON.stringify(b);

// El archivo del motor es un fragmento JS (claves sin comillas): nodos {label:"…"} y enlaces {to:"…",value:"…",from:"…"[,n:…,top1:…,sello:"…",…]}.
function leerSankey(ruta) {
  const t = fs.readFileSync(ruta, 'utf8');
  const nodos = [...t.matchAll(/\{label:"([^"]*)"\}/g)].map(m => m[1]);
  const enlaces = [...t.matchAll(/\{to:"([^"]*)",value:"([^"]*)",from:"([^"]*)"((?:,[A-Za-z0-9]+:"[^"]*")*)\}/g)].map(m => {
    const extra = {};
    [...m[4].matchAll(/,([A-Za-z0-9]+):"([^"]*)"/g)].forEach(x => { extra[x[1]] = x[2]; });
    return { to: m[1], value: m[2], from: m[3], ...extra };
  });
  return { nodos, enlaces };
}

async function esperar(page, fn, intentos = 150) {
  for (let i = 0; i < intentos; i++) {
    const v = await page.evaluate(fn);
    if (v) return v;
    await sleep(200);
  }
  return null;
}

async function probarEntidad(browser, abrev) {
  const dir = path.join(dirUsers, abrev);
  const meta = JSON.parse(fs.readFileSync(path.join(dir, 'meta.json'), 'utf8'));
  const ciclo = JSON.parse(fs.readFileSync(path.join(dir, 'ciclo-vida.json'), 'utf8'));
  const tasas = JSON.parse(fs.readFileSync(path.join(dir, 'tasas-efectivas.json'), 'utf8'));
  const netoArchivo = fs.existsSync(path.join(dir, 'neto-pibe.json')) ? JSON.parse(fs.readFileSync(path.join(dir, 'neto-pibe.json'), 'utf8')) : null;
  const cortes = ['quintil', 'grupoedad', 'sexo', 'rural', 'escol'];
  const sankeys = {}; cortes.forEach(c => { sankeys[c] = leerSankey(path.join(dir, `sankey-${c}.json`)); });
  console.log(`### ${abrev} — ${meta.entidad.nombre}`);

  // meta.json ⇔ JSON del motor: el conjunto de celdas selladas
  const selladosMotor = [];
  cortes.forEach(c => sankeys[c].enlaces.filter(l => l.sello === '1').forEach(l => selladosMotor.push(`sankey:${c}:${l.from}→${l.to}`)));
  ciclo.celdas.filter(x => x.sello === 1).forEach(x => selladosMotor.push(`ciclo:${x.sexo}:${x.quinquenio}`));
  tasas.impuestos.filter(i => i.sello === 1).forEach(i => selladosMotor.push(`tasas:${i.impuesto}`));
  const selladosMeta = [];
  cortes.forEach(c => ((meta.sellos.sankeys[c] || {}).sellados || []).forEach(l => selladosMeta.push(`sankey:${c}:${l.from}→${l.to}`)));
  meta.sellos.ciclo.forEach(x => selladosMeta.push(`ciclo:${x.sexo}:${x.quinquenio}`));
  meta.sellos.tasas.forEach(t => selladosMeta.push(`tasas:${t.impuesto}`));
  ok(igual(selladosMotor.slice().sort(), selladosMeta.slice().sort()), `meta.json declara exactamente las ${selladosMeta.length} celdas con sello=1 de los JSON del motor (${meta.sellos.texto})`);

  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900 });
  const errores = []; const peticiones = { sankey: [], meta: 0 };
  page.on('pageerror', e => errores.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errores.push(m.text()); });
  page.on('request', r => { const u = r.url(); if (/producto=sankey/.test(u)) peticiones.sankey.push(u); if (/producto=meta/.test(u)) peticiones.meta++; });
  const resp = await page.goto(`${urlBase}/entidades/${abrev}/`, { waitUntil: 'networkidle2', timeout: 90000 });
  ok(resp && resp.status() === 200, `GET /entidades/${abrev}/ responde 200 (${resp && resp.status()})`);

  const listo = await esperar(page, () => {
    const D = window.entidadData;
    return !!(D && D.meta && D.ciclo && D.tasas && D.neto && D.sankeys.quintil
      && document.querySelectorAll('#ent-sankey svg path').length > 0
      && document.querySelectorAll('#ent-ciclo-H svg .apexcharts-bar-area').length > 0
      && document.querySelectorAll('#ent-ciclo-M svg .apexcharts-bar-area').length > 0
      && document.querySelectorAll('#ent-tasas svg rect.ent-tasas-barra').length > 0);
  });
  ok(!!listo, 'los cuatro productos se dibujaron (Sankey FusionCharts, dos ApexCharts del ciclo, barras SVG de tasas)');

  // --- Sankey quintil: idéntico al motor ---
  const rec = await page.evaluate(() => window.entidadData.sankeys.quintil);
  const ori = sankeys.quintil;
  ok(!!rec && igual(rec.nodes.map(n => n.label), ori.nodos), `Sankey quintil: nodos idénticos y en el mismo orden (${ori.nodos.length})`);
  let distintos = [];
  ori.enlaces.forEach((e, i) => { const r = (rec && rec.links[i]) || {}; if (r.from !== e.from || r.to !== e.to || String(r.value) !== e.value) distintos.push(i); });
  ok(rec && rec.links.length === ori.enlaces.length && distintos.length === 0, `Sankey quintil: cada enlace (from, to, value) idéntico como cadena al motor (${ori.enlaces.length - distintos.length}/${ori.enlaces.length})`);
  const conSello = ori.enlaces.map((e, i) => [e, i]).filter(([e]) => e.sello === '1');
  ok(rec && conSello.every(([e, i]) => rec.links[i].toolText && rec.links[i].toolText.indexOf('n = ' + e.n) >= 0) && rec.links.every((l, i) => !!l.toolText === (ori.enlaces[i].sello === '1')), `Sankey quintil: toolText de sello (con su n) exactamente en los ${conSello.length} enlaces con sello=1`);
  const enChart = await page.evaluate(() => { const c = FusionCharts.items['ent-sankey-chart']; if (!c) return null; const d = c.getJSONData(); return { corte: d.chart.corte, values: d.links.map(l => String(l.value)), labels: d.nodes.map(n => n.label) }; });
  ok(enChart && enChart.corte === 'quintil' && igual(enChart.values, ori.enlaces.map(e => e.value)) && igual(enChart.labels, ori.nodos), 'FusionCharts.getJSONData() devuelve los mismos nodos y valores que el origen (quintil)');
  // selector → grupoedad
  await page.click('input[name="ent-corte"][value="grupoedad"]');
  const rec2 = await esperar(page, () => { const c = FusionCharts.items['ent-sankey-chart']; const d = window.entidadData.sankeys.grupoedad; return (d && c && c.getJSONData().chart.corte === 'grupoedad') ? d : null; });
  const ori2 = sankeys.grupoedad;
  ok(!!rec2 && rec2.links.length === ori2.enlaces.length && ori2.enlaces.every((e, i) => rec2.links[i].from === e.from && rec2.links[i].to === e.to && String(rec2.links[i].value) === e.value) && igual(rec2.nodes.map(n => n.label), ori2.nodos), `selector → Age group: el Sankey redibujado trae los ${ori2.enlaces.length} enlaces de sankey-grupoedad.json, idénticos`);
  ok(peticiones.sankey.length === 2, `el Sankey se pidió una vez por corte elegido (${peticiones.sankey.length} peticiones: quintil y grupoedad)`);
  const listaSk = await page.evaluate(() => [...document.querySelectorAll('#ent-sankey-sellos li[data-sello]')].map(li => li.getAttribute('data-sello')));
  const espSk = ori2.enlaces.filter(l => l.sello === '1').map(l => `sankey:grupoedad:${l.from}→${l.to}`);
  ok(igual(listaSk.slice().sort(), espSk.slice().sort()), `la lista bajo el Sankey (grupoedad) tiene exactamente los ${espSk.length} enlaces sellados del motor`);

  // --- Ciclo de vida: series = pct del JSON; ⚠ solo en celdas selladas ---
  const cs = await page.evaluate(() => window.entidadData.cicloSeries);
  const etiquetas = ciclo.grupos.etiquetas;
  for (const [sexo, s] of [['Hombres', 'H'], ['Mujeres', 'M']]) {
    const celdas = ciclo.celdas.filter(c => c.sexo === sexo).sort((a, b) => b.g - a.g);
    const espSeries = etiquetas.map(et => ({ name: et, data: celdas.map(c => { const g = c.grupos.find(x => x.grupo === et); return g ? g.pct : null; }) }));
    const espCat = celdas.map(c => c.quinquenio + (c.sello === 1 ? ' ⚠' : ''));
    ok(cs && cs[s] && igual(cs[s].series, espSeries), `ciclo ${sexo}: las ${etiquetas.length} series son los pct de las ${celdas.length} celdas del JSON (del quinquenio mayor al menor)`);
    ok(cs && cs[s] && igual(cs[s].categorias, espCat), `ciclo ${sexo}: «⚠» exactamente en las ${celdas.filter(c => c.sello === 1).length} celdas con sello=1`);
    const enApex = await page.evaluate(id => { const c = ApexCharts.getChartByID(id); return c ? c.w.globals.series : null; }, `ent-ciclo-${s}`);
    ok(enApex && igual(enApex.map(a => a.map(v => Number(v))), espSeries.map(x => x.data.map(v => v === null ? 0 : Number(v)))) || (enApex && igual(enApex, espSeries.map(x => x.data))), `ciclo ${sexo}: ApexCharts tiene cargadas esas mismas series`);
  }

  // --- Tasas efectivas: una barra por impuesto no excluido, te idéntico, sello exacto ---
  const barras = await page.evaluate(() => [...document.querySelectorAll('#ent-tasas rect.ent-tasas-barra')].map(r => ({ impuesto: r.getAttribute('data-impuesto'), te: r.getAttribute('data-te'), nac: r.getAttribute('data-te-nacional'), sello: r.getAttribute('data-sello') })));
  const espT = tasas.impuestos.filter(i => EXCLUIR_TASAS.indexOf(i.impuesto) < 0);
  ok(barras.length === espT.length && espT.every((i, j) => barras[j].impuesto === i.impuesto && Number(barras[j].te) === i.te && Number(barras[j].nac) === i.te_nacional_micro), `tasas: ${barras.length} barras (sin ${EXCLUIR_TASAS.join('/')}), cada una con el te y el te nacional del JSON`);
  ok(espT.every((i, j) => barras[j] && barras[j].sello === (i.sello === 1 ? '1' : '0')), `tasas: data-sello=1 exactamente en los ${espT.filter(i => i.sello === 1).length} impuestos con sello=1`);
  ok(!barras.some(b => EXCLUIR_TASAS.indexOf(b.impuesto) >= 0), 'tasas: ISAN e IMPORT no se dibujan (tasa nacional por construcción)');

  // --- Neto / PIBE: el escalar de Stata (neto-pibe.json), transcrito igual en meta.json ---
  const neto = await page.evaluate(() => ({
    cifra: (document.querySelector('[data-neto="escalares.NetoCicloPIBE{abrev}.valor"]') || {}).textContent,
    netoBn: (document.querySelector('[data-neto="escalares.NetoCiclo{abrev}.valor"]') || {}).textContent,
    barras: [...document.querySelectorAll('#ent-neto rect.ent-neto-barra')].map(r => r.getAttribute('data-value')),
    nd: !(document.getElementById('ent-neto-nd') || {}).hidden,
    recibido: window.entidadData.neto && window.entidadData.neto.procedencia && window.entidadData.neto.procedencia.generado_en,
  }));
  if (netoArchivo) {
    const esc = netoArchivo.escalares;
    const pct = esc['NetoCicloPIBE' + abrev].valor, pibY = esc['pibY' + abrev].valor, netoEsc = esc['NetoCiclo' + abrev].valor;
    ok(neto.recibido === netoArchivo.procedencia.generado_en, `neto-pibe.json recibido es el del archivo (generado_en ${neto.recibido})`);
    ok(neto.cifra === fmt(pct, 3, 3), `neto / PIBE en la página = ${neto.cifra} % = escalar NetoCicloPIBE${abrev} de Stata (${fmt(pct, 3, 3)})`);
    ok(neto.netoBn === fmt(netoEsc / 1e9, 1, 1), `neto del ciclo en la página = ${neto.netoBn} bn = escalar NetoCiclo${abrev}`);
    ok(neto.barras.length === 2 && neto.barras[0] === String(pct) && neto.barras[1] === String(meta.nacional.neto_pct_pib) && !neto.nd, 'neto / PIBE: dos barras (entidad, nacional) con el escalar tal cual y la razón nacional de meta.json');
    ok(meta.pibe && meta.pibe.neto_pct_pibe === pct && meta.pibe.pibe_pesos === pibY && meta.pibe.neto_pesos === netoEsc && Math.abs(netoEsc - ciclo.totales.entidad.neto) <= 0.005, 'meta.json transcribe los tres escalares sin tocarlos y NetoCiclo = totales.entidad.neto de ciclo-vida.json (a medio centavo: el JSON va con 2 decimales)');
    ok(Math.abs(netoEsc / pibY * 100 - pct) <= 1e-9 * Math.abs(pct), 'control: el escalar de Stata es neto / PIBE × 100 (1e-9 relativo)');
  } else {
    ok(neto.nd && neto.barras.length === 0 && !meta.pibe, 'sin neto-pibe.json: la página lo declara, no dibuja la razón y meta.json no inventa el bloque pibe');
  }

  // --- Sellos: listas + notas al pie = meta.json (y nada más) ---
  const sellosPag = await page.evaluate(() => ({
    listas: [...document.querySelectorAll('.ent-sellos li[data-sello]')].map(li => li.getAttribute('data-sello')),
    notas: [...document.querySelectorAll('ol.metodo-notas li[data-sello]')].map(li => ({ clave: li.getAttribute('data-sello'), n: li.getAttribute('data-n'), texto: li.textContent, num: li.value })),
    notasMetodo: document.querySelectorAll('ol.metodo-notas li:not([data-sello])').length,
    refs: [...document.querySelectorAll('.ent-sellos sup.metodo-nota-ref a')].map(a => a.getAttribute('href')),
  }));
  const espListas = selladosMeta.filter(k => !k.startsWith('sankey:') || k.startsWith('sankey:grupoedad:'));   // la lista del Sankey es la del corte vigente
  ok(igual(sellosPag.listas.slice().sort(), espListas.slice().sort()), `listas de sellos bajo las gráficas: ${sellosPag.listas.length} = celdas selladas de meta.json (ciclo + tasas + Sankey del corte vigente)`);
  ok(igual(sellosPag.notas.map(x => x.clave).sort(), selladosMeta.slice().sort()), `notas al pie de sellos: ${sellosPag.notas.length} = las ${selladosMeta.length} celdas selladas de meta.json, ninguna de más`);
  const nPorClave = {};
  cortes.forEach(c => ((meta.sellos.sankeys[c] || {}).sellados || []).forEach(l => { nPorClave[`sankey:${c}:${l.from}→${l.to}`] = l.n; }));
  meta.sellos.ciclo.forEach(x => { nPorClave[`ciclo:${x.sexo}:${x.quinquenio}`] = x.n; });
  meta.sellos.tasas.forEach(t => { nPorClave[`tasas:${t.impuesto}`] = t.n; });
  ok(sellosPag.notas.every(x => x.texto.indexOf('n = ' + fmt(nPorClave[x.clave], 0, 0)) >= 0 && x.texto.indexOf('indicative') >= 0), 'cada nota de sello dice «n = <n> … read as indicative» con el n de meta.json');
  ok(sellosPag.notas.every((x, i) => x.num === sellosPag.notasMetodo + i + 1), `la numeración de las notas de sellos continúa la de las ${sellosPag.notasMetodo} notas de método (${sellosPag.notasMetodo + 1}…${sellosPag.notasMetodo + sellosPag.notas.length})`);
  ok(sellosPag.refs.every(h => /^#nota-\d+$/.test(h)) && sellosPag.refs.length === sellosPag.listas.length, 'cada marca en las listas lleva su superíndice a la nota');

  // --- Encabezado y cifras ---
  const cifras = await page.evaluate(() => [...document.querySelectorAll('[data-ent]')].map(el => ({ ruta: el.getAttribute('data-ent'), texto: el.textContent })));
  const lee = (o, ruta) => ruta.split('.').reduce((v, k) => (v === undefined || v === null) ? undefined : v[k], o);
  const vacias = cifras.filter(c => c.texto === '' || (c.texto === 'n/a' && lee(meta, c.ruta) !== null && lee(meta, c.ruta) !== undefined));
  ok(cifras.length > 0 && vacias.length === 0, `las ${cifras.length} cifras <span data-ent> se llenaron desde meta.json (n/a solo donde meta.json trae null: ${cifras.filter(c => c.texto === 'n/a').length})${vacias.length ? ' (vacías o n/a indebidos: ' + vacias.map(c => c.ruta).join(', ') + ')' : ''}`);
  const nEnc = cifras.find(c => c.ruta === 'muestra.n');
  ok(nEnc && nEnc.texto === fmt(meta.muestra.n, 0, 0), `n ENIGH del encabezado = ${nEnc && nEnc.texto} (meta.json: ${fmt(meta.muestra.n, 0, 0)})`);
  const espejo = await page.evaluate(() => { const p = document.getElementById('ent-espejo'); return p ? { texto: p.textContent.trim(), enlaces: p.querySelectorAll('a').length } : null; });
  if (abrev === 'NL') ok(espejo && espejo.enlaces === 0 && espejo.texto === 'Nuevo León also has a dedicated mirror (SimuladorCoNL) maintained with Consejo Nuevo León; available on request.', 'NL: frase fija del espejo CoNL, sin enlace');
  else ok(espejo === null, `${abrev}: sin línea de espejo`);
  const fuente = await page.evaluate(() => (document.querySelector('.metodo-fuente') || {}).textContent || '');
  ok(/Source/.test(fuente) && /ENIGH/.test(fuente), 'pie de fuente presente');
  ok(errores.length === 0, `sin errores de JS en la página${errores.length ? ': ' + errores.slice(0, 3).join(' | ') : ''}`);

  if (dirPng) {
    await page.click('input[name="ent-corte"][value="quintil"]');
    await esperar(page, () => { const c = FusionCharts.items['ent-sankey-chart']; return c && c.getJSONData().chart.corte === 'quintil'; });
    await sleep(800);
    const png = path.join(dirPng, `${abrev}.png`);
    await page.screenshot({ path: png, fullPage: true });
    ok(fs.existsSync(png) && fs.statSync(png).size > 0, `captura guardada en ${png}`);
  }
  await page.close();
}

async function probarIndice(browser) {
  console.log('### índice /entidades');
  const indice = JSON.parse(fs.readFileSync(path.join(dirUsers, 'entidades.json'), 'utf8'));
  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900 });
  const errores = [];
  page.on('pageerror', e => errores.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errores.push(m.text()); });
  const resp = await page.goto(`${urlBase}/entidades/`, { waitUntil: 'networkidle2', timeout: 90000 });
  ok(resp && resp.status() === 200, `GET /entidades/ responde 200 (${resp && resp.status()})`);
  const llenas = await esperar(page, () => document.getElementById('ent-indice') && document.getElementById('ent-indice').getAttribute('data-filas-llenas'));
  ok(llenas === String(indice.entidades.length), `la tabla se llenó desde entidades.json (${llenas} entidades con datos)`);
  const filas = await page.evaluate(() => [...document.querySelectorAll('#ent-indice tbody tr[data-abrev]')].map(tr => ({ abrev: tr.getAttribute('data-abrev'), n: tr.querySelector('td[data-col="n"]').textContent, sellos: tr.querySelector('td[data-col="sellos_texto"]').textContent, neto: tr.querySelector('td[data-col="neto_pct_pibe"]').textContent, href: tr.querySelector('a').getAttribute('href') })));
  ok(filas.length === 32, `32 filas (${filas.length})`);
  const por = {}; indice.entidades.forEach(e => { por[e.abrev] = e; });
  const mal = filas.filter(f => por[f.abrev] ? (f.n !== fmt(por[f.abrev].n, 0, 0) || f.sellos !== por[f.abrev].sellos_texto || f.neto !== (por[f.abrev].neto_pct_pibe === null ? 'n/a' : fmt(por[f.abrev].neto_pct_pibe, 3, 3))) : f.n !== 'n/a');
  ok(mal.length === 0, `cada fila trae n, sellos y neto/PIBE de entidades.json (o n/a si la entidad no viene)${mal.length ? ': ' + mal.map(f => f.abrev).join(', ') : ''}`);
  ok(filas.every(f => f.href === `/entidades/${f.abrev}/`), 'cada fila enlaza a /entidades/<ABREV>/');
  ok(errores.length === 0, `sin errores de JS en el índice${errores.length ? ': ' + errores.slice(0, 3).join(' | ') : ''}`);
  if (dirPng) {
    const png = path.join(dirPng, 'indice.png');
    await page.screenshot({ path: png, fullPage: true });
    ok(fs.existsSync(png) && fs.statSync(png).size > 0, `captura guardada en ${png}`);
  }
  await page.close();
}

(async () => {
  ok(ENTIDADES.length > 0, `entidades a probar: ${ENTIDADES.join(', ')}`);
  if (dirPng) fs.mkdirSync(dirPng, { recursive: true });
  const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox', '--hide-scrollbars'] });
  for (const e of ENTIDADES) await probarEntidad(browser, e);
  await probarIndice(browser);
  await browser.close();
  console.log(fallos === 0 ? 'RESULTADO: /entidades OK (0 fallos)' : `RESULTADO: ${fallos} fallo(s)`);
  process.exit(fallos === 0 ? 0 : 1);
})().catch(e => { console.error('FALLO  excepción: ' + e); process.exit(1); });
