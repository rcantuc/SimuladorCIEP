*! test-nta-identidad.do  v1.0 (NTA-1, 2026-10-27) — gate de identidad de la cuenta NTA por individuo
*
* Recalcula desde users/$id/NTA/nta-persona.dta (lo que escribió 01_modulos/NTA.do) y exige:
*   1. por grupo de edad y por quinquenio × sexo: C − YL − (τ⁺ − τ⁻) − (YA − S) − intra = 0 a 1e-9 RELATIVO
*      (relativo al C del grupo; τ⁺ = Tpub + InterRec + Remesas, τ⁻ = Tmen + InterOtor);
*   2. Σ intra-hogar nacional = 0 a 1e-9 relativo (a Σ |intra|) y Σ intra por hogar = 0 (misma tolerancia, al C del hogar);
*   3. Σ S = AhorroHog (B.8n S.14, escalar de SCN.ado para el año de la cuenta) a 1e-9 relativo, cuando nta_anclaS = AhorroHog;
*   4. los agregados por grupo del JSON nta-grupoedad.json coinciden con los recalculados (1e-9 relativo).
* Falla = exit 9 (el .sh lo vuelve PR rojo). No escribe nada en users/.
* USO: do "${SIMROOT}/05_scripts/test-nta-identidad.do" [<ruta a nta-persona.dta>]
local dta `"`1'"'
if `"`dta'"' == "" local dta `"${SIMROOT}/users/$id/NTA/nta-persona.dta"'
local tol = 1e-9
local rojo = 0

use in 1 using `"`dta'"', clear
local anio : char _dta[nta_anio]
local params : char _dta[nta_parametros]
noisily di _newline in g "{bf:test-nta-identidad}: " in y `"`dta'"' in g " (año " in y "`anio'" in g "; `params')"

** 3. Ancla: el escalar vivo de SCN para el año (no el char del archivo); SCN deja su base en memoria **
quietly SCN, anio(`anio') nographs
local AhorroHog = scalar(AhorroHog)
local anclado = strpos("`params'", "nta_anclaS=AhorroHog") > 0
use `"`dta'"', clear

** 1. Identidad por grupo de edad y por quinquenio × sexo **
quietly g double resid = C - YL - (Tpub + InterRec + Remesas - Tmen - InterOtor) - (YA - S) - Intra
foreach corte in "grupoedad" "quinq sexo" {
	preserve
	quietly collapse (sum) C resid [fw=factor], by(`corte')
	quietly g double rel = abs(resid)/C
	quietly summarize rel, meanonly
	local mx = r(max)
	quietly count
	noisily di in g "  identidad por `corte': " in y r(N) in g " celdas; |R|/C máx " in y %9.2e `mx' in g " -> " in y cond(`mx' <= `tol', "OK", "ROJO")
	if `mx' > `tol' local rojo = 1
	restore
}

** 2. Σ intra-hogar: nacional y por hogar **
quietly {
	g double absintra = abs(Intra)
	tabstat Intra absintra C [fw=factor], stat(sum) save
	local inac = r(StatTotal)[1,1]
	local iabs = r(StatTotal)[1,2]
	local Ctot = r(StatTotal)[1,3]
	egen double ihog = total(Intra), by(hhid)
	egen double Chog = total(C), by(hhid)
	g double relhog = abs(ihog)/Chog
	summarize relhog, meanonly
	local mxhog = r(max)
}
noisily di in g "  Σ intra nacional " in y %14.4f `inac' in g " (relativo a Σ|intra| " in y %9.2e abs(`inac')/`iabs' in g "); por hogar |Σ|/C máx " in y %9.2e `mxhog' in g " -> " in y cond(abs(`inac')/`iabs' <= `tol' & `mxhog' <= `tol', "OK", "ROJO")
if abs(`inac')/`iabs' > `tol' | `mxhog' > `tol' local rojo = 1

** 3. Σ S = AhorroHog **
quietly tabstat S [fw=factor], stat(sum) save
local Snac = r(StatTotal)[1,1]
if `anclado' {
	noisily di in g "  Σ S " in y %20.0fc `Snac' in g " vs AhorroHog (B.8n S.14 `anio') " in y %20.0fc `AhorroHog' in g " (reldif " in y %9.2e reldif(`Snac', `AhorroHog') in g ") -> " in y cond(reldif(`Snac', `AhorroHog') <= `tol', "OK", "ROJO")
	if reldif(`Snac', `AhorroHog') > `tol' local rojo = 1
}
else {
	noisily di in g "  Σ S " in y %20.0fc `Snac' in g " (sin ancla por parámetro; AhorroHog = " in y %20.0fc `AhorroHog' in g ")"
}

** 4. El JSON por grupo dice lo mismo que la base **
local json : subinstr local dta "nta-persona.dta" "nta-grupoedad.json"
capture confirm file `"`json'"'
if _rc == 0 {
	preserve
	quietly collapse (sum) C YL YA S Tpub Tmen InterRec Remesas InterOtor Intra [fw=factor], by(grupoedad)
	local mxj = 0
	local nj = 0
	tempname jh
	file open `jh' using `"`json'"', read text
	file read `jh' line
	while r(eof) == 0 {
		if regexm(`"`line'"', `"^,?\{"g":([1-5]),"grupo":"[^"]*","pob":[0-9]+,"C":([-0-9.e+]+)"') {
			local g = regexs(1)
			local ++nj
			local Cj = regexs(2)
			quietly summarize C if grupoedad == `g', meanonly
			local d = reldif(`Cj', r(mean))
			if `d' > `mxj' local mxj = `d'
			foreach v in YL YA S Tpub Tmen InterRec Remesas InterOtor Intra {
				if regexm(`"`line'"', `""`v'":([-0-9.e+]+)"') {
					local vj = regexs(1)
					quietly summarize `v' if grupoedad == `g', meanonly
					local d = cond(r(mean) == 0, abs(`vj'), reldif(`vj', r(mean)))
					if `d' > `mxj' local mxj = `d'
				}
			}
		}
		file read `jh' line
	}
	file close `jh'
	restore
	noisily di in g "  nta-grupoedad.json vs base: " in y "`nj'" in g " grupos leídos; reldif máx " in y %9.2e `mxj' in g " -> " in y cond(`mxj' <= 1e-6 & `nj' == 5, "OK", "ROJO")
	if `mxj' > 1e-6 | `nj' != 5 local rojo = 1	// el JSON va con 4 decimales de MXN: 1e-6 relativo es el límite del formato
}
else {
	noisily di as err "  falta `json'"
	local rojo = 1
}

if `rojo' {
	noisily di as err "test-nta-identidad: ROJO"
	exit 9
}
noisily di in g "{bf:test-nta-identidad: VERDE}"
