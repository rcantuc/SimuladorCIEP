"""nl_fed.py - lectores de la capa NL para el endpoint Federacion<->NL (NL-0.4.0).

Modulo Python importado desde 01_modulos/nl-assets/nl-fed.do. Tres familias:
  1. eopf_fetch: Estadisticas Oportunas de Finanzas Publicas (SHCP, datos
     abiertos) -> transferencias a entidades federativas y municipios por fondo
     y entidad, mensual. Patron _NLbie: se baja la tabla COMPLETA (32 entidades
     + "No distribuible" + total) de los dos ZIP (vigente + historico), se
     filtra por una LISTA EXPLICITA de fondos (nunca por substring: XAC4219 es
     "Ramo Bienestar", no Nuevo Leon), se cachea en CSV ligero con .meta
     (Last-Modified de cada ZIP, periodo final, n, URL) y escritura atomica:
     un formato inesperado aborta y conserva el ultimo cache bueno.
  2. json_get / json_arr: lectura de JSON del canal (statajson_entidad-nl.json,
     actividad-nl.json, poblacion-nl.json, federacion-sello.json) hacia
     globals de Stata o CSV temporales; Stata no parsea JSON nativamente.
  3. sha256: huella de archivos para la procedencia y el sello de corrida.
Las funciones publican metadatos en globals NLFED_* que el .do lee y limpia.
"""
import csv, hashlib, io, json, os, re, ssl, time, zipfile
import urllib.request
from sfi import Macro

_UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0 Safari/537.36"
_CTX = ssl.create_default_context()
try:
	_CTX.load_default_certs()
except Exception:
	pass

_EOPF = "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/"
_ZIPS = ("transferencias_entidades_fed.zip", "transferencias_entidades_fed_hist.zip")


def _get(url, tries=3):
	last = None
	for i in range(tries):
		try:
			req = urllib.request.Request(url, headers={"User-Agent": _UA})
			try:
				r = urllib.request.urlopen(req, timeout=300, context=_CTX)
			except ssl.SSLError:
				ctx = ssl.create_default_context()
				ctx.check_hostname = False
				ctx.verify_mode = ssl.CERT_NONE
				r = urllib.request.urlopen(req, timeout=300, context=ctx)
			return r.read(), r.headers.get("Last-Modified", "")
		except Exception as e:
			last = e
			time.sleep(3)
	raise last


def _num(s):
	s = (s or "").replace(",", "").strip()
	if s in ("", "ND", "N/E", "-", "N/D"):
		return None
	try:
		return float(s)
	except Exception:
		return None


