"""nl_bie.py - lectores INEGI (BIE por area geografica; programa INPC) de la capa NL.

Modulo Python importado desde 01_modulos/nl-assets/nl-bie.do. Las funciones
publican sus metadatos en globals de Stata NLBIE_* (titulo, fecha, area,
ultimo, n), que el programa Stata lee y limpia. Ver nl-bie.do para el porque.
"""
import re, html, ssl, time, os
import urllib.request, urllib.parse
from sfi import Macro

_UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0 Safari/537.36"
_CTX = ssl.create_default_context()
try:
	_CTX.load_default_certs()
except Exception:
	pass

def _get(url, data=None, headers=None, tries=3):
	h = {"User-Agent": _UA}
	if headers:
		h.update(headers)
	last = None
	for i in range(tries):
		try:
			req = urllib.request.Request(url, data=data, headers=h)
			try:
				return urllib.request.urlopen(req, timeout=120, context=_CTX).read()
			except ssl.SSLError:
				ctx = ssl.create_default_context()
				ctx.check_hostname = False
				ctx.verify_mode = ssl.CERT_NONE
				return urllib.request.urlopen(req, timeout=120, context=ctx).read()
		except Exception as e:
			last = e
			time.sleep(2)
	raise last

def _clean_num(s):
	s = s.replace(",", "").replace(" ", "").strip()
	if s in ("", "ND", "N/E", "-", "N/D"):
		return ""
	try:
		return str(float(s))
	except Exception:
		return ""

def nlbie_fetch(indicador, csv_path, meta_path):
	"""Exporta un indicador del BIE con TODAS sus areas geograficas (tabla completa)
	y la cachea con el sello de revision de cada observacion (p1, r1, ...).
	El filtro por area lo hace el consumidor (_NLbie). Escritura atomica: si el
	formato es inesperado se aborta y el ultimo cache bueno queda intacto."""
	params = {"cveser": indicador, "bie": "false", "aamin": "1980", "aamax": "9999",
		"ordena": "a", "ordenaPeriodo": "ap", "orientacion": "v", "frecuencia": "Todo",
		"estadistico": "false", "FileFormat": "iqy", "ag": "0", "subapp": "BIE",
		"tematica": "3", "tyExp": "1", "view": "filas"}
	url = "https://www.inegi.org.mx/app/indicadores/exportacion.aspx?" + urllib.parse.urlencode(params)
	raw = _get(url)
	try:
		t = raw.decode("utf-8")
	except UnicodeDecodeError:
		t = raw.decode("windows-1252", "replace")
	m = re.search(r'<table[^>]*id="tableContainerSinScroll"[^>]*>(.*?)</table>', t, re.S)
	if not m:
		raise RuntimeError("BIE: el indicador %s no devolvio tabla (formato inesperado); se conserva el ultimo cache" % indicador)
	rows = re.findall(r"<tr[^>]*>(.*?)</tr>", m.group(1), re.S)
	ths = [html.unescape(re.sub("<[^>]+>", "", x)).strip() for x in re.findall(r"<th[^>]*>(.*?)</th>", rows[0], re.S)]
	if len(ths) < 3 or "rea geogr" not in ths[1].lower():
		raise RuntimeError("BIE: el indicador %s no trae la columna de area geografica (formato inesperado); se conserva el ultimo cache" % indicador)
	titulo = ths[-1]
	fm = re.search(r"Fecha de consulta:\s*([0-9/]+\s+[0-9:]+)", t)
	fecha = fm.group(1) if fm else ""
	out = []
	areas = {}
	for r in rows[1:]:
		cells = [html.unescape(re.sub("<[^>]+>", "", c)).strip() for c in re.findall(r"<td[^>]*>(.*?)</td>", r, re.S)]
		if len(cells) < 3:
			continue
		periodo, ageo, valor = cells[0], cells[1], cells[2]
		nm = re.search(r"\s*/?\s*([A-Za-z]+\d*)\s*$", periodo)
		nota = nm.group(1) if nm else ""
		periodo = re.sub(r"\s*/?\s*[A-Za-z]+\d*\s*$", "", periodo).strip()
		areas[ageo[:2]] = ageo
		out.append((periodo, ageo[:2], _clean_num(valor), nota))
	if not out:
		raise RuntimeError("BIE: el indicador %s no trae filas (formato inesperado); se conserva el ultimo cache" % indicador)
	tmp = csv_path + ".tmp"
	with open(tmp, "w", encoding="utf-8") as f:
		f.write("periodo,area,valor,nota\n")
		for p, a, v, n in out:
			f.write("%s,%s,%s,%s\n" % (p, a, v, n))
	os.replace(tmp, csv_path)
	with open(meta_path + ".tmp", "w", encoding="utf-8") as f:
		f.write("titulo=%s\nfecha_consulta=%s\nareas=%s\nn=%d\nurl=%s\n" % (titulo, fecha, ";".join(sorted(areas.values())), len(out), url))
	os.replace(meta_path + ".tmp", meta_path)
	Macro.setGlobal("NLBIE_titulo", titulo)
	Macro.setGlobal("NLBIE_fecha", fecha)
	Macro.setGlobal("NLBIE_n", str(len(out)))

