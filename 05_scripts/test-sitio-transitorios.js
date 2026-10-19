// test-sitio-transitorios.js <urlBase> <urlBase429> — efectos TRANSITORIOS del «Calcular», con Chrome headless (puppeteer-core).
// Los efectos de un segundo no dejan rastro en el DOM final: una captura de "resultados" no los ve (v8.12.2 perdió el
// parpadeo de las tablas y el refresco de los Sankeys con 0 px de diferencia). Aquí se muestrea el DOM cada ~100 ms.
//
//  T1 parpadeo  tras el POST: las tablas (.table) adquieren `blink-1`, la animación corre, y la pierden (~1.5 s)
//  T2 sankeys   tras el POST: se piden los 5 jsonSankey*.php de la sesión (refresco)
//  T3 flags     moduloCambio / moduloCambioIva vuelven a 0 tras un cálculo exitoso
//  T4 reloj     (v8.12.2) valor inicial = CIEP_TIEMPOS[flujo]; se apaga al terminar; «Finalizando…» si la cuenta se acaba antes
//  T5 429       (v8.11c/v8.12.2) con el freno activo: aviso apagado, flags conservados, mensaje del servidor
// Salida: 0 todo verde; 1 algún aserto falló. Imprime una línea por aserto y la secuencia muestreada del parpadeo.
const puppeteer = require('puppeteer-core');
const [urlBase, url429] = process.argv.slice(2);
const CHROME = process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fallos = 0;
const ok = (cond, msg) => { console.log((cond ? 'OK     ' : 'FALLO  ') + msg); if (!cond) fallos++; };

async function abrir(browser, base, ruta) {
  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900 });
  page.on('dialog', d => { page.__dialogos = (page.__dialogos || []).concat(d.message()); d.dismiss(); });
  await page.goto(`${base}/${ruta}`, { waitUntil: 'networkidle2', timeout: 90000 });
  await sleep(2500);
  return page;
}