def eopf_fetch(fondos, csv_path, meta_path):
	"""fondos: lista separada por espacios de prefijos de clave (p. ej. XAC28 XAC28A ...
	XAC33 XACCD XACCR XAC23 XACPSS XACGF). Se aceptan las claves <prefijo><ent> con
	ent = 00..33 exactamente (00 total, 01-32 entidades, 33 no distribuible)."""
	pref = tuple(p.strip() for p in fondos.split() if p.strip())
	rx = re.compile(r"^(" + "|".join(re.escape(p) for p in pref) + r")(\d\d)$")
	meses = {"Enero": 1, "Febrero": 2, "Marzo": 3, "Abril": 4, "Mayo": 5, "Junio": 6, "Julio": 7,
		"Agosto": 8, "Septiembre": 9, "Octubre": 10, "Noviembre": 11, "Diciembre": 12}
	out = {}
	nombres = {}
	lastmods = []
	periodo_final = ""
	nraw = 0
	for z in _ZIPS:
		raw, lm = _get(_EOPF + z)
		lastmods.append("%s=%s" % (z, lm))
		try:
			zf = zipfile.ZipFile(io.BytesIO(raw))
		except zipfile.BadZipFile:
			raise RuntimeError("EOPF: %s no es un ZIP (formato inesperado); se conserva el ultimo cache" % z)
		names = [n for n in zf.namelist() if n.lower().endswith(".csv")]
		if len(names) != 1:
			raise RuntimeError("EOPF: %s no trae exactamente un CSV (formato inesperado); se conserva el ultimo cache" % z)
		data = zf.read(names[0])
		try:
			txt = data.decode("utf-8")
		except UnicodeDecodeError:
			txt = data.decode("windows-1252", "replace")
		rd = csv.DictReader(io.StringIO(txt))
		need = {"CICLO", "MES", "CLAVE_DE_CONCEPTO", "NOMBRE", "UNIDAD_DE_MEDIDA", "MONTO", "PERIODO_FINAL", "BASE_DE_REGISTRO"}
		if not need.issubset(set(rd.fieldnames or [])):
			raise RuntimeError("EOPF: %s sin las columnas esperadas %s (formato inesperado); se conserva el ultimo cache" % (z, sorted(need - set(rd.fieldnames or []))))
		for row in rd:
			nraw += 1
			m = rx.match(row["CLAVE_DE_CONCEPTO"].strip())
			if not m:
				continue
			fondo, ent = m.group(1), m.group(2)
			try:
				anio = int(row["CICLO"])
			except Exception:
				continue
			mes = meses.get(row["MES"].strip())
			if mes is None:
				continue
			v = _num(row["MONTO"])
			if v is None:
				continue
			u = row["UNIDAD_DE_MEDIDA"].strip()
			if u.startswith("Miles"):
				v *= 1000.0
			elif u != "Pesos":
				raise RuntimeError("EOPF: unidad inesperada '%s' en %s; se conserva el ultimo cache" % (u, row["CLAVE_DE_CONCEPTO"]))
			if row["BASE_DE_REGISTRO"].strip() not in ("Pagado", ""):
				raise RuntimeError("EOPF: base de registro inesperada '%s'; se conserva el ultimo cache" % row["BASE_DE_REGISTRO"])
			key = (anio, mes, fondo, ent)
			# El historico y el vigente pueden traslaparse: gana el vigente (primer ZIP). *
			if key not in out:
				out[key] = v
			if ent == "00" and fondo not in nombres:
				nombres[fondo] = re.sub(r"^Total:\s*", "", row["NOMBRE"].strip())
			pf = row["PERIODO_FINAL"].strip()
			if pf > periodo_final:
				periodo_final = pf
	if not out:
		raise RuntimeError("EOPF: ninguna fila coincide con los fondos pedidos (formato inesperado); se conserva el ultimo cache")
	faltan = [p for p in pref if p not in nombres]
	if faltan:
		raise RuntimeError("EOPF: fondos sin fila nacional '00': %s; se conserva el ultimo cache" % faltan)
	tmp = csv_path + ".tmp"
	with open(tmp, "w", encoding="utf-8", newline="") as f:
		f.write("anio,mes,fondo,ent,monto\n")
		for (a, m, fo, e) in sorted(out):
			f.write("%d,%d,%s,%s,%.3f\n" % (a, m, fo, e, out[(a, m, fo, e)]))
	os.replace(tmp, csv_path)
	fpath = csv_path[:-4] + "_fondos.csv"
	with open(fpath + ".tmp", "w", encoding="utf-8", newline="") as f:
		w = csv.writer(f)
		w.writerow(["fondo", "nombre"])
		for fo in pref:
			w.writerow([fo, nombres[fo]])
	os.replace(fpath + ".tmp", fpath)
	fecha = time.strftime("%Y-%m-%d %H:%M:%S")
	with open(meta_path + ".tmp", "w", encoding="utf-8") as f:
		f.write("fecha_descarga=%s\nlast_modified=%s\nperiodo_final=%s\nn=%d\nn_raw=%d\nfondos=%s\nurl=%s\n"
			% (fecha, ";".join(lastmods), periodo_final, len(out), nraw, " ".join(pref), _EOPF))
	os.replace(meta_path + ".tmp", meta_path)
	Macro.setGlobal("NLFED_fecha", fecha)
	Macro.setGlobal("NLFED_lastmod", ";".join(lastmods))
	Macro.setGlobal("NLFED_periodo_final", periodo_final)
	Macro.setGlobal("NLFED_n", str(len(out)))


