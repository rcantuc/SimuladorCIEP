*! PoblacionNL.do  v1.0.0 — endpoint de Población: Simulador Fiscal NL (F2, capa NL-0.1.0)
*
* QUÉ ES ESTO
*   Un comando -> un HTML autocontenido. Lee la población del MOTOR (sin
*   modificarlo), la prepara para Nuevo León, exporta un JSON de datos y lo
*   incrusta en una plantilla HTML (CSS/JS/SVG inline, cero red) que un colega
*   de Consejo Nuevo León abre desde Drive sin saber que Stata existe.
*
* FUENTES (las dos del canal; cero números a mano)
*   (a) master/Poblacion.dta — Poblacion.ado del motor (CONAPO pry23 vía
*       DGIS-Salud, asset del sidecar): edad simple 0-109 x sexo x año, para
*       "Nuevo León" y "Nacional". El rango de años se LEE de la base.
*   (b) 01_modulos/nl-assets/pobproy_quinq1.csv — CONAPO, Reconstrucción y
*       proyecciones de la población de los municipios de México 1990-2040
*       (2024): grupos quinquenales x sexo x municipio x año. Asset de la CAPA
*       NL (versionado aquí, no en el manifest del motor), con checksum
*       declarado en nl-assets/nl-manifest.json y verificado en cada corrida.
*       Compuerta: la suma de los 51 municipios debe igualar la serie estatal
*       del motor en los años comunes (mismo vintage demográfico).
*
* CIFRAS DEL CANAL
*   Los escalares pob*NL y pob*Nacional los registra el propio Poblacion.ado
*   (23 por entidad) al invocarlo aquí para NL y nacional; la capa NL añade
*   razdepNL/razdepNacional (razón de dependencia (0-14 + 65+)/(15-64) x 100,
*   la definición alineada a los quinquenios municipales; la gráfica del motor
*   usa 0-18/61+ sobre 19-60, se declara la diferencia). El HTML muestra las
*   cifras del año de referencia tal cual vienen del JSON y verifica que su
*   propia suma de los arreglos coincide con ellas (autocomprobación).
*
* SALIDAS (generadas, gitignored): users/$id/nodos/poblacion-nl.json,
*   users/$id/nodos/poblacion-nl.html, users/$id/nodos/poblacion-nl.log.
*   publicar-conl.sh las lleva al Drive de CoNL.
*
* USO (con o sin SIM.do en la sesión; no depende de la corrida fiscal):
*   do "${SIMROOT}/01_modulos/PoblacionNL.do"
* OJO: destruye los datos en memoria.

*** 0 RAÍZ, LOG (procedencia), IDENTIDAD ***
SIMroot
local site `"${SIMROOT}"'
if "$id" == "" global id = "`c(username)'"
capture mkdir `"`site'/users"'
capture mkdir `"`site'/users/$id"'
capture mkdir `"`site'/users/$id/nodos"'
local q = char(34)

* Año de referencia: aniovp (profile.do / SIM.do) o el año en curso *
capture confirm scalar aniovp
if _rc == 0 {
	local anioref = scalar(aniovp)
}
else {
	local anioref = year(date("$S_DATE", "DMY"))
}

* Procedencia: log PROPIO y con nombre (coexiste con el log de batch o con el de
* otro driver de la capa); se cierra al final. Sin él no hay exportación válida. *
capture log close nlpob
quietly log using `"`site'/users/$id/nodos/poblacion-nl.log"', replace text name(nlpob)
capture quietly log query nlpob
if `"`r(filename)'"' == "" {
	di as err "PoblacionNL: no pudo abrirse el log de procedencia; sin procedencia no hay exportación válida."
	exit 459
}
local logfile "poblacion-nl.log"

run `"`site'/01_modulos/nl-assets/nl-identidad.do"'
_NLidentidad, modulo("Población")
local nl_producto `"`r(producto)'"'
local nl_titulo `"`r(titulo)'"'
local nl_subtitulo `"`r(subtitulo)'"'
local nl_vmotor `"`r(version_motor)'"'
local nl_vnl `"`r(version_nl)'"'

