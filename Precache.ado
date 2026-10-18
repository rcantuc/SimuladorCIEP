*! version 8.12 CIEP 18oct2026
* Precache — produce el cache de lo invariante al escenario (v8.12 fase 2a).
*
* Perfil del flujo web «Calcular» (02_governance/perf/perfil-web-2026-10-18.md):
* de ~32 s, ~12 s se iban en piezas que NO dependen de ningún input del
* formulario y se recalculaban en cada clic. Este comando las calcula UNA vez por
* corrida batch (SIM.do §5.1b, después de PEF y antes de GastoPC, con master/ y
* los *RECprom ya hechos) y las guarda como producto en users/$id/cache/. Los
* consumidores (PEF, cache / GastoPC, cache / FiscalGap) las leen con
* _precache_usa, que aborta con receta si faltan o caducaron (sin fallback).
* Viajan al VPS con publicar-vps.sh (Fase 3b-bis, junto con los *RECprom).
*
* Items y convención de nombres (users/<id>/cache/):
*   PEF_<by>_<ifkey>.dta          colapso anual de master/PEF.dta tal como lo pide
*                                 FiscalGap (PEF if transf_gf == 0, by(divCIEP)):
*                                 gasto, gastoTOT, CuoTOT en PESOS corrientes por
*                                 anio × divCIEP × transf_gf. El % PIB se calcula
*                                 después con pibY (depende de CRECPIB/CRECDEF).
*                                 La clave la forma PEF.ado (_PEF_cachekey) de su
*                                 by() e if: la misma para producir y consumir.
*   GastoPC_base_<aniope>.dta     la micro de GastoPC tras §2 (perfiles<aniope> +
*                                 households + indicadores alum_/benef_/der_/pens_/
*                                 cuidados/pob), y
*   GastoPC_base_<aniope>_mat.dta las matrices de CONTEOS de población de §2
*                                 (tabstat [fw=factor]): matriz, columna, nombre, valor.
*   REC_<var>.dta                 collapse estimacion contribuyentes, by(anio modulo
*                                 aniobase) de users/<id>/bootstraps/<B>/<var>RECprom.dta
*                                 (lo que FiscalGap §4.2/§5.2 colapsaba 24 veces por clic).
*   sello.txt                     tab-separado. Líneas:
*                                   sello  <clave>  <valor>      (version, data_updated,
*                                                                 commit, generado, id, bootstrap)
*                                   item   <item>   <archivo>
*                                   insumo <item>   <ruta relativa a SIMROOT>  <bytes>  -
*
* Uso: Precache [, ANIOpe(int) ANIOvp(int)]    (defaults: scalars anioPE / aniovp)
* Requiere: $SIMROOT, $id, $bootstrap; master/PEF.dta, master/perfiles<aniope>.dta,
* master/<anioenigh>/households.dta y los <var>RECprom.dta de users/$id/bootstraps/$bootstrap/.
* (Ojo: en comentarios de Stata nunca escribir barra+asterisco: abre un comentario de bloque y se come el resto
* del archivo. Y los tabs del sello se escriben con _tab: Stata convierte en espacios los tabs del código fuente.)
program define Precache, rclass
	version 17
	timer on 12
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	capture confirm scalar aniovp
	if _rc == 0 local aniovp = scalar(aniovp)
	local aniope = `aniovp'
	capture confirm scalar anioPE
	if _rc == 0 local aniope = scalar(anioPE)
	syntax [, ANIOpe(int `aniope') ANIOvp(int `aniovp')]

	if "$id" == "" | "${SIMROOT}" == "" {
		di as err "Precache: faltan las globals SIMROOT e id (SIM.do §0)."
		exit 198
	}
	if "$bootstrap" == "" {
		di as err `"Precache: falta la global bootstrap (réplicas del escenario base; SIM.do §0.2)."'
		exit 198
	}
	local dir `"${SIMROOT}/users/$id/cache"'
	local dirprom `"${SIMROOT}/users/$id/bootstraps/$bootstrap"'
	capture mkdir `"${SIMROOT}/users/$id"'
	capture mkdir `"`dir'"'
	noisily di _newline(2) in g _dup(20) "." "{bf:   PRECACHE de lo invariante (users/$id/cache/)   }" in g _dup(20) "."

	tempname sello
	tempfile sellotmp
	file open `sello' using `"`sellotmp'"', write text
	_precache_manifest
	local version "`r(version)'"
	local data_updated "`r(data_updated)'"
	local commit "n/a"
	tempfile gitout
	capture quietly shell git -C "${SIMROOT}" rev-parse --short HEAD > "`gitout'" 2>/dev/null
	capture confirm file "`gitout'"
	if _rc == 0 {
		tempname gh
		capture file open `gh' using "`gitout'", read text
		if _rc == 0 {
			file read `gh' linea
			if r(eof) == 0 & trim("`linea'") != "" local commit = trim("`linea'")
			file close `gh'
		}
	}
	file write `sello' "sello" _tab "version" _tab "`version'" _n
	file write `sello' "sello" _tab "data_updated" _tab "`data_updated'" _n
	file write `sello' "sello" _tab "commit" _tab "`commit'" _n
	file write `sello' "sello" _tab "generado" _tab "`c(current_date)' `c(current_time)'" _n
	file write `sello' "sello" _tab "id" _tab "$id" _n
	file write `sello' "sello" _tab "bootstrap" _tab "$bootstrap" _n
	file write `sello' "sello" _tab "aniope" _tab "`aniope'" _n
	local n_items = 0

	** 1. PEF histórico, tal como lo pide FiscalGap (misma llamada: by(divCIEP), if transf_gf == 0) **
	capture confirm file "${SIMROOT}/master/PEF.dta"
	if _rc {
		di as err "Precache: no existe master/PEF.dta (corre PEF antes: SIM.do §5)."
		exit 601
	}
	quietly PEF if transf_gf == 0, anio(`aniope') by(divCIEP) nographs desde(2016) precachear(`"`dir'"')
	local it "`r(precache_item)'"
	_precache_anota `sello' "`it'" "`r(precache_archivo)'" `"`r(precache_insumos)'"'
	local n_items = `n_items' + 1
	noisily di in g "  PEF:      " in y "`it'" in g " (master/PEF.dta -> anio x divCIEP x transf_gf, pesos corrientes)"

	** 2. Base de hogares de GastoPC (§1-2: perfiles + households + conteos de población) **
	quietly GastoPC, aniope(`aniope') aniovp(`aniovp') precachear(`"`dir'"')
	local it "`r(precache_item)'"
	local nv "`r(precache_nvars)'"
	_precache_anota `sello' "`it'" "`r(precache_archivo)'" `"`r(precache_insumos)'"'
	local n_items = `n_items' + 1
	noisily di in g "  GastoPC:  " in y "`it'" in g " (micro tras §2 + matrices de conteos; " in y "`nv'" in g " variables)"

	** 3. Colapsos de los *RECprom (lo que FiscalGap §4.2/§5.2 repetía en cada clic) **
	local files : dir `"`dirprom'"' files "*RECprom.dta"
	local nrec = 0
	foreach f of local files {
		local var = subinstr("`f'", "RECprom.dta", "", 1)
		quietly use `"`dirprom'/`f'"', clear
		quietly collapse estimacion contribuyentes, by(anio modulo aniobase)
		quietly save `"`dir'/REC_`var'.dta"', replace
		_precache_anota `sello' "REC_`var'" "REC_`var'.dta" `"users/$id/bootstraps/$bootstrap/`f'"'
		local nrec = `nrec' + 1
		local n_items = `n_items' + 1
	}
	if `nrec' == 0 {
		di as err `"Precache: no hay <var>RECprom.dta en `dirprom' (PerfilesSim.do §8 los escribe)."'
		exit 601
	}
	noisily di in g "  RECprom:  " in y "`nrec'" in g " colapsos REC_<var>.dta desde users/$id/bootstraps/$bootstrap/"

	file close `sello'
	capture erase `"`dir'/sello.txt"'
	quietly copy `"`sellotmp'"' `"`dir'/sello.txt"'
	noisily di in g "  Sello:    " in y "`dir'/sello.txt" in g " (version `version', data_updated `data_updated', commit `commit')"
	noisily di in g "  Items:    " in y "`n_items'"
	return local dir `"`dir'"'
	return scalar items = `n_items'
	timer off 12
	timer list 12
end

* anota en el sello un item y sus insumos (rutas relativas a SIMROOT) con bytes y mtime
program define _precache_anota
	version 17
	args fh item archivo insumos
	file write `fh' "item" _tab "`item'" _tab "`archivo'" _n
	foreach ins of local insumos {
		local ruta `"${SIMROOT}/`ins'"'
		_precache_bytes `"`ruta'"'
		local bytes "`r(bytes)'"
		file write `fh' "insumo" _tab "`item'" _tab "`ins'" _tab "`bytes'" _tab "-" _n   // 5a columna reservada (mtime): no se exige, rsync/cp pueden no conservarlo
	}
end

