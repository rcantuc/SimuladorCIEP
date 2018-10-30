*****************
**** MODULOS ****
*****************

if "`1'" == "" {
	local 1 "PE2018"
	local 2 "$anioVP"
}




***********
*** PIB ***
***********
PIBDeflactor, id(`1')
tempfile PIB
save `PIB'




****************
*** INGRESOS ***
****************
LIF, base
merge m:1 (anio) using `PIB', nogen keep(matched)


** Impuestos al ingreso **
replace recaudacion = scalar(sISR__as)/100*pibY if modulo == "rec_ISR__asalariados1" & anio >= `2'
replace recaudacion = scalar(sCuotasT)/100*pibY if modulo == "rec_CuotasT1" & anio >= `2'

tempvar isrftot isrmtot
egen `isrftot' = sum(recaudacion) if modulo == "rec_ISR__PF1" & anio >= `2'
replace recaudacion = scalar(sISR__PF)/100*pibY*recaudacion/`isrftot' if modulo == "rec_ISR__PF1" & anio >= `2'

egen `isrmtot' = sum(recaudacion) if modulo == "rec_ISR__PM1" & anio >= `2'
replace recaudacion = scalar(sISR__PM)/100*pibY*recaudacion/`isrmtot' if modulo == "rec_ISR__PM1" & anio >= `2'


** Impuestos al consumo **
replace recaudacion = scalar(sIVA)/100*pibY if modulo == "rec_IVA2" & anio >= `2'

tempvar iepstot
egen `iepstot' = sum(recaudacion) if (modulo == "rec_IEPS__n2" | modulo == "rec_IEPS__p2") & anio >= `2'
replace recaudacion = scalar(sIEPS)/100*pibY*recaudacion/`iepstot' if (modulo == "rec_IEPS__n2" | modulo == "rec_IEPS__p2") & anio >= `2'

replace recaudacion = scalar(sISAN)/100*pibY if modulo == "rec_ISAN2" & anio >= `2'
replace recaudacion = scalar(sImporta)/100*pibY if modulo == "rec_Importaciones2" & anio >= `2'


** Impuestos al capital **
tempvar fmptot oyetot
egen `fmptot' = sum(recaudacion) if modulo == "rec_FMP_Derechos" & anio >= `2'
replace recaudacion = scalar(sFMP_Der)/100*pibY*recaudacion/`fmptot' if modulo == "rec_FMP_Derechos" & anio >= `2'

egen `oyetot' = sum(recaudacion) if (modulo == "rec_IMSSISSSTE4" | modulo == "rec_Pemex5" | modulo == "rec_CFE_PF5") & anio >= `2'
replace recaudacion = scalar(sOYE)/100*pibY*recaudacion/`oyetot' if (modulo == "rec_IMSSISSSTE4" | modulo == "rec_Pemex5" | modulo == "rec_CFE_PF5") & anio >= `2'

** Guardar base `id' **
capture drop __*
save "`c(sysdir_personal)'/users/`1'/LIF", replace




**************
*** GASTOS ***
**************
PEF, base

set obs `=_N+2'
replace anio = 2018 in -2/-1
replace neto = 0 in -2/-1
foreach k of varlist ramo-fuente {
	capture confirm numeric variable `k'
	if _rc == 0 {
		replace `k' = -2 in -1
		replace `k' = -3 in -2
	}
	else {
		replace `k' = "Ingreso b${a}sico" in -1
		replace `k' = "Reducci${o}n del gasto" in -2
	}
	label define `k' -2 "Ingreso b${a}sico", add
	label define `k' -3 "Reducci${o}n del gasto", add
}
merge m:1 (anio) using `PIB', nogen keep(matched)


** B${a}sico **
replace gasto = scalar(singbas)/100*pibY if ramo == -2
replace gastoneto = scalar(singbas)/100*pibY if ramo == -2
replace modulo = "uso_IngBasi0" if ramo == -2


** Reducci${o}n al gasto **
*tempvar redgas
*replace gasto = scalar(redgast)/100*pibY if ramo == -3


** Educaci${o}n **
tempvar basicatot mediastot superitot posgratot

egen `basicatot' = sum(gasto) if modulo == "uso_Educaci2" ///
	& desc_subfuncion == 29 ///
	& anio >= `2'
replace gasto = scalar(sbasica)/100*pibY*gasto/`basicatot' if modulo == "uso_Educaci2" ///
	& desc_subfuncion == 29 ///
	& anio >= `2'

egen `mediastot' = sum(gasto) if modulo == "uso_Educaci2" ///
	& desc_subfuncion == 30 ///
	& anio >= `2'
replace gasto = scalar(smedias)/100*pibY*gasto/`mediastot' if modulo == "uso_Educaci2" ///
	& desc_subfuncion == 30 ///
	& anio >= `2'

egen `superitot' = sum(gasto) if modulo == "uso_Educaci2" ///
	& desc_subfuncion == 31 ///
	& anio >= `2'
replace gasto = scalar(ssuperi)/100*pibY*gasto/`superitot' if modulo == "uso_Educaci2" ///
	& desc_subfuncion == 31 ///
	& anio >= `2'

egen `posgratot' = sum(gasto) if modulo == "uso_Educaci2" ///
	& desc_subfuncion == 66 ///
	& anio >= `2'
replace gasto = scalar(sposgra)/100*pibY*gasto/`posgratot' if modulo == "uso_Educaci2" ///
	& desc_subfuncion == 66 ///
	& anio >= `2'


** Pensiones **
tempvar pamtot penimsstot penissstetot penpemextot pencfetot penlfctot

egen `pamtot' = sum(gasto) if modulo == "uso_Pension1" ///
	& ramo == 20 ///
	& anio >= `2'
replace gasto = scalar(spam)/100*pibY*gasto/`pamtot' if modulo == "uso_Pension1" ///
	& ramo == 20 ///
	& anio >= `2'

egen `penimsstot' = sum(gasto) if modulo == "uso_Pension1" ///
	& ramo == 50 ///
	& anio >= `2'
replace gasto = scalar(spenims)/100*pibY*gasto/`penimsstot' if modulo == "uso_Pension1" ///
	& ramo == 50 ///
	& anio >= `2'

egen `penissstetot' = sum(gasto) if modulo == "uso_Pension1" ///
	& ramo == 51 ///
	& anio >= `2'
replace gasto = scalar(speniss)/100*pibY*gasto/`penissstetot' if modulo == "uso_Pension1" ///
	& ramo == 51 ///
	& anio >= `2'

egen `penpemextot' = sum(gasto) if modulo == "uso_Pension1" ///
	& ramo == 52 ///
	& anio >= `2'
replace gasto = scalar(spenpem)/100*pibY*gasto/`penpemextot' if modulo == "uso_Pension1" ///
	& ramo == 52 ///
	& anio >= `2'

egen `pencfetot' = sum(gasto) if modulo == "uso_Pension1" ///
	& ramo == 53 ///
	& anio >= `2'
replace gasto = scalar(spencfe)/100*pibY*gasto/`pencfetot' if modulo == "uso_Pension1" ///
	& ramo == 53 ///
	& anio >= `2'

egen `penlfctot' = sum(gasto) if modulo == "uso_Pension1" ///
	& ramo == 19 ///
	& anio >= `2'
replace gasto = scalar(spenlfc)/100*pibY*gasto/`penlfctot' if modulo == "uso_Pension1" ///
	& ramo == 19 ///
	& anio >= `2'


** Salud **
tempvar ssatot segpoptot imsstot issstetot imssprosperatot pemextot

egen `segpoptot' = sum(gasto) if modulo == "uso_Salud3" ///
	& (ramo == 33 | desc_pp == 1343) ///
	& anio >= `2'
replace gasto = scalar(ssegpop)/100*pibY*gasto/`segpoptot' if modulo == "uso_Salud3" ///
	& (ramo == 33 | desc_pp == 1343) ///
	& anio >= `2'
	
egen `imssprosperatot' = sum(gasto) if modulo == "uso_Salud3" ///
	& (pp == 38) ///
	& anio >= `2'
replace gasto = scalar(sprospe)/100*pibY*gasto/`imssprosperatot' if modulo == "uso_Salud3" ///
	& (pp == 38) ///
	& anio >= `2'

egen `ssatot' = sum(gasto) if modulo == "uso_Salud3" ///
	& ramo == 12 & (pp != 38 & desc_pp != 1343) ///
	& anio >= `2'
replace gasto = scalar(sssa)/100*pibY*gasto/`ssatot' if modulo == "uso_Salud3" ///
	& ramo == 12 & (pp != 38 & desc_pp != 1343) ///
	& anio >= `2'

egen `imsstot' = sum(gasto) if modulo == "uso_Salud3" ///
	& ramo == 50 & (pp != 38 & desc_pp != 1343) ///
	& anio >= `2'
replace gasto = scalar(simss)/100*pibY*gasto/`imsstot' if modulo == "uso_Salud3" ///
	& ramo == 50 & (pp != 38 & desc_pp != 1343) ///
	& anio >= `2'

egen `issstetot' = sum(gasto) if modulo == "uso_Salud3" ///
	& ramo == 51 & (pp != 38 & desc_pp != 1343) ///
	& anio >= `2'
replace gasto = scalar(sissste)/100*pibY*gasto/`issstetot' if modulo == "uso_Salud3" ///
	& ramo == 51 & (pp != 38 & desc_pp != 1343) ///
	& anio >= `2'

egen `pemextot' = sum(gasto) if modulo == "uso_Salud3" ///
	& (ramo == 7 | ramo == 13 | ramo == 52) ///
	& anio >= `2'
replace gasto = scalar(spemex)/100*pibY*gasto/`pemextot' if modulo == "uso_Salud3" ///
	& (ramo == 7 | ramo == 13 | ramo == 52) ///
	& anio >= `2'


** Otros gastos **
tempvar servpers matesumi gastgene substran bienmueb obrapubl invefina partapor deudpubl

egen `servpers' = sum(gastoneto) if modulo == "" & neto == 0 ///
	& (capitulo == 1) ///
	& anio >= `2'
replace gastoneto = scalar(servpers)/100*pibY*gastoneto/`servpers' if modulo == "" & neto == 0 ///
	& (capitulo == 1) ///
	& anio >= `2'
	
egen `matesumi' = sum(gastoneto) if modulo == "" & neto == 0 ///
	& (capitulo == 2) ///
	& anio >= `2'
replace gastoneto = scalar(matesumi)/100*pibY*gastoneto/`matesumi' if modulo == "" & neto == 0 ///
	& (capitulo == 2) ///
	& anio >= `2'
	
egen `gastgene' = sum(gastoneto) if modulo == "" & neto == 0 ///
	& (capitulo == 3) ///
	& anio >= `2'
replace gastoneto = scalar(gastgene)/100*pibY*gastoneto/`gastgene' if modulo == "" & neto == 0 ///
	& (capitulo == 3) ///
	& anio >= `2'
	
egen `substran' = sum(gastoneto) if modulo == "" & neto == 0 ///
	& (capitulo == 4) ///
	& anio >= `2'
replace gastoneto = scalar(substran)/100*pibY*gastoneto/`substran' if modulo == "" & neto == 0 ///
	& (capitulo == 4) ///
	& anio >= `2'
	
egen `bienmueb' = sum(gastoneto) if modulo == "" & neto == 0 ///
	& (capitulo == 5) ///
	& anio >= `2'
replace gastoneto = scalar(bienmueb)/100*pibY*gastoneto/`bienmueb' if modulo == "" & neto == 0 ///
	& (capitulo == 5) ///
	& anio >= `2'
	
egen `obrapubl' = sum(gastoneto) if modulo == "" & neto == 0 ///
	& (capitulo == 6) ///
	& anio >= `2'
replace gastoneto = scalar(obrapubl)/100*pibY*gastoneto/`obrapubl' if modulo == "" & neto == 0 ///
	& (capitulo == 6) ///
	& anio >= `2'
	
egen `invefina' = sum(gastoneto) if modulo == "" & neto == 0 ///
	& (capitulo == 7) ///
	& anio >= `2'
replace gastoneto = scalar(invefina)/100*pibY*gastoneto/`invefina' if modulo == "" & neto == 0 ///
	& (capitulo == 7) ///
	& anio >= `2'
	
egen `partapor' = sum(gastoneto) if modulo == "" & neto == 0 ///
	& (capitulo == 8) ///
	& anio >= `2'
replace gastoneto = scalar(partapor)/100*pibY*gastoneto/`partapor' if modulo == "" & neto == 0 ///
	& (capitulo == 8) ///
	& anio >= `2'

egen `deudpubl' = sum(gastoneto) if modulo == "" & neto == 0 ///
	& (capitulo == 9) ///
	& anio >= `2'
replace gastoneto = scalar(deudpubl)/100*pibY*gastoneto/`deudpubl' if modulo == "" & neto == 0 ///
	& (capitulo == 9) ///
	& anio >= `2'



	
************************
*** Guardar base `1' ***
************************
replace gastoneto = gasto - gastoCUOTAS if modulo != "" & anio >= `2' & ramo != -2
replace gasto = gastoneto + gastoCUOTAS if modulo == "" & neto == 0 & anio >= `2' & ramo != -2
capture drop __*
save "`c(sysdir_personal)'/users/`1'/PEF", replace
