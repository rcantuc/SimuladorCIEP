*! test-nta-identidad.do  v1.2 (NTA-1c, 2026-10-28) — gate de identidad de la cuenta NTA por individuo
*
* Recalcula desde users/$id/NTA/nta-persona.dta (lo que escribió 01_modulos/NTA.do) y exige:
*   1. identidad SIN ancla por grupo de edad y por quinquenio × sexo: C − YL − ImpProd − (τ⁺ − τ⁻) − (YA − YA_ajuste − S_sinancla)
*      − intra = 0 a 1e-9 RELATIVO (relativo al C del grupo; τ⁺ = Tpub + InterRec + Remesas, τ⁻ = Tmen + InterOtor; ImpProd =
*      impuestos netos a los productos como ingreso; bases NTA-1 sin esas columnas: ImpProd = 0, S_sinancla = S − YA_ajuste);
*      y, con ancla, que el residual CON ancla sea exactamente el ajuste declarado S_ajuste = S − S_sinancla − YA_ajuste;
*   2. Σ intra-hogar nacional = 0 a 1e-9 relativo (a Σ |intra|) y Σ intra por hogar = 0 (misma tolerancia, al C del hogar);
*   3. Σ S_sinancla vs AhorroHog (B.8n S.14): factor implícito y brecha (informativo). Si hay ancla (aditivo | multiplicativo,
*      NTA-1c: auto la activa solo si |brecha| ≤ 15 %), Σ S = AhorroHog a 1e-9 y se reporta el factor;
*   4. las anclas S.14 por construcción (1e-9 relativo): Σ CpubInd = TransfEspecie (D.63), Σ ImpProd = ImpNetosProd
*      (D.21 − D.31), Σ YA_d8 = AjustePension (D.8), con nta_anclaTau = on Σ TpubEf = TauPubS14 (D.62 + D.759) y, con
*      nta_YA = S14, Σ YA_base = YAHogS14 (B.2n + 1/3 B.3n + D.4 neto);
*   5. los agregados por grupo del JSON nta-grupoedad.json coinciden con los recalculados (1e-6 relativo: 4 decimales de MXN).
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

** Anclas: los escalares vivos de SCN para el año (no los char del archivo); SCN deja su base en memoria **
quietly SCN, anio(`anio') nographs
local AhorroHog = scalar(AhorroHog)
foreach k in TransfEspecie ImpNetosProd AjustePension TauPubS14 YAHogS14 {
	capture local `k' = scalar(`k')
	if _rc local `k' = .
}
local sinancla = strpos("`params'", "nta_anclaS=off") > 0
local tauon = strpos("`params'", "nta_anclaTau=on") > 0
local yas14 = strpos("`params'", "nta_YA=S14") > 0
use `"`dta'"', clear
capture confirm variable ImpProd
if _rc != 0 quietly g double ImpProd = 0
capture confirm variable YA_ajuste
if _rc != 0 quietly g double YA_ajuste = 0
capture confirm variable S_sinancla
if _rc != 0 quietly g double S_sinancla = S - YA_ajuste
capture confirm variable S_ajuste
if _rc != 0 quietly g double S_ajuste = S - S_sinancla - YA_ajuste
foreach v in CpubInd YA_d8 TpubEf YA_base {
	capture confirm variable `v'
	if _rc != 0 quietly g double `v' = .
}

