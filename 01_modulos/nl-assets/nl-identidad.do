*! nl-identidad.do  v1.0.0 — identidad de producto de la capa NL (F1, NL-0.1.0)
*
* Define _NLidentidad: lee la versión del MOTOR desde 05_scripts/manifest.json
* (la misma fuente de verdad que profile.do y scalarjson.ado) y la versión de
* la CAPA NL desde 01_modulos/nl-assets/nl-manifest.json. Nada se escribe a
* mano: si un manifiesto falta, la versión sale vacía y se declara.
*
* Uso (desde un driver de la capa NL, tras SIMroot):
*   run "${SIMROOT}/01_modulos/nl-assets/nl-identidad.do"
*   _NLidentidad, modulo("Población")          // imprime el encabezado
*   local vmotor `r(version_motor)'            // p. ej. v8.6.0
*   local vnl    `r(version_nl)'               // p. ej. NL-0.1.0
*   local sub    `"`r(subtitulo)'"'            // construido sobre el Simulador Fiscal CIEP v8.6.0
*
* El motor no se toca: esto es presentación de la capa de producto. Las
* salidas nacionales (output.txt, títulos de los .ado) conservan su identidad.

capture program drop _NLidentidad
program define _NLidentidad, rclass
	syntax [, MODulo(string) Quietly]
	SIMroot
	local q = char(34)

	* Versión del motor (manifest.json; misma regex que scalarjson.ado) *
	local vmotor ""
	capture confirm file `"${SIMROOT}/05_scripts/manifest.json"'
	if _rc == 0 {
		tempname mh
		file open `mh' using `"${SIMROOT}/05_scripts/manifest.json"', read text
		file read `mh' line
		while r(eof) == 0 {
			if regexm(`"`line'"', `"`q'version`q'[ ]*:[ ]*`q'([^`q']*)`q'"') & "`vmotor'" == "" {
				local vmotor = regexs(1)
			}
			file read `mh' line
		}
		file close `mh'
	}

	* Versión de la capa NL (nl-manifest.json) *
	local vnl ""
	local producto ""
	capture confirm file `"${SIMROOT}/01_modulos/nl-assets/nl-manifest.json"'
	if _rc == 0 {
		tempname nh
		file open `nh' using `"${SIMROOT}/01_modulos/nl-assets/nl-manifest.json"', read text
		file read `nh' line
		while r(eof) == 0 {
			if regexm(`"`line'"', `"`q'version_nl`q'[ ]*:[ ]*`q'([^`q']*)`q'"') & "`vnl'" == "" {
				local vnl = regexs(1)
			}
			if regexm(`"`line'"', `"`q'producto`q'[ ]*:[ ]*`q'([^`q']*)`q'"') & `"`producto'"' == "" {
				local producto = regexs(1)
			}
			file read `nh' line
		}
		file close `nh'
	}
	if `"`producto'"' == "" local producto "Simulador Fiscal NL"

	local titulo `"`producto'"'
	if `"`modulo'"' != "" local titulo `"`producto' — `modulo'"'
	local subtitulo `"construido sobre el Simulador Fiscal CIEP `vmotor'"'

	if "`quietly'" == "" {
		noisily di _newline(2) in g _dup(70) "="
		noisily di in y `"{bf:`titulo'}"'
		noisily di in g `"`subtitulo'"' in g " · capa " in y "`vnl'"
		if "`vmotor'" == "" noisily di as err "  (manifest.json del motor no encontrado: versión del motor sin declarar)"
		if "`vnl'" == ""    noisily di as err "  (nl-manifest.json no encontrado: versión de la capa NL sin declarar)"
		noisily di in g _dup(70) "="
	}

	return local producto `"`producto'"'
	return local titulo `"`titulo'"'
	return local subtitulo `"`subtitulo'"'
	return local version_motor "`vmotor'"
	return local version_nl "`vnl'"
end
