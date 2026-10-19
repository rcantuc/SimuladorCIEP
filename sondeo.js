// sondeo.js <puerto> <etiqueta> — tras el POST de «Calcular», muestrea cada 100 ms durante ~6 s las animaciones CSS vivas
// (document.getAnimations()) y registra qué elementos adquieren/pierden clases con "blink".
const puppeteer = require('/tmp/shots/node_modules/puppeteer-core');
const [port, etiqueta] = process.argv.slice(2); const sleep = ms => new Promise(r => setTimeout(r, ms));
(async () => {
  const b = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: 'new', args: ['--no-sandbox', '--hide-scrollbars'] });
  const p = await b.newPage(); await p.setViewport({ width: 1440, height: 900 }); p.on('dialog', d => d.dismiss());
  await p.goto(`http://localhost:${port}/index.php`, { waitUntil: 'networkidle2', timeout: 90000 }); await sleep(3000);
  await p.evaluate(() => { window.__muts = []; new MutationObserver(ms => ms.forEach(m => { if (m.attributeName === 'class') { const t = m.target, c = t.className || ''; const old = m.oldValue || ''; if (/blink|flash|pulse|highlight/.test(c + ' ' + old)) window.__muts.push({ t: Math.round(performance.now()), el: (t.id ? '#' + t.id : t.tagName.toLowerCase()) + '.' + String(c).replace(/\s+/g, '.').slice(0, 60), ahora: /blink|flash|pulse|highlight/.test(c) }); } })).observe(document.documentElement, { subtree: true, attributes: true, attributeOldValue: true, attributeFilter: ['class'] }); });
  const t0 = await p.evaluate(() => { document.querySelector('#isrSub').click(); return Math.round(performance.now()); });
  const muestras = []; for (let i = 0; i < 80; i++) { await sleep(100); muestras.push(await p.evaluate(() => document.getAnimations().filter(a => a.animationName && !/spinner|grow|sk-|loading/i.test(a.animationName)).map(a => a.animationName + ' @' + (a.effect.target.id ? '#' + a.effect.target.id : a.effect.target.tagName.toLowerCase()))).then(a => [...new Set(a)])); }
  const muts = await p.evaluate(() => window.__muts);
  const res = { etiqueta, mutaciones: muts.map(m => ({ ...m, t: m.t - t0 })).slice(0, 40), n_mut: muts.length, animaciones_vivas: muestras.map((m, i) => [(i + 1) * 100, m]).filter(x => x[1].length).map(x => x[0] + 'ms: ' + x[1].join(', ')).slice(0, 12) };
  console.log(JSON.stringify(res, null, 1)); await b.close();
})();