** 1. Identidad SIN ancla por grupo de edad y por quinquenio × sexo; con ancla, residual = S_ajuste declarado **
quietly g double resid = C - YL - ImpProd - (Tpub + InterRec + Remesas - Tmen - InterOtor) - (YA - YA_ajuste - S_sinancla) - Intra
quietly g double residancla = C - YL - ImpProd - (Tpub + InterRec + Remesas - Tmen - InterOtor) - (YA - S) - Intra - S_ajuste
foreach corte in "grupoedad" "quinq sexo" {
	preserve
	quietly collapse (sum) C resid residancla [fw=factor], by(`corte')
	quietly g double rel = abs(resid)/C
	quietly g double rela = abs(residancla)/C
	quietly summarize rel, meanonly
	local mx = r(max)
	quietly summarize rela, meanonly
	local mxa = r(max)
	quietly count
	noisily di in g "  identidad sin ancla por `corte': " in y r(N) in g " celdas; |R|/C máx " in y %9.2e `mx' in g "; con ancla − S_ajuste declarado " in y %9.2e `mxa' in g " -> " in y cond(`mx' <= `tol' & `mxa' <= `tol', "OK", "ROJO")
	if `mx' > `tol' | `mxa' > `tol' local rojo = 1
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

** 3. Σ S sin ancla vs AhorroHog (informativo); con ancla, Σ S = AhorroHog **
quietly tabstat S S_sinancla S_ajuste [fw=factor], stat(sum) save
local Snac = r(StatTotal)[1,1]
local Ssin = r(StatTotal)[1,2]
local Saj = r(StatTotal)[1,3]
noisily di in g "  Σ S sin ancla " in y %20.0fc `Ssin' in g " vs AhorroHog (B.8n S.14 `anio') " in y %20.0fc `AhorroHog' in g " (factor implícito " in y %8.4f `AhorroHog'/`Ssin' in g "; brecha " in y %7.1f (`Ssin'/`AhorroHog' - 1)*100 in g " %)"
if `sinancla' {
	noisily di in g "  Σ S final = sin ancla (nta_anclaS=off) -> " in y "OK"
}
else {
	noisily di in g "  Σ S con ancla " in y %20.0fc `Snac' in g " vs AhorroHog (reldif " in y %9.2e reldif(`Snac', `AhorroHog') in g "); Σ S_ajuste declarado " in y %20.0fc `Saj' in g " -> " in y cond(reldif(`Snac', `AhorroHog') <= `tol', "OK", "ROJO")
	if reldif(`Snac', `AhorroHog') > `tol' local rojo = 1
}

** 4. Anclas S.14 por construcción **
quietly tabstat CpubInd ImpProd YA_d8 TpubEf YA_base [fw=factor], stat(sum) save
tempname A
matrix `A' = r(StatTotal)
local j = 0
foreach par in "CpubInd TransfEspecie D.63" "ImpProd ImpNetosProd D.21-D.31" "YA_d8 AjustePension D.8" "TpubEf TauPubS14 D.62+D.759" "YA_base YAHogS14 B.2n+1/3B.3n+D.4neto" {
	local ++j
	gettoken v par : par
	gettoken k cod : par
	local cod = trim("`cod'")
	if "`v'" == "TpubEf" & !`tauon' {
		noisily di in g "  Σ `v' " in y %20.0fc `A'[1,`j'] in g " (nta_anclaTau=off: sin ancla a `k')"
		continue
	}
	if "`v'" == "YA_base" & !`yas14' {
		noisily di in g "  Σ `v' " in y %20.0fc `A'[1,`j'] in g " (nta_YA=motor: sin ancla a `k')"
		continue
	}
	if ``k'' == . | `A'[1,`j'] == . {
		noisily di in g "  Σ `v' " in y %20.0fc `A'[1,`j'] in g " (`k' no disponible: sin comparar)"
		continue
	}
	local d = reldif(`A'[1,`j'], ``k'')
	noisily di in g "  Σ `v' " in y %20.0fc `A'[1,`j'] in g " vs `k' (`cod') " in y %20.0fc ``k'' in g " (reldif " in y %9.2e `d' in g ") -> " in y cond(`d' <= `tol', "OK", "ROJO")
	if `d' > `tol' local rojo = 1
}

** 5. El JSON por grupo dice lo mismo que la base **
local json : subinstr local dta "nta-persona.dta" "nta-grupoedad.json"
capture confirm file `"`json'"'
if _rc == 0 {
	preserve
	quietly collapse (sum) C YL ImpProd YA S Tpub Tmen InterRec Remesas InterOtor Intra [fw=factor], by(grupoedad)
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
			foreach v in YL ImpProd YA S Tpub Tmen InterRec Remesas InterOtor Intra {
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
