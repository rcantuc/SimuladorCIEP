**************
*** SANKEY ***
**************
timer on 9
if "`1'" == "" {
	local 1 = "decil"
	local 2 = 2025
}

* Entidad federativa (global entidad, 2026-10-10). Tercer argumento opcional = nombre de la
* entidad ($entidadesL, SIMentidad); lo pasa SIM.do §8.2 solo con $entidad definido. Con él:
*   - la base se filtra a la entidad (clave INEGI = substr(folioviv,1,2)) tras cada use;
*   - el corte "quintil" se re-rankea DENTRO de la entidad con el criterio de ingreso del
*     motor (Households.do §12: ingreso bruto del hogar por integrante, xtile n(5) con
*     pw = factor/integrantes): P2 = la construcción sellada del sprint NL (C1, 2026-10-08);
*   - los renglones per cápita usan la población ENIGH de la entidad con su fórmula actual
*     (pobtot) y los renglones "% PIB × pibY" se reparten por población (supuesto S-P3,
*     $entidad_macro "pob" | "omitir"; pendiente de firma en el CHANGELOG);
*   - los outputs van a users/$id/<ABREV>/ con los mismos nombres (P1, SankeySumSim folder());
*   - cada enlace micro lleva su banda de vintages ENIGH (P4: participación de la celda de la
*     entidad en el total nacional de la familia, observada en users/$id-v<t>/aportaciones.dta,
*     × total nacional vigente; mín/máx = halo, el vigente = punto) y sus sellos de muestra
*     (P5: n < $sello_n personas o concTop1 > $sello_top1 %) como campos del JSON.
* Sin tercer argumento no se ejecuta ni una línea de los bloques de entidad. *
local entidad : subinstr local 3 `"""' "", all		// el argumento de un do-file llega con sus comillas
local entidad = trim(`"`entidad'"')
local cuotas_spec ""
local sankey_extra ""
if `"`entidad'"' != "" {
	SIMentidad `"`entidad'"'
	local enombre `"`r(nombre)'"'
	local eclave "`r(clave)'"
	local eabrev "`r(abrev)'"
	local sello_n = cond("$sello_n" == "", 100, real("$sello_n"))
	local sello_top1 = cond("$sello_top1" == "", 25, real("$sello_top1"))
	local macro_regla = cond("$entidad_macro" == "", "pob", "$entidad_macro")
	if !inlist("`macro_regla'", "pob", "omitir") {
		di as err `"SankeySF: global entidad_macro "`macro_regla'" no es "pob" ni "omitir" (SIM.do §0.4)."'
		exit 198
	}
	local cuotas_aparte = ("$entidad_cuotas" == "aparte")
	local vintages "2016 2018 2020 2022 2024"
	if "$entidad_vintages" == "0" local vintages ""
	else if "$entidad_vintages" != "" local vintages "$entidad_vintages"

	* Familias micro de cada eje: variable de aportaciones.dta y el sufijo con el que el
	* reshape de abajo las nombra (etiqueta del nodo con "_" por espacio; los "_" iniciales
	* solo ordenan). Cuotas aparte (P5, regla NL): nodo propio y se restan de Imp al trabajo. *
	local fams1 "AlTrabajo AlConsumo AlCapital"
	local sufs1 "Imp_al_trabajo _Imp_al_consumo __Imp_al_capital"
	if `cuotas_aparte' {
		local fams1 "`fams1' CUOTAS_Sim"
		local sufs1 "`sufs1' ___Cuotas_IMSS"
		local cuotas_spec "ing____Cuotas_IMSS=CUOTAS_Sim"
	}
	local fams4 "Educacion Salud Pensiones IngBasico OtrasInversiones"
	local sufs4 "Educación Salud __Pensiones ___Transferencias ___Inversión"

	* Totales nacionales vigentes (base completa, sin filtrar): población ENIGH y Σ familia *
	quietly {
		local uvars "factor CUOTAS_Sim `fams1' `fams4'"
		local uvars : list uniq uvars
		use `uvars' using `"${SIMROOT}/users/$id/aportaciones.dta"', clear
		if `cuotas_aparte' replace AlTrabajo = AlTrabajo - CUOTAS_Sim
		summarize factor, meanonly
		local pobnac = r(sum)
		foreach e in 1 4 {
			local nacvig`e' ""
			foreach f of local fams`e' {
				tempvar w
				g double `w' = `f'*factor
				summarize `w', meanonly
				local s = r(sum)
				local nacvig`e' "`nacvig`e'' `s'"
				drop `w'
			}
		}
	}

	* Filtro a la entidad y, para el corte quintil, re-ranking estatal (P2 = C1 del sprint NL) *
	capture program drop _SFentidad
	program define _SFentidad
		args clave corte
		keep if substr(folioviv, 1, 2) == "`clave'"
		if "`corte'" == "quintil" {
			tempvar toti ingh ingpc wh
			egen `toti' = count(edad), by(folioviv foliohog)
			egen double `ingh' = total(ingbrutotot), by(folioviv foliohog)
			g double `ingpc' = `ingh'/`toti'
			g double `wh' = factor/`toti'
			xtile quintil = `ingpc' [pw=`wh'], n(5)
			capture label drop quintil
			label define quintil 1 "I" 2 "II" 3 "III" 4 "IV" 5 "V"
			label values quintil quintil
		}
	end

	* Sellos de muestra (P5) y banda de vintages (P4) por celda × familia. Deja en out() un
	* archivo con claves (<corte>, key = sufijo del reshape) y variables j_* que SankeySumSim
	* escribe como campos del enlace; devuelve r(vintages) usados y r(celdas) (JSON). *
	capture program drop _SFsellos
	program define _SFsellos, rclass
		syntax, CORTE(string) FAMS(string) SUFS(string) CLAVE(string) APARTE(integer) ///
			NACVIG(string) SELLON(real) SELLOTOP1(real) OUT(string) IDV(string) [VINTAGES(string)]
		preserve
		local nf : word count `fams'
		quietly {
			local cs ""
			local cn ""
			local cm ""
			forvalues i = 1/`nf' {
				local f : word `i' of `fams'
				g double w_`i' = `f'*factor
				g byte p_`i' = `f' != 0 & `f' != .
				local cs "`cs' s_`i'=w_`i'"
				local cn "`cn' n_`i'=p_`i'"
				local cm "`cm' m_`i'=w_`i'"
			}
			bysort folioviv foliohog: g byte hog1 = _n == 1
			g byte one = 1
			collapse (sum) `cs' `cn' nPers=one nHog=hog1 pob=factor (max) `cm', by(`corte')
			local celdas ""
			forvalues k = 1/`=_N' {
				local lab : label (`corte') `=`corte'[`k']'
				local lab = subinstr("`lab'", " ", "_", .)
				local celdas `"`celdas'`=cond(`k' > 1, ",", "")'{celda:"`lab'",n:"`=nPers[`k']'",hog:"`=nHog[`k']'",pob:"`=pob[`k']'"}"'
			}
			drop nPers nHog pob
			reshape long s_ n_ m_, i(`corte') j(fam)
			g double j_top1 = cond(s_ != 0, m_/s_*100, .)
			rename n_ j_n
			g byte j_sello = (j_n < `sellon') | (j_top1 > `sellotop1')
			g key = ""
			forvalues i = 1/`nf' {
				replace key = "`: word `i' of `sufs''" if fam == `i'
			}
			keep `corte' fam key j_n j_top1 j_sello
			tempfile S
			save `S'

			* Banda: la misma celda × familia en cada vintage ENIGH disponible (filtrar, no re-correr) *
			local usados ""
			local omitidos ""
			foreach t of local vintages {
				local base `"${SIMROOT}/users/`idv'-v`t'/aportaciones.dta"'
				capture confirm file `"`base'"'
				if _rc {
					local omitidos "`omitidos' `t'"
					continue
				}
				local cvar = cond("`corte'" == "quintil", "", "`corte'")
				local uvars "folioviv foliohog factor edad ingbrutotot `cvar' `fams'"
				if `aparte' local uvars "`uvars' AlTrabajo CUOTAS_Sim"
				local uvars : list uniq uvars
				capture use `uvars' using `"`base'"', clear
				if _rc {
					* la ENIGH 2016 (base del 8-oct) nombra factor_hog al factor de expansión *
					local uvars2 : subinstr local uvars "factor" "factor_hog", word
					capture use `uvars2' using `"`base'"', clear
					if _rc {
						local omitidos "`omitidos' `t'"
						continue
					}
					rename factor_hog factor
				}
				if `aparte' replace AlTrabajo = AlTrabajo - CUOTAS_Sim
				forvalues i = 1/`nf' {
					local f : word `i' of `fams'
					g double w_`i' = `f'*factor
					summarize w_`i', meanonly
					local nac`i' = r(sum)
				}
				_SFentidad `clave' `corte'
				collapse (sum) w_*, by(`corte')
				reshape long w_, i(`corte') j(fam)
				g double j_v`t' = .
				forvalues i = 1/`nf' {
					replace j_v`t' = w_/`nac`i''*`: word `i' of `nacvig'' if fam == `i'
				}
				keep `corte' fam j_v`t'
				tempfile V`t'
				save `V`t''
				local usados "`usados' `t'"
			}
			use `S', clear
			foreach t of local usados {
				merge 1:1 `corte' fam using `V`t'', nogen keep(master match)
			}
			if "`usados'" != "" {
				egen double j_bmin = rowmin(j_v*)
				egen double j_bmax = rowmax(j_v*)
			}
			drop fam
			save `"`out'"', replace
		}
		restore
		return local vintages "`usados'"
		return local omitidos "`omitidos'"
		return local celdas `"`celdas'"'
	end
}





