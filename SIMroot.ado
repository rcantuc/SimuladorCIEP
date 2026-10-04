*! version 8.4 CIEP 23sep2026
*
* SIMroot — Raíz del proyecto del Simulador Fiscal CIEP (global $SIMROOT).
*
* CONTRATO (governance, v8.4.0): todo comando del Simulador resuelve sus rutas
* de datos (raw/, master/, users/, 01_modulos/) a partir de ${SIMROOT}, NUNCA de
* c(sysdir_site). SITE es el directorio de ado-files de la instalación de Stata
* (de solo lectura para un usuario externo que hizo `net install`); usarlo como
* raíz del proyecto obligaba a redefinirlo con `sysdir set SITE` en cada máquina.
*
* Resolución (una sola vez por sesión; idempotente):
*   1. Si ${SIMROOT} ya está fijada y no se pide reset, no hace nada.
*   2. dir(<ruta>)  -> la fija explícitamente (profile.do, Web.Stata.do, usuario).
*   3. Si c(sysdir_site) contiene 05_scripts/manifest.json -> es un clon del repo
*      apuntado por sysprofile.do (investigadores CIEP, servidor): compatibilidad.
*   4. En otro caso -> el directorio de trabajo actual, c(pwd), con aviso en
*      pantalla de dónde se escribirán raw/, master/ y users/.
*
* Sintaxis:   SIMroot [, dir(string) reset quietly]
* Devuelve:   r(root)   y la global $SIMROOT (sin diagonal final).

program define SIMroot, rclass
	version 14
	syntax [, Dir(string) Reset Quietly]

	if `"$SIMROOT"' != "" & "`reset'" == "" & `"`dir'"' == "" {
		return local root `"$SIMROOT"'
		exit
	}

	local origen ""
	if `"`dir'"' != "" {
		local root `"`dir'"'
		local origen "dir()"
	}
	else if fileexists(`"`c(sysdir_site)'/05_scripts/manifest.json"') {
		local root `"`c(sysdir_site)'"'
		local origen "sysdir_site"
	}
	else {
		local root `"`c(pwd)'"'
		local origen "pwd"
	}

	* Ruta absoluta y sin diagonal final (`${SIMROOT}/raw` queda limpio) *
	while inlist(substr(`"`root'"', -1, 1), "/", "\") & length(`"`root'"') > 1 {
		local root = substr(`"`root'"', 1, length(`"`root'"') - 1)
	}
	if "`origen'" == "dir()" {
		capture mkdir `"`root'"'
	}
	quietly {
		local here `"`c(pwd)'"'
		capture cd `"`root'"'
		if _rc != 0 {
			noisily di as error `"SIMroot: no existe el directorio `root'."'
			exit 601
		}
		local root `"`c(pwd)'"'
		cd `"`here'"'
	}

	global SIMROOT `"`root'"'
	return local root `"`root'"'

	* Subcarpetas de datos (la creacion de users/$id la hace cada comando) *
	capture mkdir `"`root'/raw"'
	capture mkdir `"`root'/raw/temp"'
	capture mkdir `"`root'/master"'
	capture mkdir `"`root'/users"'

	if "`quietly'" == "" & "`origen'" == "pwd" {
		noisily di as text _newline "Simulador Fiscal CIEP: carpeta de trabajo " as result `"`root'"'
		noisily di as text "  Los datos se guardan en raw/, master/ y users/ dentro de esa carpeta."
		noisily di as text `"  Para usar otra: {cmd:SIMroot, dir("<ruta>")}  o  {cmd:global SIMROOT "<ruta>"}"'
	}
end