(async () => {
  const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox', '--hide-scrollbars'] });

  // ---------------- T1-T3: éxito, con moduloCambio = 1 para ver el reinicio de flags ----------------
  for (const ruta of ['index.php', 'index-en.php']) {
    const L = ruta === 'index.php' ? 'ES' : 'EN';
    const page = await abrir(browser, urlBase, ruta);
    await page.evaluate(() => {
      window.__peticiones = []; window.__finPost = null;
      $(document).ajaxSend((e, x, o) => window.__peticiones.push({ t: performance.now(), url: o.url, fase: 'envio' }));
      $(document).ajaxComplete((e, x, o) => { if (/calculaStata/.test(o.url)) window.__finPost = performance.now(); });
      $('#moduloCambio').val(1);
      window.__ntablas = document.querySelectorAll('.table').length;
      document.querySelector('#isrSub').click();
    });
    const muestras = [];
    const t0 = Date.now();
    while (Date.now() - t0 < 14000) {
      const s = await page.evaluate(() => ({
        fin: window.__finPost !== null,
        conBlink: document.querySelectorAll('.table.blink-1').length,
        anim: document.getAnimations().some(a => a.animationName === 'blink-1'),
      }));
      muestras.push({ ms: Date.now() - t0, ...s });
      if (s.fin && muestras.filter(m => m.fin).length > 30) break;   // ~3 s después del fin del POST
      await sleep(100);
    }
    const ntablas = await page.evaluate(() => window.__ntablas);
    const post = muestras.filter(m => m.fin);
    const adquiere = post.find(m => m.conBlink > 0);
    const pierde = adquiere && post.find(m => m.ms > adquiere.ms && m.conBlink === 0);
    const maxBlink = Math.max(0, ...post.map(m => m.conBlink));
    console.log(`# [${L}] secuencia (ms desde el clic: tablas con blink-1 / animación blink-1 viva), tras el fin del POST:`);
    console.log('# ' + post.filter((m, i) => i % 3 === 0).map(m => `${m.ms}:${m.conBlink}${m.anim ? '*' : ''}`).join('  '));
    ok(ntablas > 0, `T1 [${L}] hay tablas (.table) en la página (${ntablas})`);
    ok(!!adquiere, `T1 [${L}] tras el POST las tablas adquieren la clase blink-1`);
    ok(maxBlink === ntablas, `T1 [${L}] parpadean TODAS las tablas, como el original (${maxBlink}/${ntablas})`);
    ok(post.some(m => m.anim), `T1 [${L}] la animación CSS blink-1 está corriendo (document.getAnimations)`);
    ok(!!pierde, `T1 [${L}] y luego pierden la clase (el parpadeo termina)`);
    if (adquiere && pierde) {
      const dur = pierde.ms - adquiere.ms;
      ok(dur >= 1200 && dur <= 2200, `T1 [${L}] duración del parpadeo ≈ 1.5 s (medida ${dur} ms; original: setTimeout 1500)`);
    }
    // hook registrado tras la carga: solo ve peticiones posteriores al clic; las de jsonSankey* son el refresco
    const sk = await page.evaluate(() => window.__peticiones.filter(p => /jsonSankey/.test(p.url)).map(p => ({ url: p.url })));
    const refresco = sk;
    const urls = [...new Set(refresco.map(p => p.url.split('/').pop()))].sort();
    ok(urls.length === 5, `T2 [${L}] tras el POST se refrescan los 5 Sankeys (${urls.join(', ') || 'ninguno'})`);
    const flags = await page.evaluate(() => [$('#moduloCambio').val(), $('#moduloCambioIva').val()]);
    ok(flags[0] === '0' && flags[1] === '0', `T3 [${L}] moduloCambio/moduloCambioIva vuelven a 0 tras un cálculo exitoso (${flags.join(',')})`);
    const visible = await page.evaluate(() => getComputedStyle(document.querySelector('#cargando-notify')).display !== 'none');
    ok(!visible, `T4 [${L}] el aviso «Calculando…» se apaga al terminar`);
    await page.close();
  }

  // ---------------- T4: valor inicial por flujo y «Finalizando…» ----------------
  {
    const page = await abrir(browser, urlBase, 'index.php');
    const r = await page.evaluate(async () => {
      const lee = () => document.querySelector('#count').textContent.trim();
      const out = {};
      for (const [a, b, flujo] of [[0, 0, 'principal'], [1, 0, 'isr'], [0, 1, 'iva'], [1, 1, 'isr_iva']]) {
        $('#moduloCambio').val(a); $('#moduloCambioIva').val(b);
        CIEPCronometro.iniciar(CIEPCronometro.flujo()); out[flujo] = { texto: lee(), esperado: String(CIEP_TIEMPOS[flujo]) };
        CIEPCronometro.terminar();
      }
      return out;
    });
    for (const [f, v] of Object.entries(r)) ok(v.texto === v.esperado, `T4 flujo ${f}: el reloj arranca en ${v.texto} (CIEP_TIEMPOS = ${v.esperado})`);
    // cuenta de 2 s con un run de ~5 s: debe pasar a «Finalizando…» y apagarse al llegar la respuesta
    await page.evaluate(() => { CIEP_TIEMPOS.principal = 2; $('#moduloCambio').val(0); $('#moduloCambioIva').val(0); document.querySelector('#isrSub').click(); });
    await sleep(3600);
    const fin = await page.evaluate(() => ({ visible: getComputedStyle(document.querySelector('#cargando-notify')).display !== 'none', fin: getComputedStyle(document.querySelector('#cargando-notify .cronometro-fin')).display !== 'none', cuenta: getComputedStyle(document.querySelector('#cargando-notify .cronometro-cuenta')).display !== 'none' }));
    ok(fin.visible && fin.fin && !fin.cuenta, 'T4 si la cuenta se acaba antes que el run: «Finalizando…» (sin cifra) y el aviso sigue encendido');
    await page.waitForFunction(() => getComputedStyle(document.querySelector('#cargando-notify')).display === 'none', { timeout: 30000 }).then(() => ok(true, 'T4 y se apaga al llegar la respuesta'), () => ok(false, 'T4 el aviso no se apagó al llegar la respuesta'));
    await page.close();
  }

  // ---------------- T5: 429 ----------------
  if (url429) {
    const page = await abrir(browser, url429, 'index.php');
    await page.evaluate(() => { $('#moduloCambio').val(1); document.querySelector('#isrSub').click(); });
    await sleep(2500);
    const r = await page.evaluate(() => ({ visible: getComputedStyle(document.querySelector('#cargando-notify')).display !== 'none', flag: $('#moduloCambio').val() }));
    ok(!r.visible, 'T5 con un 429 el aviso «Calculando…» queda apagado (no hay spinner eterno)');
    ok(r.flag === '1', `T5 con un 429 se conserva moduloCambio para el reintento (${r.flag})`);
    ok((page.__dialogos || []).some(m => /ocupado|busy|muchos|too many/i.test(m)), `T5 el mensaje del servidor se muestra al usuario (${(page.__dialogos || [])[0] || 'ninguno'})`);
    await page.close();
  }

  await browser.close();
  console.log(fallos ? `RESULTADO: ${fallos} fallo(s) en los efectos transitorios del «Calcular»` : 'RESULTADO: efectos transitorios del «Calcular» OK (parpadeo, refresco de Sankeys, flags, reloj, 429)');
  process.exit(fallos ? 1 : 0);
})().catch(e => { console.error('ERROR del test:', e); process.exit(2); });