***************************************
*** 1 Sistema de Cuentas Nacionales ***
***************************************
*SCN, anio(`2') nographs
PIBDeflactor, anio(`2') nographs nooutput



**********************************/
** Eje 1: Generación del ingreso **
use `"${SIMROOT}/users/$id/aportaciones.dta"', clear
if `"`entidad'"' != "" {
	if `cuotas_aparte' replace AlTrabajo = AlTrabajo - CUOTAS_Sim
	_SFentidad `eclave' `1'
	tempfile sellos1
	_SFsellos, corte(`1') fams(`fams1') sufs(`sufs1') clave(`eclave') aparte(`cuotas_aparte') ///
		vintages(`vintages') nacvig(`nacvig1') sellon(`sello_n') sellotop1(`sello_top1') out(`sellos1') idv($id)
	local vint_usados "`r(vintages)'"
	local vint_omitidos "`r(omitidos)'"
	local celdas `"`r(celdas)'"'
	summarize factor, meanonly
	local pobent = r(sum)
	local eshare = `pobent'/`pobnac'
	local eshare1 = cond("`macro_regla'" == "pob", `eshare', 0)	// renglones % PIB × pibY (S-P3)
	local eshare4 = cond("`macro_regla'" == "pob", 1, 0)			// renglones per cápita: pobtot ya es el de la entidad
	noisily di _newline in g "  Sankey de entidad: " in y "`enombre'" in g " (`eabrev', clave `eclave') {c -} corte " in y "`1'" in g ", población ENIGH " in y %12.0fc `pobent' in g " (" in y %5.2f `eshare'*100 in g " % del nacional), renglones macro: " in y "`macro_regla'" in g ", cuotas: " in y "`=cond(`cuotas_aparte', "aparte", "en Imp al trabajo")'" in g ", banda ENIGH: " in y "`=cond("`vint_usados'" == "", "sin banda", trim("`vint_usados'"))'" in g ", sellos n<`sello_n' | top1>`sello_top1' %."
}
collapse (sum) ing_Imp_al_trabajo=AlTrabajo ing__Imp_al_consumo=AlConsumo ///
	ing___Imp_al_capital=AlCapital /*ing____FMP=FMP_Sim*/ `cuotas_spec' [fw=factor], by(`1')

* to *
tempvar to
reshape long ing_, i(`1') j(`to') string
if `"`entidad'"' != "" {
	preserve
	use `sellos1', clear
	rename key `to'
	save `sellos1', replace
	restore
	merge 1:1 `1' `to' using `sellos1', nogen keep(master match)
}
rename ing_ profile
encode `to', g(to)

* from *
rename `1' from

* IMSS e ISSSTE *
* INVARIANTE (v8.1.0): los *PIB son params de interfaz NUMÉRICOS — Web.Stata.do
* los declara sin comillas y ambos flujos (local vía escalar, web vía template)
* entregan numérico; un placeholder sin sustituir truena en sintaxis, visible —
* NO reintroducir real() ni comillas.
set obs `=_N+1'
replace from = 99 in -1
replace profile = (IMSSPIB+ISSSTEPIB)/100*scalar(pibY) in -1
if `"`entidad'"' != "" replace profile = profile*`eshare1' in -1
replace to = 99 in -1
label define to 99 "Empresas públicas", add
label define `1' 99 "IMSS, ISSSTE", add

/* CFE *
set obs `=_N+1'
replace from = 98 in -1
replace profile = CFEPIB/100*scalar(pibY) in -1
replace to = 99 in -1
label define `1' 98 "CFE", add

* Pemex */
set obs `=_N+1'
replace from = 97 in -1
replace profile = (PEMEXPIB+CFEPIB)/100*scalar(pibY) in -1
if `"`entidad'"' != "" replace profile = profile*`eshare1' in -1
replace to = 99 in -1
label define `1' 97 "Pemex, CFE", add

* FMP *
set obs `=_N+1'
replace from = 97 in -1
replace profile = FMPPIB/100*scalar(pibY) in -1
if `"`entidad'"' != "" replace profile = profile*`eshare1' in -1
replace to = 100 in -1
label define to 100 "FMP", add

* TOTAL *
tabstat profile, stat(sum) f(%20.0fc) save
tempname ingtot
matrix `ingtot' = r(StatTotal)

tempfile eje1
save `eje1'




********************
** Eje 4: Consumo **
use `"${SIMROOT}/users/$id/aportaciones.dta"', clear
if `"`entidad'"' != "" {
	_SFentidad `eclave' `1'
	tempfile sellos4
	_SFsellos, corte(`1') fams(`fams4') sufs(`sufs4') clave(`eclave') aparte(0) ///
		vintages(`vintages') nacvig(`nacvig4') sellon(`sello_n') sellotop1(`sello_top1') out(`sellos4') idv($id)
}

tabstat factor, stat(sum) f(%20.0fc) save
tempname pobenigh
matrix `pobenigh' = r(StatTotal)

tabstat factor if edad >= 65, stat(sum) f(%20.0fc) save
tempname pobpenbien
matrix `pobpenbien' = r(StatTotal)

tabstat factor, stat(sum) f(%20.0fc) save
tempname pobtot
matrix `pobtot' = r(StatTotal)

* Pensiones de aportaciones.dta YA incluye Pensión_AM: SIM.do §7.2 la suma una vez
* antes de guardar la base (y Web.Stata.do hace lo mismo en la vía web). Hasta v8.8.1
* esta línea la volvía a sumar: el nodo "Pensiones" del Sankey (3,002,971.1 mdp, PE 2027)
* excedía en exactamente `pam` (1.474 % del PIB = 581,042.2 mdp) al gasto parametrizado
* en SIM.do §5.1, y el enlace residual de endeudamiento cargaba el mismo exceso contra el
* financiamiento de la ILIF 2027. Prueba de endeudamiento del 2026-10-10
* (diag-pivote-entidad-2026-10-10/prueba-pam/); corrección en v8.8.2 (CHANGELOG). *

collapse (sum) gas_Educación=Educacion gas_Salud=Salud /*gas__Salarios_de_gobierno=Salarios*/ ///
	gas___Pensiones=Pensiones gas____Transferencias=IngBasico ///
	gas____Inversión=OtrasInversiones [fw=factor], by(`1')

levelsof `1', local(`1')
foreach k of local `1' {
	local oldlabel : label (`1') `k'
	label define `1' `k' "_`oldlabel'", modify
}

* from *
tempvar from
reshape long gas_, i(`1') j(`from') string
if `"`entidad'"' != "" {
	preserve
	use `sellos4', clear
	rename key `from'
	save `sellos4', replace
	restore
	merge 1:1 `1' `from' using `sellos4', nogen keep(master match)
}
rename gas_ profile
encode `from', g(from)

* to *
rename `1' to

* Costo de la deuda *
set obs `=_N+5'

replace from = 97 in -1
label define from 97 "Costo de la deuda", add

replace profile = scalar(gascostoPC)*`pobtot'[1,1] in -1

replace to = 14 in -1
label define `1' 14 "Sistema financiero", add

* Aportaciones y participaciones *
replace from = 94 in -2
label define from 94 "Part y otras Aport", add

replace profile = scalar(gasfederPC)*`pobtot'[1,1] in -2

replace to = 12 in -2
label define `1' 12 "Estados y municipios", add

* Otros *
replace from = 95 in -3
label define from 95 "Otros gastos", add

replace profile = scalar(gasotrosPC)*`pobtot'[1,1] in -3

replace to = 13 in -3
label define `1' 13 "No distribuibles", add

* Energía *
replace from = 96 in -4
label define from 96 "Energía", add

replace profile = (scalar(gaspemexPC)+scalar(gascfePC)+scalar(gassenerPC)+scalar(gasinverfPC))*`pobtot'[1,1] in -4

replace to = 11 in -4
label define `1' 11 "CFE Pemex SENER", add

* Costo de la deuda energía *
replace from = 96 in -5

replace profile = scalar(gascosdeuePC)*`pobtot'[1,1] in -5

replace to = 14 in -5

* Entidad: renglones per cápita × población ENIGH de la entidad (fórmula actual) u omitidos (S-P3) *
if `"`entidad'"' != "" replace profile = profile*`eshare4' in -5/-1


* Gasto total */
tabstat profile, stat(sum) f(%20.0fc) save
tempname gastot
matrix `gastot' = r(StatTotal)

sort from to
tempfile eje4
save `eje4'




********************
** DEUDA o AHORRO **
if `gastot'[1,1]-`ingtot'[1,1] > 0 {
	use `eje1', clear

	set obs `=_N+1'

	replace from = 101 in -1
	replace profile = (`gastot'[1,1]-`ingtot'[1,1]) in -1
	replace to = 101 in -1

	label define `1' 101 "Futuro", add
	label define to 101 "Endeudamiento", add

	save `eje1', replace
}
else {
	use `eje4', clear

	set obs `=_N+1'

	replace from = 102 in -1
	replace profile = (`ingtot'[1,1]-`gastot'[1,1]) in -1
	replace to = 15 in -1

	label define `1' 15 "Futuro", add
	label define from 102 "Ahorro", add

	save `eje4', replace
}




********************
** Eje 2: Total 1 **
use `eje1', clear
collapse (sum) profile, by(to)
rename to from

g to = 999
label define PIB 999 "$paqueteEconomico"
label values to PIB

tempfile eje2
save `eje2'




********************
** Eje 3: Total 2 **
use `eje4', clear
collapse (sum) profile, by(from)
rename from to

g from = 999
label define PIB 999 "$paqueteEconomico"
label values from PIB

tempfile eje3
save `eje3'




************
** Sankey **
if `"`entidad'"' != "" {
	* Metadatos del JSON de entidad (sin espacios ni paréntesis: "_" = espacio tras el filtro de SankeySumSim) *
	local meta `"entidad:{nombre:"`=subinstr(`"`enombre'"', " ", "_", .)'",clave:"`eclave'",abrev:"`eabrev'",corte:"`1'`=cond("`1'" == "quintil", "_estatal", "")'",anio:"`2'",pobEnt:"`pobent'",pobNac:"`pobnac'",macro:"`macro_regla'",cuotas:"`=cond(`cuotas_aparte', "aparte", "en_Imp_al_trabajo")'",selloN:"`sello_n'",selloTop1:"`sello_top1'",vintages:"`=subinstr(trim("`vint_usados'"), " ", "_", .)'",vintagesOmitidos:"`=subinstr(trim("`vint_omitidos'"), " ", "_", .)'",celdas:[`celdas']}"'
	local sankey_extra `"folder(`eabrev') meta(`"`meta'"')"'
}
noisily SankeySumSim, anio(`2') name(`1') a(`eje1') b(`eje2') c(`eje3') d(`eje4') `sankey_extra'

timer off 9
timer list 9
noisily di _newline in g "Tiempo: " in y round(`=r(t9)/r(nt9)',.1) in g " segs."