def _walk(obj, path):
	cur = obj
	for p in path.split("."):
		if p == "":
			continue
		if isinstance(cur, list):
			cur = cur[int(p)]
		else:
			cur = cur[p]
	return cur


def json_get(path, keys):
	"""keys: lista separada por espacios de rutas con punto (p. ej. procedencia.generado_en).
	Publica NLFED_v<k> (texto; numeros con repr completa) y NLFED_ok<k> (1/0)."""
	with open(path, encoding="utf-8") as f:
		j = json.load(f)
	for k, key in enumerate(keys.split(), start=1):
		try:
			v = _walk(j, key)
			ok = "1"
		except Exception:
			v, ok = "", "0"
		if isinstance(v, bool):
			v = "1" if v else "0"
		elif isinstance(v, (int, float)):
			v = repr(v)
		elif v is None:
			v = ""
		elif not isinstance(v, str):
			v = json.dumps(v, ensure_ascii=False)
		Macro.setGlobal("NLFED_v%d" % k, str(v))
		Macro.setGlobal("NLFED_ok%d" % k, ok)


def json_arr(path, arr_key, fields, out_csv):
	"""Vuelca el arreglo de objetos en <arr_key> (ruta con punto) a CSV con las columnas
	<fields> (separadas por espacios; las ausentes van vacias)."""
	with open(path, encoding="utf-8") as f:
		j = json.load(f)
	arr = _walk(j, arr_key)
	if not isinstance(arr, list):
		raise RuntimeError("json_arr: %s no es un arreglo en %s" % (arr_key, path))
	cols = fields.split()
	with open(out_csv, "w", encoding="utf-8", newline="") as f:
		w = csv.writer(f)
		w.writerow(cols)
		for o in arr:
			row = []
			for c in cols:
				v = o.get(c, "") if isinstance(o, dict) else ""
				if isinstance(v, bool):
					v = 1 if v else 0
				elif isinstance(v, float):
					v = repr(v)
				elif v is None:
					v = ""
				row.append(v)
			w.writerow(row)
	Macro.setGlobal("NLFED_n", str(len(arr)))


def json_escalares(path, out_csv, prefijos):
	"""Escalares del contrato scalarjson (dict nombre -> {valor, tipo}) cuyo nombre empieza
	por alguno de <prefijos> (espacios) -> CSV nombre,tipo,valor."""
	with open(path, encoding="utf-8") as f:
		j = json.load(f)
	esc = j.get("escalares", {})
	pref = tuple(prefijos.split())
	n = 0
	with open(out_csv, "w", encoding="utf-8", newline="") as f:
		w = csv.writer(f)
		w.writerow(["nombre", "tipo", "valor"])
		for k in sorted(esc):
			if k.startswith(pref):
				e = esc[k]
				w.writerow([k, e.get("tipo", ""), repr(e.get("valor"))])
				n += 1
	Macro.setGlobal("NLFED_n", str(n))


def fileinfo(path):
	"""Vintage de un archivo del canal (caché .dta del motor): fecha de modificación ISO y bytes."""
	st = os.stat(path)
	Macro.setGlobal("NLFED_mtime", time.strftime("%Y-%m-%dT%H:%M:%S", time.localtime(st.st_mtime)))
	Macro.setGlobal("NLFED_bytes", str(st.st_size))


def sha256(path):
	h = hashlib.sha256()
	with open(path, "rb") as f:
		for chunk in iter(lambda: f.read(1 << 20), b""):
			h.update(chunk)
	Macro.setGlobal("NLFED_sha", h.hexdigest())
	Macro.setGlobal("NLFED_bytes", str(os.path.getsize(path)))