_MESES = {"Ene": 1, "Feb": 2, "Mar": 3, "Abr": 4, "May": 5, "Jun": 6, "Jul": 7, "Ago": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dic": 12}

def nlinpc_fetch(serie, estructura, csv_path, meta_path):
	"""Exporta una serie mensual del programa INPC de INEGI (indicesdeprecios) en CSV."""
	url = "https://www.inegi.org.mx/app/indicesdeprecios/Exportacion.aspx?INPtipoExporta=CSV"
	form = {"idEstructura": estructura, "_formato": "CSV", "_anioI": "1969", "_anioF": "2099",
		"_meta": "0", "_tipo": "Niveles", "_info": "Indices", "_orient": "vertical", "esquema": "",
		"cvEstructura": estructura, "pf": "inp", "cuadro": estructura, "_series": "c|%s," % serie}
	raw = _get(url, data=urllib.parse.urlencode(form).encode("utf-8"),
		headers={"Content-Type": "application/x-www-form-urlencoded"})
	t = raw.decode("windows-1252", "replace")
	if "<html" in t[:300].lower():
		raise RuntimeError("INPC: la exportacion de la serie %s devolvio HTML (formato inesperado); se conserva el ultimo cache" % serie)
	titulo = ""
	fecha = ""
	out = []
	for line in t.splitlines():
		cells = [c.strip().strip('"') for c in line.split('","')]
		cells = [c.strip('"') for c in cells]
		if len(cells) >= 2 and cells[0] == "Título":
			titulo = cells[1]
		fm = re.search(r"Fecha de consulta:\s*([0-9/]+\s+[0-9:]+)", line)
		if fm:
			fecha = fm.group(1)
		mm = re.match(r"^([A-Z][a-z][a-z])\s+(\d{4})$", cells[0]) if cells else None
		if mm and len(cells) >= 2 and mm.group(1) in _MESES:
			v = _clean_num(cells[1])
			if v != "":
				out.append((int(mm.group(2)), _MESES[mm.group(1)], v))
	if not out:
		raise RuntimeError("INPC: la serie %s no trae observaciones (formato inesperado); se conserva el ultimo cache" % serie)
	out.sort()
	tmp = csv_path + ".tmp"
	with open(tmp, "w", encoding="utf-8") as f:
		f.write("anio,mes,valor\n")
		for a, m, v in out:
			f.write("%d,%d,%s\n" % (a, m, v))
	os.replace(tmp, csv_path)
	ultimo = "%d/%02d" % (out[-1][0], out[-1][1])
	with open(meta_path, "w", encoding="utf-8") as f:
		f.write("titulo=%s\nfecha_consulta=%s\nserie=%s\nestructura=%s\nultimo=%s\nn=%d\nurl=%s\n" % (titulo, fecha, serie, estructura, ultimo, len(out), url))
	Macro.setGlobal("NLBIE_titulo", titulo)
	Macro.setGlobal("NLBIE_fecha", fecha)
	Macro.setGlobal("NLBIE_ultimo", ultimo)
	Macro.setGlobal("NLBIE_n", str(len(out)))