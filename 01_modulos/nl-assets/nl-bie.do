*! nl-bie.do  v1.1.0 — acceso a series INEGI por área geográfica para la capa NL (NL-0.2.0; v1.1.0 NL-0.6.0: candado $nlfuentes, lee nl-fuentes-<fecha>.zip sin descargar)
*
* POR QUÉ EXISTE (DIAGNOSTICO_NL.md, anexo PIBDeflactorNL §0.2):
*   El BIE (versión 2025) exporta cada INDICADOR con las 33 áreas geográficas
*   apiladas en una columna "Área geográfica"; los IDs clásicos por estado ya no
*   responden y la API oficial contesta 401 con el token vigente. AccesoBIE.ado
*   (motor) lee periodo/valor sin mirar el área, así que para una serie estatal
*   mezclaría los 33 estados. El motor no se toca: esta capa define sus propios
*   lectores, con la MISMA vía pública (exportacion.aspx) y el MISMO directorio
*   de caché (raw/temp/AccesoBIE/, prefijo nl_). Propuesta a master por PR
*   aparte: opción area() en AccesoBIE.
*
*   El INPC por entidad federativa NO está en el BIE (su árbol INPC solo trae
*   indicadores nacionales); vive en el programa INPC de INEGI
*   (app/indicesdeprecios, exportación CSV por POST). _NLinpc lo lee de ahí.
*
* COMANDOS (definidos al correr este archivo con `run`):
*   _NLbie <indicador>, AREa(cc) NOMbre(var) [OFFline]
*       cc = clave de 2 dígitos del área (00 nacional, 19 Nuevo León).
*       Cachea la TABLA COMPLETA del indicador (33 áreas, sello de revisión por
*       observación) una vez por sesión y filtra el área al consumir: el
*       comparativo nacional sale del mismo pull. Deja en memoria:
*       anio [trimestre|mes] <var> sello<var>; r(titulo) r(fecha) r(n) r(ultimo)
*       r(sello) r(cache) r(checksum) [checksum = tabla completa].
*   _NLinpc <serie>, ESTructura(id) NOMbre(var) [OFFline]
*       Deja en memoria: anio mes <var> (mensual); mismos r().
*   offline: usa la caché si existe en lugar de descargar (desarrollo).
*   global nlfuentes "AAAA-MM-DD" (NL-0.6.0, nl-fuentes.do): los dos comandos leen
*       el estado empacado en nl-assets/nl-fuentes-<fecha>.zip y NUNCA descargan;
*       vacío = comportamiento idéntico al anterior.
*
* PROCEDENCIA: cada descarga guarda <cache>.csv y <cache>.meta (título, fecha
* de consulta INEGI, último periodo) en raw/temp/AccesoBIE/; el driver registra
* checksum y vintage en su log y en el JSON.

capture python which sys
if _rc {
	di as err "nl-bie: Stata no puede inicializar Python (python query). Sin Python no hay descarga INEGI."
	exit 7100
}

* Las funciones Python viven en nl_bie.py (mismo directorio): el codigo Python
* definido en un do-file no es visible desde programas; se importa como modulo. *

* Candado de fuentes propias de la capa (_NLfuentes, NL-0.6.0) *
SIMroot
run "${SIMROOT}/01_modulos/nl-assets/nl-fuentes.do"


