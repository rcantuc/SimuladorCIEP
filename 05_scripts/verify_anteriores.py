#!/usr/bin/env python3
"""verify_anteriores.py — Auditoría estática del museo de versiones (04_3_anteriores/).

Para cada generación (v1..v4) y para index.html revisa que todo recurso local
referido desde HTML y CSS exista en disco, y que no queden referencias a hosts
de desarrollo (localhost, ddns) ni a Google Tag Manager. Es el Gate 2 de
publicar-anteriores.sh; exit 0 si no hay fallas, 1 si las hay.

Uso: python3 05_scripts/verify_anteriores.py [--verbose]
"""
import glob, os, re, sys, urllib.parse, collections

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), '04_3_anteriores')
PROHIBIDOS = re.compile(r'(localhost:\d+|ciep-mx\.ddns\.net|googletagmanager\.com|google-analytics\.com)', re.I)
# mixed content: el sitio es https; cualquier recurso activo por http:// lo bloquea el navegador
MIXED = re.compile(r'(?:src|href)=["\']\s*(http://[^"\']+)|url\(["\']?\s*(http://[^"\')]+)|@import\s+url\(["\']?(http://[^"\')]+)', re.I)
verbose = '--verbose' in sys.argv

def local(path_from, ref):
    ref = urllib.parse.unquote(ref.split('?')[0].split('#')[0])
    base = os.path.dirname(path_from)
    if os.path.basename(base) == 'parts':      # los parts se inyectan por AJAX en la página padre: sus rutas son relativas a ella
        base = os.path.dirname(base)
    return os.path.normpath(os.path.join(base, ref))

fallas = 0
for v in ['.', 'v1', 'v2', 'v3', 'v4']:
    htmls = sorted(glob.glob(os.path.join(ROOT, v, '*.html')) + (glob.glob(os.path.join(ROOT, v, '**', '*.html'), recursive=True) if v != '.' else []))
    htmls = sorted(set(htmls))
    csss = glob.glob(os.path.join(ROOT, v, '**', '*.css'), recursive=True) if v != '.' else []
    refs = collections.Counter(); prohib = collections.Counter()
    for pg in htmls:
        s = open(pg, encoding='utf-8', errors='replace').read()
        s = re.sub(r'<!--.*?-->', '', s, flags=re.S)   # comentarios HTML (incluye bloques solo-IE)
        for m in re.findall(r'(?:src|href|data-src|poster)=["\']([^"\'#]+)', s):
            if not m.strip() or m.startswith(('mailto:', 'javascript:', 'data:', 'tel:')): continue
            if re.match(r'(https?:)?//', m):
                if PROHIBIDOS.search(m): prohib[m] += 1
            else:
                refs[local(pg, m)] += 1
        s_sin = re.sub(r'<!--.*?-->', '', re.sub(r'/\*.*?\*/', '', s, flags=re.S), flags=re.S)
        for m in re.findall(r'url\(["\']?([^"\')]+)["\']?\)', s_sin):
            if not re.match(r'(https?:)?//|data:', m): refs[local(pg, m)] += 1
        for m in PROHIBIDOS.findall(s_sin): prohib[m] += 1
        for g in MIXED.findall(s_sin):
            u = next(x for x in g if x)
            if not u.startswith('http://ciep.mx') or True: prohib['http:// (mixed content) ' + u.split('/')[2]] += 1
        # cargas AJAX (.load / url:) de la propia pieza: tambien deben existir
        for m in re.findall(r'(?:\.load\(|url\s*:\s*)["\']((?!https?:|//)[^"\'?]+)', s_sin):
            if re.search(r'\.(html|xml|php|json)$', m): refs[local(pg, m)] += 1
    for jsf in (glob.glob(os.path.join(ROOT, v, 'js', '*.js')) if v != '.' else []):
        s = re.sub(r'/\*.*?\*/|//[^\n]*', '', open(jsf, encoding='utf-8', errors='replace').read(), flags=re.S)
        for m in re.findall(r'url\s*:\s*["\']([A-Za-z0-9_./-]+\.(?:xml|html|json))["\']', s):
            refs[os.path.normpath(os.path.join(ROOT, v, m))] += 1
    for css in csss:
        s = open(css, encoding='utf-8', errors='replace').read()
        s = re.sub(r'/\*.*?\*/', '', s, flags=re.S)   # las url() comentadas no cuentan
        for g in MIXED.findall(s):
            u = next(x for x in g if x); prohib['http:// (mixed content, css) ' + u.split('/')[2]] += 1
        for m in re.findall(r'url\(["\']?([^"\')]+)["\']?\)', s):
            if not re.match(r'(https?:)?//|data:', m): refs[local(css, m)] += 1
    faltan = sorted(p for p in refs if not os.path.exists(p))
    n = len(faltan) + len(prohib)
    fallas += n
    tag = 'OK ' if n == 0 else 'FALLA'
    print(f"[{tag}] {v if v != '.' else 'index'}: {len(htmls)} html, {len(refs)} recursos locales, {len(faltan)} faltantes, {sum(prohib.values())} referencias prohibidas")
    for p in faltan[: (999 if verbose else 15)]:
        print(f"        falta  {os.path.relpath(p, ROOT)}  (x{refs[p]})")
    for p, c in prohib.most_common(999 if verbose else 10):
        print(f"        prohibido  {p}  (x{c})")
print(f"TOTAL fallas: {fallas}")
sys.exit(0 if fallas == 0 else 1)
