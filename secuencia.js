// secuencia.js <puerto> <prefijo> — tras el POST, 9 cuadros cada ~250 ms de la primera tabla visible del escenario.
const puppeteer = require('/tmp/shots/node_modules/puppeteer-core'); const [port, pref] = process.argv.slice(2); const sleep = ms => new Promise(r => setTimeout(r, ms));
(async () => { const b = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: 'new', args: ['--no-sandbox', '--hide-scrollbars'] });
const p = await b.newPage(); await p.setViewport({ width: 1440, height: 900 }); p.on('dialog', d => d.dismiss());
await p.goto(`http://localhost:${port}/index.php`, { waitUntil: 'networkidle2' }); await sleep(3000);
await p.evaluate(() => { window.__fin = false; $(document).ajaxComplete((e, x, o) => { if (/calculaStata/.test(o.url)) window.__fin = true; }); });
await p.evaluate(() => document.querySelector('#isrSub').click());
await p.waitForFunction(() => window.__fin, { timeout: 60000, polling: 50 });
const clip = await p.evaluate(() => { const t = [...document.querySelectorAll('.table')].find(e => e.getBoundingClientRect().height > 80 && e.getBoundingClientRect().top < 800 && e.getBoundingClientRect().top > 0) || document.querySelector('.table'); t.scrollIntoView({ block: 'center' }); const r = t.getBoundingClientRect(); return { x: Math.max(0, r.x + scrollX), y: Math.max(0, r.y + scrollY), width: Math.min(r.width, 700), height: Math.min(r.height, 260) }; });
for (let i = 0; i < 9; i++) { await p.screenshot({ path: `${pref}-${i}.png`, clip }); await sleep(250); }
await b.close(); })();
