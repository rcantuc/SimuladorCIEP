*! version 8.6 CIEP 06oct2026
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
*   1. Si ${SIMROOT} ya está fijada y no se pide reset, no cambia la raíz.
*   2. dir(<ruta>)  -> la fija explícitamente (profile.do, Web.Stata.do, usuario).
*   3. Si c(sysdir_site) contiene 05_scripts/manifest.json -> es un clon del repo
*      apuntado por sysprofile.do (investigadores CIEP, servidor): compatibilidad.
*   4. En otro caso -> el directorio de trabajo actual, c(pwd), con aviso en
*      pantalla de dónde se escribirán raw/, master/ y users/.
*
* Modo motor (v8.6; lo usa SIM.do §0.0): con scheme y/o smoke la raíz DEBE ser la
* carpeta completa del simulador (SIM.do, SIMroot.ado, scheme-ciep.scheme y
* 05_scripts/manifest.json); si no, se detiene con la instrucción exacta para el
* usuario (r(601)). scheme hace `set scheme ciep` (el scheme vive en la raíz, así
* que requiere el adopath que fija este mismo comando). smoke (o la variable de
* entorno SIM_SMOKE=1 junto con scheme) corre la prueba de humo de
* 05_scripts/test-maquina-virgen.sh --zip: desde raw/temp/ (otra carpeta de
* trabajo, como la deja Expenditure.do) verifica que los .ado del motor se siguen
* encontrando y devuelve r(smoke)=1 para que SIM.do termine sin correr el pipeline.
*
* Sintaxis:   SIMroot [, dir(string) reset quietly scheme smoke]
* Devuelve:   r(root) (= $SIMROOT, sin diagonal final) y r(smoke) (1 si corrió la prueba).

program define SIMroot, rclass
	version 14
	syntax [, Dir(string) Reset Quietly SCHeme SMoke]

	local origen ""
	if `"$SIMROOT"' != "" & "`reset'" == "" & `"`dir'"' == "" {
		local root `"$SIMROOT"'
		local origen "global"
	}
	else if `"`dir'"' != "" {
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

	if "`origen'" != "global" {
		* Ruta absoluta y sin diagonal final (`${SIMROOT}/raw` queda limpio) *
		while inlist(substr(`"`root'"', -1, 1), "/", "\") & length(`"`root'"') > 1 {
			local root = substr(`"`root'"', 1, length(`"`root'"') - 1)
		}
		if "`origen'" == "dir()" & "`scheme'`smoke'" == "" {
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
	}
	return local root `"`root'"'

	* Si la raiz es un clon del repo (trae los .ado), entra al adopath (v8.7.2): asi los
	* modulos se encuentran aunque un .do haga cd (Expenditure.do -> raw/ENIGH) y aunque
	* la carpeta de trabajo cambie; sin profile.do ni sysdir set SITE. Idempotente. *
	if fileexists(`"`root'/SIMroot.ado"') & !strpos(`"`c(adopath)'"', `"`root'"') {
		quietly adopath ++ `"`root'"'
	}

	if "`origen'" != "global" {
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
	}

	return local smoke "0"
	if "`scheme'`smoke'" == "" exit

	* ---------- Modo motor (SIM.do §0.0, v8.6) ----------
	* Validación: la raíz tiene que ser la carpeta completa del simulador. *
	local faltan ""
	foreach f in SIM.do SIMroot.ado scheme-ciep.scheme 05_scripts/manifest.json {
		if !fileexists(`"`root'/`f'"') local faltan `"`faltan' `f'"'
	}
	if `"`faltan'"' != "" {
		di as error _newline `"SIMroot: la carpeta no es (o no está completa) la del Simulador Fiscal CIEP: `root'"'
		di as error `"  Debe contener SIM.do, SIMroot.ado, scheme-ciep.scheme y 05_scripts/manifest.json; falta:`faltan'."'
		di as error `"  Carpeta de trabajo actual: `c(pwd)'"'
		di as error "  Solución (cualquiera de las dos):"
		di as error `"    a) En Stata: File > Change Working Directory... > elige la carpeta del simulador, y luego escribe:  do "SIM.do""'
		di as error `"    b) En la ventana de comandos:  cd "<ruta de la carpeta del simulador>"   y luego   do "SIM.do""'
		di as error "  (Si descargaste el ZIP de GitHub, la carpeta se llama SimuladorCIEP-master y no debe moverse después."
		di as error "   Para salir de Stata: exit, clear). Guía: README, «Inicio rápido para estudiantes (ZIP de GitHub, sin Git)»."
		exit 601
	}

	if "`scheme'" != "" set scheme ciep

	* Prueba de humo (05_scripts/test-maquina-virgen.sh --zip): desde otra carpeta de
	* trabajo los .ado del motor se siguen encontrando (la clase de falla "command LIF
	* is unrecognized" tras el cd de Expenditure.do). Opción smoke, o SIM_SMOKE=1 con
	* scheme (punto de entrada SIM.do). No corre el pipeline: SIM.do termina si r(smoke)=1. *
	local env_smoke : environment SIM_SMOKE
	if "`smoke'" != "" | ("`scheme'" != "" & "`env_smoke'" == "1") {
		local here `"`c(pwd)'"'
		quietly cd `"`root'/raw/temp"'
		foreach a in SIMroot ensure_asset Poblacion PIBDeflactor SCN LIF PEF TasasEfectivas GastoPC perfilpc Simulador FiscalGap escalar {
			which `a'
		}
		quietly cd `"`here'"'
		di as result _newline `"SIMroot: autolocalización OK — carpeta del simulador: `root'"'
		return local smoke "1"
	}
end
