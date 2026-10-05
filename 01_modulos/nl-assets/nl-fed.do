*! nl-fed.do  v1.0.0 — lectores de la capa NL para el endpoint Federación↔NL (NL-0.4.0)
*
* POR QUÉ EXISTE (DIAGNOSTICO_NL.md, anexo Federación↔NL §0.1):
*   El motor ya ingiere las transferencias SHCP por fondo × entidad en
*   master/DatosAbiertos.dta, pero ese caché (a) duplica la clave XACGF00 con
*   una fila derivada (XAC2800+XAC3300) y (b) rompe la costura _hist/vigente en
*   2011, mientras el CSV fresco de SHCP cuadra a 1e-9. El motor no se toca
*   desde esta rama (issue documentado para master): la capa lee la fuente con
*   su propio lector, misma vía pública, patrón _NLbie (tabla completa, filtro
*   al consumir, vintage + checksum, escritura atómica, fallo seguro).
*
* COMANDOS (definidos al correr este archivo con `run`):
*   _NLeopf, FONdos(lista) [OFFline]
*       Descarga los dos ZIP de Estadísticas Oportunas (vigente + histórico),
*       conserva solo las claves <fondo><ent> de la lista (ent 00..33) y deja
*       en memoria: anio mes fondo ent monto (pesos). r(fecha) r(lastmod)
*       r(periodo_final) r(n) r(checksum) r(cache) r(fondos) [CSV fondo,nombre].
*   _NLjsonget using <json>, KEYs(rutas)      -> r(v1) r(ok1) r(v2) ...
*   _NLjsonarr using <json>, ARRay(ruta) FIElds(lista) -> datos en memoria
*   _NLjsonesc using <json>, PREfijos(lista)  -> nombre tipo valor en memoria
*   _NLsha256 <archivo>                       -> r(sha256) r(bytes)
*   _NLfileinfo <archivo>                     -> r(mtime) r(bytes)  [vintage de cachés .dta]
*   offline: usa la caché si existe en lugar de descargar (desarrollo).

capture python which sys
if _rc {
	di as err "nl-fed: Stata no puede inicializar Python (python query). Sin Python no hay lectura de SHCP ni de JSON."
	exit 7100
}

capture program drop _NLfedpy
program define _NLfedpy
	* Importa (o recarga) el módulo y ejecuta la llamada que viene como argumento *
	SIMroot
	python: import sys, importlib; sys.path.insert(0, r"""${SIMROOT}/01_modulos/nl-assets"""); import nl_fed; _r = importlib.reload(nl_fed); nl_fed.`0'
end

capture program drop _NLfedmeta
program define _NLfedmeta
	args meta
	tempname mh
	file open `mh' using `"`meta'"', read text
	file read `mh' line
	while r(eof) == 0 {
		local k = substr(`"`line'"', 1, strpos(`"`line'"', "=") - 1)
		local v = substr(`"`line'"', strpos(`"`line'"', "=") + 1, .)
		if inlist("`k'", "fecha_descarga", "last_modified", "periodo_final", "n") {
			c_local nl_`k' `"`v'"'
		}
		file read `mh' line
	}
	file close `mh'
end

capture program drop _NLeopf
program define _NLeopf, rclass
	syntax , FONdos(string) [OFFline]
	SIMroot
	capture mkdir "${SIMROOT}/raw"
	capture mkdir "${SIMROOT}/raw/temp"
	capture mkdir "${SIMROOT}/raw/temp/EOPF"
	local csv `"${SIMROOT}/raw/temp/EOPF/nl_transferencias.csv"'
	local meta `"${SIMROOT}/raw/temp/EOPF/nl_transferencias.meta"'
	local descargar = 1
	capture confirm file `"`csv'"'
	if _rc == 0 & ("`offline'" != "" | "${NLEOPF_SESION}" == "1") local descargar = 0
	if `descargar' {
		noisily di as text "  nl-fed: descargando Estadísticas Oportunas (transferencias a entidades, vigente + histórico)..."
		_NLfedpy eopf_fetch("`fondos'", r"""`csv'""", r"""`meta'""")
		global NLEOPF_SESION "1"
		local nl_fecha_descarga `"${NLFED_fecha}"'
		local nl_last_modified `"${NLFED_lastmod}"'
		local nl_periodo_final `"${NLFED_periodo_final}"'
		local nl_n `"${NLFED_n}"'
		foreach g in fecha lastmod periodo_final n {
			global NLFED_`g'
		}
		noisily di as text "  nl-fed: EOPF tabla completa (`nl_n' filas útiles, periodo final `nl_periodo_final', descarga `nl_fecha_descarga')"
	}
	else {
		_NLfedmeta `"`meta'"'
		noisily di as text "  nl-fed (caché): EOPF `nl_n' filas, periodo final `nl_periodo_final', descarga `nl_fecha_descarga'"
	}
	quietly {
		checksum `"`csv'"'
		local chk = r(checksum)
		import delimited `"`csv'"', clear varnames(1) encoding(utf-8) stringcols(3 4)
		count
		if r(N) == 0 {
			noisily di as err "nl-fed: la caché EOPF está vacía."
			exit 459
		}
	}
	return local fecha `"`nl_fecha_descarga'"'
	return local lastmod `"`nl_last_modified'"'
	return local periodo_final `"`nl_periodo_final'"'
	return local cache `"`csv'"'
	return local fondos `"`=substr(`"`csv'"', 1, strlen(`"`csv'"') - 4)'_fondos.csv"'
	return scalar n = `nl_n'
	return scalar checksum = `chk'
end

capture program drop _NLjsonget
program define _NLjsonget, rclass
	syntax using/, KEYs(string)
	_NLfedpy json_get(r"""`using'""", "`keys'")
	local k = 0
	foreach key of local keys {
		local ++k
		return local v`k' `"${NLFED_v`k'}"'
		return local ok`k' "${NLFED_ok`k'}"
		global NLFED_v`k'
		global NLFED_ok`k'
	}
end

capture program drop _NLjsonarr
program define _NLjsonarr, rclass
	syntax using/, ARRay(string) FIElds(string)
	tempfile csv
	_NLfedpy json_arr(r"""`using'""", "`array'", "`fields'", r"""`csv'""")
	quietly import delimited `"`csv'"', clear varnames(1) encoding(utf-8) case(preserve)
	return scalar n = ${NLFED_n}
	global NLFED_n
end

capture program drop _NLjsonesc
program define _NLjsonesc, rclass
	syntax using/, PREfijos(string)
	tempfile csv
	_NLfedpy json_escalares(r"""`using'""", r"""`csv'""", "`prefijos'")
	quietly import delimited `"`csv'"', clear varnames(1) encoding(utf-8) stringcols(1 2) case(preserve)
	return scalar n = ${NLFED_n}
	global NLFED_n
end

capture program drop _NLfileinfo
program define _NLfileinfo, rclass
	args archivo
	_NLfedpy fileinfo(r"""`archivo'""")
	return local mtime "${NLFED_mtime}"
	return scalar bytes = ${NLFED_bytes}
	global NLFED_mtime
	global NLFED_bytes
end

capture program drop _NLsha256
program define _NLsha256, rclass
	args archivo
	_NLfedpy sha256(r"""`archivo'""")
	return local sha256 "${NLFED_sha}"
	return scalar bytes = ${NLFED_bytes}
	global NLFED_sha
	global NLFED_bytes
end