* Lee <cache>.meta (clave=valor) a locals nl_* *
capture program drop _NLmeta
program define _NLmeta
	args meta
	tempname mh
	file open `mh' using `"`meta'"', read text
	file read `mh' line
	while r(eof) == 0 {
		local k = substr(`"`line'"', 1, strpos(`"`line'"', "=") - 1)
		local v = substr(`"`line'"', strpos(`"`line'"', "=") + 1, .)
		if inlist("`k'", "titulo", "fecha_consulta", "area", "areas", "ultimo", "n") {
			c_local nl_`=cond("`k'"=="fecha_consulta","fecha","`k'")' `"`v'"'
		}
		file read `mh' line
	}
	file close `mh'
end


capture program drop _NLbie
program define _NLbie, rclass
	syntax anything(name=indicador) , AREa(string) NOMbre(name) [OFFline]
	SIMroot
	capture mkdir "${SIMROOT}/raw"
	capture mkdir "${SIMROOT}/raw/temp"
	capture mkdir "${SIMROOT}/raw/temp/AccesoBIE"
	* Caché = TABLA COMPLETA del indicador (33 áreas, con sello de revisión por
	* observación). Se descarga UNA vez por sesión; cada área la filtra al consumir. *
	local csv `"${SIMROOT}/raw/temp/AccesoBIE/nl_`indicador'.csv"'
	local meta `"${SIMROOT}/raw/temp/AccesoBIE/nl_`indicador'.meta"'
	local descargar = 1
	capture confirm file `"`csv'"'
	if _rc == 0 & ("`offline'" != "" | "${NLBIE_SESION_`indicador'}" == "1") local descargar = 0
	_NLfuentes
	if r(congelado) {
		capture confirm file `"`csv'"'
		if _rc {
			di as err "nl-bie: nl-fuentes-${nlfuentes}.zip no trae nl_`indicador'.csv; con fuentes congeladas no se descarga."
			exit 601
		}
		local descargar = 0
	}
	if `descargar' {
		python: import sys, importlib; sys.path.insert(0, r"""${SIMROOT}/01_modulos/nl-assets"""); import nl_bie; _r = importlib.reload(nl_bie); nl_bie.nlbie_fetch("`indicador'", r"""`csv'""", r"""`meta'""")
		global NLBIE_SESION_`indicador' "1"
		foreach k in titulo fecha n {
			local nl_`k' `"${NLBIE_`k'}"'
			global NLBIE_`k'
		}
		noisily di as text "  nl-bie: " as result "`indicador'" as text " tabla completa (`nl_n' filas, consulta INEGI `nl_fecha') | `nl_titulo'"
	}
	else {
		_NLmeta `"`meta'"'
	}
	quietly {
		checksum `"`csv'"'
		local chk = r(checksum)
		import delimited `"`csv'"', clear varnames(1) encoding(utf-8) stringcols(1 2 4)
		keep if area == "`area'"
		count
		if r(N) == 0 {
			noisily di as err "nl-bie: el indicador `indicador' no trae filas para el área `area'."
			exit 459
		}
		rename valor `nombre'
		rename nota sello`nombre'
		replace sello`nombre' = "" if sello`nombre' == "."
		drop area
		replace periodo = strtrim(periodo)
		split periodo, destring p("/")
		rename periodo1 anio
		capture confirm variable periodo2
		if _rc == 0 {
			summarize periodo2, meanonly
			if r(max) == 12 rename periodo2 mes
			else if r(max) == 4 rename periodo2 trimestre
			else rename periodo2 subperiodo
		}
		drop periodo
		order anio
		sort anio
		local ultobs = _N
		forvalues i = `=_N'(-1)1 {
			if `nombre'[`i'] != . {
				local ultobs = `i'
				continue, break
			}
		}
		local ultimo = string(anio[`ultobs'])
		capture confirm variable trimestre
		if _rc == 0 local ultimo = "`ultimo'/" + string(trimestre[`ultobs'], "%02.0f")
		capture confirm variable mes
		if _rc == 0 local ultimo = "`ultimo'/" + string(mes[`ultobs'], "%02.0f")
		local sello = sello`nombre'[`ultobs']
	}
	noisily di as text "          área " as result "`area'" as text " -> `nombre': último `ultimo'" as result " `sello'" as text " · checksum tabla `chk'"
	return local titulo `"`nl_titulo'"'
	return local fecha `"`nl_fecha'"'
	return local area "`area'"
	return local ultimo "`ultimo'"
	return local sello "`sello'"
	return local cache `"`csv'"'
	return scalar n = `nl_n'
	return scalar checksum = `chk'
end


capture program drop _NLinpc
program define _NLinpc, rclass
	syntax anything(name=serie) , ESTructura(string) NOMbre(name) [OFFline]
	SIMroot
	capture mkdir "${SIMROOT}/raw"
	capture mkdir "${SIMROOT}/raw/temp"
	capture mkdir "${SIMROOT}/raw/temp/AccesoBIE"
	local csv `"${SIMROOT}/raw/temp/AccesoBIE/nl_inpc_`serie'.csv"'
	local meta `"${SIMROOT}/raw/temp/AccesoBIE/nl_inpc_`serie'.meta"'
	local usecache = 0
	if "`offline'" != "" {
		capture confirm file `"`csv'"'
		if _rc == 0 local usecache = 1
	}
	_NLfuentes
	if r(congelado) {
		capture confirm file `"`csv'"'
		if _rc {
			di as err "nl-inpc: nl-fuentes-${nlfuentes}.zip no trae nl_inpc_`serie'.csv; con fuentes congeladas no se descarga."
			exit 601
		}
		local usecache = 1
	}
	if `usecache' {
		_NLmeta `"`meta'"'
		noisily di as text "  nl-inpc (caché): " as result "`serie'" as text " | `nl_titulo'"
	}
	else {
		python: import sys, importlib; sys.path.insert(0, r"""${SIMROOT}/01_modulos/nl-assets"""); import nl_bie; _r = importlib.reload(nl_bie); nl_bie.nlinpc_fetch("`serie'", "`estructura'", r"""`csv'""", r"""`meta'""")
		foreach k in titulo fecha ultimo n {
			local nl_`k' `"${NLBIE_`k'}"'
			global NLBIE_`k'
		}
		noisily di as text "  nl-inpc: " as result "`serie'" as text " | `nl_titulo'"
		noisily di as text "           consulta INEGI `nl_fecha' · `nl_n' obs · último `nl_ultimo'"
	}
	quietly {
		import delimited `"`csv'"', clear varnames(1) encoding(utf-8)
		rename valor `nombre'
		order anio mes
		checksum `"`csv'"'
		local chk = r(checksum)
	}
	return local titulo `"`nl_titulo'"'
	return local fecha `"`nl_fecha'"'
	return local ultimo `"`nl_ultimo'"'
	return local cache `"`csv'"'
	return scalar n = `nl_n'
	return scalar checksum = `chk'
end