* Checksum declarado del asset municipal (nl-manifest.json) *
local chk_decl ""
local len_decl ""
tempname nh
file open `nh' using `"`site'/01_modulos/nl-assets/nl-manifest.json"', read text
file read `nh' line
while r(eof) == 0 {
	if regexm(`"`line'"', `"`q'checksum_stata`q'[ ]*:[ ]*([0-9]+)"') & "`chk_decl'" == "" local chk_decl = regexs(1)
	if regexm(`"`line'"', `"`q'filelen`q'[ ]*:[ ]*([0-9]+)"') & "`len_decl'" == "" local len_decl = regexs(1)
	file read `nh' line
}
file close `nh'

*** 1 MATA: escritores del JSON y del HTML ***
capture mata: mata drop nlpob_*()
mata:
void nlpob_rows(real scalar fh, string scalar key, real matrix X, real scalar coma)
{
	real scalar i
	fput(fh, sprintf(`"      "%s": ["', key))
	for (i = 1; i <= rows(X); i++) {
		fput(fh, "        [" + invtokens(strtrim(strofreal(X[i, .], "%15.0f")), ",") + "]" + (i < rows(X) ? "," : ""))
	}
	fput(fh, "      ]" + (coma ? "," : ""))
}
void nlpob_geo(string scalar fn, string scalar key, string scalar nombre, string scalar tipo,
	string scalar cve, string scalar eje, real colvector anios, real matrix H, real matrix M, real scalar coma)
{
	real scalar fh
	fh = fopen(fn, "a")
	fput(fh, sprintf(`"    "%s": {"', key))
	fput(fh, sprintf(`"      "nombre": "%s", "tipo": "%s", "cve": %s, "eje": "%s","', nombre, tipo, cve, eje))
	fput(fh, `"      "anios": ["' + invtokens(strtrim(strofreal(anios', "%12.0f")), ",") + "],")
	nlpob_rows(fh, "h", H, 1)
	nlpob_rows(fh, "m", M, 0)
	fput(fh, "    }" + (coma ? "," : ""))
	fclose(fh)
}
void nlpob_inject(string scalar tpl, string scalar json, string scalar out, string scalar marca)
{
	real scalar fi, fo, fj, hits
	string scalar line, l2
	fi = fopen(tpl, "r")
	unlink(out)								// fopen(,"w") no pisa archivos: se regenera siempre
	fo = fopen(out, "w")
	hits = 0
	while ((line = fget(fi)) != J(0, 0, "")) {
		if (strtrim(line) == marca) {
			hits++
			fj = fopen(json, "r")
			while ((l2 = fget(fj)) != J(0, 0, "")) fput(fo, l2)
			fclose(fj)
		}
		else fput(fo, line)
	}
	fclose(fi)
	fclose(fo)
	st_numscalar("r(hits)", hits)
}
end

* Número a JSON con precisión completa (espejo de _sjnum de scalarjson.ado) *
capture program drop _nlnum
program define _nlnum, rclass
	args e
	return local n "null"
	capture local ismiss = (`e' >= .)
	if _rc exit
	if `ismiss' exit
	local s = trim(string(`e', "%25.17g"))
	if substr("`s'", 1, 1) == "."  local s = "0`s'"
	if substr("`s'", 1, 2) == "-." local s = "-0" + substr("`s'", 2, .)
	return local n "`s'"
end

*** 2 BASE ESTATAL Y NACIONAL (motor) ***
capture confirm file `"`site'/master/Poblacion.dta"'
if _rc {
	noisily di in g "PoblacionNL: master/Poblacion.dta no existe; la construye el motor (Poblacion.ado -> UpdatePoblacion)."
	quietly Poblacion, nographs anioinicial(`anioref') aniofinal(2070)
}

** 2.1 Escalares del motor (23 por entidad): el canal, no esta capa **
noisily Poblacion if entidad == "Nuevo León", anioinicial(`anioref') aniofinal(2070) nographs
noisily Poblacion, anioinicial(`anioref') aniofinal(2070) nographs

* Sufijo con el que Poblacion.ado nombró sus escalares: misma regla que el
* motor (abreviatura de $entidadesC si profile.do cargó las globales — NL/Nac —
* o strtoname del nombre completo si no). Los escalares de ESTA capa usan
* siempre NL / Nac. *
foreach g in NL Nac {
	local nombre = cond("`g'" == "NL", "Nuevo León", "Nacional")
	local gname "`nombre'"
	tokenize $entidadesC
	local j = 1
	foreach k of global entidadesL {
		if "`gname'" == "`k'" {
			local gname = "``j''"
			continue, break
		}
		local ++j
	}
	local suf`g' = strtoname("`gname'")
	capture confirm scalar pobtot`suf`g''
	if _rc {
		di as err "PoblacionNL: Poblacion.ado no registró pobtot`suf`g'' (`nombre'). Sin escalares del motor no hay cifras del canal."
		exit 459
	}
}

** 2.2 Base completa NL + Nacional **
use `"`site'/master/Poblacion.dta"', clear
keep if inlist(entidad, "Nuevo León", "Nacional")
keep anio edad sexo entidad poblacion
isid anio edad sexo entidad
assert poblacion == round(poblacion)
quietly summarize anio
local amin = r(min)
local amax = r(max)
quietly summarize edad
local emin = r(min)
local emax = r(max)
local nanios = `amax' - `amin' + 1
local nedades = `emax' - `emin' + 1
quietly count
assert r(N) == 2*2*`nanios'*`nedades'		// rejilla completa: entidad x sexo x año x edad
assert inrange(`anioref', `amin', `amax')

** 2.3 Cifras del año de referencia (razón de dependencia alineada a quinquenios) **
foreach g in NL Nac {
	local ent = cond("`g'" == "NL", "Nuevo León", "Nacional")
	quietly summarize poblacion if entidad == "`ent'" & anio == `anioref'
	local tot`g' = r(sum)
	quietly summarize poblacion if entidad == "`ent'" & anio == `anioref' & edad <= 14
	local jov = r(sum)
	quietly summarize poblacion if entidad == "`ent'" & anio == `anioref' & edad >= 65
	local may = r(sum)
	quietly summarize poblacion if entidad == "`ent'" & anio == `anioref' & inrange(edad, 15, 64)
	local act = r(sum)
	escalar pct razdep`g' = (`jov' + `may')/`act'*100
	escalar pct pobjovprop`g' = `jov'/`tot`g''*100
	escalar pct pobactprop`g' = `act'/`tot`g''*100
	escalar pct pob65prop`g' = `may'/`tot`g''*100
	* El total debe coincidir con el escalar del motor para el mismo año *
	assert reldif(scalar(pobtot`suf`g''), `tot`g'') < 1e-9
}
escalar pct PartPobCONAPONL = `totNL'/`totNac'*100

** 2.4 Matrices año x edad por entidad y sexo **
sort entidad sexo anio edad
tempvar touse
quietly g byte `touse' = 0
foreach g in nl nac {
	local ent = cond("`g'" == "nl", "Nuevo León", "Nacional")
	forvalues s = 1/2 {
		quietly replace `touse' = (entidad == "`ent'" & sexo == `s')
		mata: X_`g'`s' = colshape(st_data(., "poblacion", "`touse'"), `nedades')
	}
}
mata: anios_e = (`amin'::`amax')

*** 3 BASE MUNICIPAL (asset de la capa NL) ***
local csv `"`site'/01_modulos/nl-assets/pobproy_quinq1.csv"'
quietly checksum `"`csv'"'
if "`r(checksum)'" != "`chk_decl'" | "`r(filelen)'" != "`len_decl'" {
	di as err "PoblacionNL: el asset municipal no coincide con nl-manifest.json (checksum `r(checksum)' vs `chk_decl'; bytes `r(filelen)' vs `len_decl'). No se exporta."
	exit 459
}
noisily di _newline in g "  Asset municipal verificado: " in y "pobproy_quinq1.csv" in g " (checksum `chk_decl', `len_decl' bytes)"

preserve
import delimited `"`csv'"', case(lower) clear encoding("utf-8")
keep if clave_ent == 19
rename ano anio
local grupos pob_00_04 pob_05_09 pob_010_014 pob_015_019 pob_20_24 pob_25_29 pob_30_34 pob_35_39 ///
	pob_40_44 pob_45_49 pob_50_54 pob_55_59 pob_60_64 pob_65_69 pob_70_74 pob_75_79 pob_80_84 pob_85_mm
keep clave nom_mun sexo anio pob_total `grupos'
g byte sx = cond(sexo == "HOMBRES", 1, cond(sexo == "MUJERES", 2, .))
assert sx != .
isid clave sx anio
tempvar suma
egen `suma' = rowtotal(`grupos')
assert `suma' == pob_total
quietly summarize anio
local mmin = r(min)
local mmax = r(max)
local mnanios = `mmax' - `mmin' + 1
quietly levelsof clave, local(claves)
local nmun : word count `claves'
quietly count
assert r(N) == `nmun'*2*`mnanios'
tempfile munic
quietly save `munic'

** 3.1 Compuerta: suma municipal = serie estatal del motor en los años comunes **
collapse (sum) pob_total, by(anio)
tempfile muntot
quietly save `muntot'
restore
preserve
keep if entidad == "Nuevo León"
collapse (sum) poblacion, by(anio)
quietly merge 1:1 anio using `muntot', keep(match) nogen
quietly count
local ncomun = r(N)
quietly count if reldif(poblacion, pob_total) > 1e-12
if r(N) > 0 {
	di as err "PoblacionNL: la suma municipal difiere de la serie estatal en `r(N)' de `ncomun' años. Vintage distinto; no se exporta."
	exit 459
}
noisily di in g "  Compuerta municipal: " in y "PASÓ" in g " (suma de `nmun' municipios = serie estatal del motor en `ncomun' años, `mmin'-`mmax')."
restore

*** 4 JSON DE DATOS ***
local json `"`site'/users/$id/nodos/poblacion-nl.json"'
local sello = subinstr(trim(`"`c(current_date)'"'), " ", "-", .) + "T" + trim(`"`c(current_time)'"')
tempname fh
file open `fh' using `"`json'"', write replace text
file write `fh' "{" _n
file write `fh' `"  `q'esquema`q': `q'nl.poblacion/v1`q',"' _n
file write `fh' `"  `q'producto`q': `q'`nl_producto'`q',"' _n
file write `fh' `"  `q'titulo`q': `q'`nl_titulo'`q',"' _n
file write `fh' `"  `q'subtitulo`q': `q'`nl_subtitulo'`q',"' _n
file write `fh' `"  `q'anio_referencia`q': `anioref',"' _n
file write `fh' `"  `q'procedencia`q': {"' _n
file write `fh' `"    `q'version_motor`q': `q'`nl_vmotor'`q',"' _n
file write `fh' `"    `q'version_capa_nl`q': `q'`nl_vnl'`q',"' _n
file write `fh' `"    `q'driver`q': `q'01_modulos/PoblacionNL.do v1.0.0`q',"' _n
file write `fh' `"    `q'log`q': `q'`logfile'`q',"' _n
file write `fh' `"    `q'fuente_estatal`q': `q'CONAPO, Conciliación Demográfica de México 1970-2019 y Proyecciones de la población de México y de las entidades federativas 2020-2070 (pry23), vía DGIS-Salud; Poblacion.ado del motor, master/Poblacion.dta`q',"' _n
file write `fh' `"    `q'cobertura_estatal`q': `q'`amin'-`amax', edad simple `emin'-`emax', sexo`q',"' _n
file write `fh' `"    `q'fuente_municipal`q': `q'CONAPO, Reconstrucción y proyecciones de la población de los municipios de México 1990-2040 (2024), grupos quinquenales de edad y sexo; 01_modulos/nl-assets/pobproy_quinq1.csv (checksum `chk_decl')`q',"' _n
file write `fh' `"    `q'cobertura_municipal`q': `q'`mmin'-`mmax', `nmun' municipios, 18 grupos quinquenales, sexo`q',"' _n
file write `fh' `"    `q'compuerta_municipal`q': `q'suma de los `nmun' municipios = serie estatal del motor en `ncomun' años comunes (reldif < 1e-12)`q',"' _n
file write `fh' `"    `q'anio_inicio_proyeccion`q': 2020,"' _n
file write `fh' `"    `q'generado_en`q': `q'`sello'`q'"' _n
file write `fh' "  }," _n
file write `fh' `"  `q'definiciones`q': {"' _n
file write `fh' `"    `q'razon_dependencia`q': `q'(población de 0-14 + 65 y más) / (población de 15-64) x 100`q',"' _n
file write `fh' `"    `q'nota_motor`q': `q'La gráfica de dependencia del motor (Poblacion.ado) usa 0-18 y 61+ sobre 19-60; aquí se usa el corte quinquenal estándar para que estado, país y municipios compartan definición.`q',"' _n
file write `fh' `"    `q'sexo`q': {`q'h`q': `q'Hombres`q', `q'm`q': `q'Mujeres`q'},"' _n
file write `fh' `"    `q'unidad`q': `q'personas a mitad de año`q'"' _n
file write `fh' "  }," _n
file write `fh' `"  `q'edades`q': {`q'min`q': `emin', `q'max`q': `emax'},"' _n
file write `fh' `"  `q'grupos_quinquenales`q': [`q'0-4`q',`q'5-9`q',`q'10-14`q',`q'15-19`q',`q'20-24`q',`q'25-29`q',`q'30-34`q',`q'35-39`q',`q'40-44`q',`q'45-49`q',`q'50-54`q',`q'55-59`q',`q'60-64`q',`q'65-69`q',`q'70-74`q',`q'75-79`q',`q'80-84`q',`q'85+`q'],"' _n

** 4.1 Cifras del canal (escalares vivos; nombres del motor y de la capa NL) **
file write `fh' `"  `q'cifras`q': {"' _n
file write `fh' `"    `q'anio`q': `anioref',"' _n
* Claves estables (familia del escalar); el nombre real del escalar del motor
* (con su sufijo) viaja en "escalares" para que la procedencia sea auditable. *
local i = 0
foreach g in NL Nac {
	local ++i
	local key = cond("`g'" == "NL", "nl", "nac")
	file write `fh' `"    `q'`key'`q': {"' _n
	file write `fh' `"      `q'sufijo_escalares_motor`q': `q'`suf`g''`q',"' _n
	local motor pobtot pobhomI pobmujI pobhompropI pobmujpropI pobMenoresI pobMenorespropI ///
		pobPrimeI pobPrimepropI pobMayoresI pobMayorespropI pobfin
	local capa razdep pobjovprop pobactprop pob65prop
	local lista ""
	foreach f of local motor {
		local lista `lista' `f':`f'`suf`g''
	}
	foreach f of local capa {
		local lista `lista' `f':`f'`g'
	}
	if "`g'" == "NL" local lista `lista' PartPob:PartPobCONAPONL
	local n : word count `lista'
	local j = 0
	local nombres ""
	foreach par of local lista {
		local ++j
		tokenize "`par'", parse(":")
		local fam `1'
		local esc `3'
		_nlnum "scalar(`esc')"
		file write `fh' `"      `q'`fam'`q': `r(n)',"' _n
		local nombres `"`nombres'`=cond(`j' > 1, ", ", "")'`q'`fam'`q': `q'`esc'`q'"'
	}
	file write `fh' `"      `q'escalares`q': {`nombres'}"' _n
	file write `fh' `"    }`=cond(`i' < 2, ",", "")'"' _n
}
file write `fh' "  }," _n

** 4.2 Arreglos: entidad y nacional (edad simple), municipios (quinquenal) **
file write `fh' `"  `q'geos`q': {"' _n
file close `fh'
mata: nlpob_geo(st_local("json"), "nl", "Nuevo León", "entidad", "19", "edad_simple", anios_e, X_nl1, X_nl2, 1)
mata: nlpob_geo(st_local("json"), "nac", "Nacional", "pais", "0", "edad_simple", anios_e, X_nac1, X_nac2, 0)
file open `fh' using `"`json'"', write append text
file write `fh' "  }," _n
file write `fh' `"  `q'municipios`q': {"' _n
file close `fh'

preserve
quietly use `munic', clear
sort clave sx anio
mata: anios_m = (`mmin'::`mmax')
tempvar tm
quietly g byte `tm' = 0
local k = 0
foreach c of local claves {
	local ++k
	quietly levelsof nom_mun if clave == `c', local(nm) clean
	quietly replace `tm' = (clave == `c' & sx == 1)
	mata: MH = st_data(., tokens(st_local("grupos")), "`tm'")
	quietly replace `tm' = (clave == `c' & sx == 2)
	mata: MM = st_data(., tokens(st_local("grupos")), "`tm'")
	mata: nlpob_geo(st_local("json"), "m`c'", st_local("nm"), "municipio", "`c'", "quinquenal", anios_m, MH, MM, `k' < `nmun')
}
restore
file open `fh' using `"`json'"', write append text
file write `fh' "  }" _n
file write `fh' "}" _n
file close `fh'
mata: mata drop X_* MH MM anios_e anios_m

*** 5 HTML AUTOCONTENIDO (plantilla versionada + JSON incrustado) ***
local tpl `"`site'/01_modulos/nl-assets/poblacion-nl.html"'
local html `"`site'/users/$id/nodos/poblacion-nl.html"'
capture confirm file `"`tpl'"'
if _rc {
	di as err "PoblacionNL: falta la plantilla 01_modulos/nl-assets/poblacion-nl.html."
	exit 601
}
mata: nlpob_inject(st_local("tpl"), st_local("json"), st_local("html"), "/*__NLPOB_DATA__*/")
if r(hits) != 1 {
	di as err "PoblacionNL: la plantilla debe tener exactamente una marca /*__NLPOB_DATA__*/ (encontradas: `r(hits)')."
	exit 459
}

*** 6 RESUMEN ***
quietly checksum `"`html'"'
local kb = string(r(filelen)/1024, "%9.0fc")
noisily di _newline in g "{bf:PoblacionNL: listo.}"
noisily di in g "  JSON: " in y `"`json'"'
noisily di in g "  HTML: " in y `"`html'"' in g " (`kb' KB)"
noisily di in g "  `nl_titulo' — `nl_subtitulo' · capa `nl_vnl' · año de referencia `anioref'"
noisily di in g "  NL `anioref': " in y %15.0fc scalar(pobtot`sufNL') in g " personas; mujeres " in y %5.1f scalar(pobmujpropI`sufNL') in g "%; razón de dependencia " in y %5.1f scalar(razdepNL)
quietly log close nlpob
