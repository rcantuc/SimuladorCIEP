#!/usr/bin/env python3
"""nl-estilo-build.py - genera nl-assets/nl-estilo-assets.js (NL-0.4.1).

Toma los activos de identidad CoNL versionados en nl-assets/identidad/ (subsets WOFF2 de
Poppins SemiBold, Inter Regular e Inter SemiBold — SIL OFL 1.1, licencias incluidas — y el
logotipo vectorial oficial en color y en blanco) y los escribe como data: URI en un solo
archivo JS que los drivers inyectan en la marca /*__NL_ESTILO_ASSETS__*/ de cada plantilla.
Así el HTML final sigue siendo UN archivo sin red. Se corre a mano cuando cambian los activos;
el resultado se commitea. Registra SHA-256 y bytes de cada activo para la procedencia.
Uso:  python3 01_modulos/nl-assets/nl-estilo-build.py
"""
import base64, hashlib, json, os, time

here = os.path.dirname(os.path.abspath(__file__))
idd = os.path.join(here, "identidad")
out = os.path.join(here, "nl-estilo-assets.js")

ASSETS = [
	("poppins600", "Poppins-SemiBold.sub.woff2", "font/woff2", "Poppins SemiBold 600 (títulos); subset Latin + Latin Ext-A + puntuación; OFL 1.1"),
	("inter400", "Inter-Regular.sub.woff2", "font/woff2", "Inter 24pt Regular 400 (cuerpo); subset; tnum/pnum/lnum; OFL 1.1"),
	("inter600", "Inter-SemiBold.sub.woff2", "font/woff2", "Inter 24pt SemiBold 600 (énfasis, totales); subset; OFL 1.1"),
	("logo", "conl-logotipo.svg", "image/svg+xml", "Logotipo Consejo Nuevo León con descriptor, texto morado (vector oficial consejonl_logotipo.ai, Pantone 518/326/130 C -> RGB de marca)"),
	("logoBlanco", "conl-logotipo-blanco.svg", "image/svg+xml", "Logotipo en blanco para fondo morado (aplicación cromática permitida por el BrandBook)"),
]

def sha(p):
	h = hashlib.sha256()
	with open(p, "rb") as f:
		h.update(f.read())
	return h.hexdigest()

parts = []
meta = []
total = 0
for key, fn, mime, desc in ASSETS:
	p = os.path.join(idd, fn)
	data = open(p, "rb").read()
	b64 = base64.b64encode(data).decode("ascii")
	total += len(b64)
	# Líneas cortas: Mata fget() lee el archivo línea a línea; se concatena en JS por trozos de 2,000 caracteres.
	chunks = [b64[i:i + 2000] for i in range(0, len(b64), 2000)]
	parts.append('  %s: "data:%s;base64," +\n%s' % (key, mime, " +\n".join('    "%s"' % c for c in chunks)))
	meta.append({"key": key, "archivo": "01_modulos/nl-assets/identidad/" + fn, "bytes": len(data), "sha256": sha(p), "descripcion": desc})

js = ("/* nl-estilo-assets.js — GENERADO por nl-estilo-build.py (%s). NO editar a mano.\n"
	"   Activos de identidad CoNL embebidos como data: URI (cero red): fuentes Poppins/Inter (SIL OFL 1.1,\n"
	"   licencias en nl-assets/identidad/OFL-*.txt) y logotipo vectorial oficial. Procedencia en NLEstiloAssets.meta. */\n"
	"window.NLEstiloAssets = {\n%s,\n  meta: %s\n};\n") % (time.strftime("%Y-%m-%d"), ",\n".join(parts), json.dumps(meta, ensure_ascii=False, indent=2))
open(out, "w", encoding="utf-8").write(js)
print("escrito", out, "bytes", os.path.getsize(out), "| data URIs base64 total KB", total // 1024)
for m in meta:
	print("  ", m["key"], m["bytes"], m["sha256"][:16])
