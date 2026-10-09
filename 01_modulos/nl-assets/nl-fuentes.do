*! nl-fuentes.do  v1.0.0 — candado de fuentes propias de la capa NL (NL-0.6.0, sesión C1 2026-10-08)
*
* POR QUÉ EXISTE (DIAGNOSTICO_NL.md, anexo "Fuentes congeladas de la capa NL"):
*   El motor congela sus descargas con `global fuentes "AAAA-MM-DD"` (asset
*   raw/fuentes/fuentes-<fecha>.zip, SIM.do §0.4; manifest.json
*   fuentes_congeladas_al). Las series que la capa NL trae por su cuenta —
*   _NLbie (raw/temp/AccesoBIE/nl_<indicador>.csv + .meta), _NLinpc
*   (nl_inpc_<serie>.csv + .meta) y _NLeopf (raw/temp/EOPF/nl_transferencias.csv
*   + .meta + _fondos.csv) — corrían SIEMPRE en vivo y tumbaron dos compuertas
*   en 48 h (INPC 2026-09 publicado el 7-oct; EOFP re-descargado el 8-oct).
*   Con `global nlfuentes "AAAA-MM-DD"` los tres lectores leen el estado
*   empacado en 01_modulos/nl-assets/nl-fuentes-<fecha>.zip y NO descargan;
*   con el global vacío el comportamiento es idéntico al anterior (en vivo, u
*   offline con la caché que haya). Misma convención que el motor: la fecha es
*   la de las descargas empacadas; cambiarla es un release de datos de la capa
*   (nuevo zip, SHA en nl-manifest.json, fuentes_nl_congeladas_al).
*
* COMANDO (definido al correr este archivo con `run`):
*   _NLfuentes            -> r(congelado) = 1 si $nlfuentes != "" (y entonces el
*                            zip ya quedó extraído en raw/temp/ UNA vez por sesión,
*                            con `replace`, como hace SIM.do con el asset del motor);
*                            r(congelado) = 0 si el global está vacío (no hace nada).
*   Verifica que el zip esté declarado en nl-manifest.json (assets[].name) y que
*   su checksum y longitud (Stata `checksum`) coincidan: un zip pisado o ausente
*   aborta. No rediseña ensure_asset (el zip viaja commiteado en nl-assets/, como
*   pobproy_quinq1.csv) ni toca el motor.

capture program drop _NLfuentes
program define _NLfuentes, rclass
	SIMroot
	return scalar congelado = 0
	if "$nlfuentes" == "" exit
	local nombre "nl-fuentes-${nlfuentes}.zip"
	local zip `"${SIMROOT}/01_modulos/nl-assets/`nombre'"'
	capture confirm file `"`zip'"'
	if _rc {
		di as err "nl-fuentes: falta 01_modulos/nl-assets/`nombre' (global nlfuentes = $nlfuentes). Sin el zip no hay fuentes congeladas de la capa."
		exit 601
	}
	if "${NLFUENTES_EXTRAIDO}" != "${nlfuentes}" {
		* Declaración en nl-manifest.json: bloque cuyo name es el zip; checksum_stata y filelen *
		local q = char(34)
		local bt = char(96)
		local enbloque = 0
		local chk = ""
		local len = ""
		capture confirm file `"${SIMROOT}/01_modulos/nl-assets/nl-manifest.json"'
		if _rc {
			di as err "nl-fuentes: falta 01_modulos/nl-assets/nl-manifest.json."
			exit 601
		}
		tempname mh
		file open `mh' using `"${SIMROOT}/01_modulos/nl-assets/nl-manifest.json"', read text
		file read `mh' line
		while r(eof) == 0 {
			local line : subinstr local line "`bt'" "", all
			if regexm(`"`line'"', `"`q'name`q'[ ]*:[ ]*`q'([^`q']*)`q'"') {
				local enbloque = (regexs(1) == "`nombre'")
			}
			if `enbloque' & regexm(`"`line'"', `"`q'checksum_stata`q'[ ]*:[ ]*([0-9]+)"') local chk = regexs(1)
			if `enbloque' & regexm(`"`line'"', `"`q'filelen`q'[ ]*:[ ]*([0-9]+)"') local len = regexs(1)
			file read `mh' line
		}
		file close `mh'
		if "`chk'" == "" | "`len'" == "" {
			di as err "nl-fuentes: `nombre' no está declarado en nl-manifest.json (name + checksum_stata + filelen). No se usa un zip sin declarar."
			exit 198
		}
		quietly checksum `"`zip'"'
		if r(checksum) != `chk' | r(filelen) != `len' {
			di as err "nl-fuentes: `nombre' no coincide con nl-manifest.json (checksum `=r(checksum)' vs `chk'; bytes `=r(filelen)' vs `len'). Zip pisado o manifest desactualizado."
			exit 459
		}
		capture mkdir "${SIMROOT}/raw"
		capture mkdir "${SIMROOT}/raw/temp"
		quietly cd "${SIMROOT}/raw/temp"
		quietly unzipfile `"`zip'"', replace
		quietly cd "${SIMROOT}"
		global NLFUENTES_EXTRAIDO "${nlfuentes}"
		noisily di in g "  nl-fuentes: fuentes propias de la capa congeladas al " in y "$nlfuentes" in g " (`nombre' -> raw/temp/AccesoBIE/nl_*, raw/temp/EOPF/*; checksum verificado; sin descargas)."
	}
	return scalar congelado = 1
end
