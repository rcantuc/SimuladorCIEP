******************************
***                        ***
*** Población con y sin SS ***
***                        ***
******************************
global export "/Users/ricardo/Desktop"



***************
** Poblacion **
Poblacion, nographs

tempfile poblacion
save `poblacion'



*********************
** Microdatos ENOE **
*noisily run "`c(sysdir_personal)'/DownloadENOE.do"



*******************
** Archivos ENOE **
local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)
forvalues anio=2005(1)`aniovp' {
	noisily di in g "Año: " in y `anio'
	local anio2 = substr("`anio'",3,2)

	use "`c(sysdir_site)'../BasesCIEP/INEGI/ENOE/`anio'/sdemt1`anio2'.dta", clear
	g anio = `anio'
	rename eda edad
	rename sex sexo

	capture rename fac_tri fac
	collapse (sum) seg_soc [fw=fac], by(anio edad sexo)
	format seg_soc %10.0fc

	tempfile enoe1`anio'
	save `enoe1`anio''
}



***********
** Merge **
use `poblacion', clear
forvalues anio=2005(1)`aniovp' {
	merge 1:1 (anio edad sexo) using `enoe1`anio'', nogen update
	drop if eda == .

}
g prop_seg_soc = seg_soc/poblacion*100


*********************/
** Seguridad Social **
tempvar pob2
g `pob2' = -seg_soc if sexo == 1
replace `pob2' = seg_soc if sexo == 2		
format `pob2' %10.0fc

g edad2 = edad
replace edad2 = . if edad != 5 & edad != 10 & edad != 15 & edad != 20 ///
	& edad != 25 & edad != 30 & edad != 35 & edad != 40 & edad != 45 ///
	& edad != 50 & edad != 55 & edad != 60 & edad != 65 & edad != 70 ///
	& edad != 75 & edad != 80 & edad != 85 & edad != 90 & edad != 95 ///
	& edad != 100 & edad != 105
g zero = 0

forvalues anio = `aniovp'(1)`aniovp' {

	* Distribucion inicial *
	tabstat seg_soc if anio == `anio', stat(sum) f(%15.0fc) save
	tempname P`anio'
	matrix `P`anio'' = r(StatTotal)

	* X label *
	tabstat seg_soc if anio == `anio', stat(max) f(%15.0fc) by(sexo) save
	tempname MaxH MaxM
	matrix `MaxH' = r(Stat1)
	matrix `MaxM' = r(Stat2)

	local graphtitle "{bf:Población con seguridad social}"
	local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de CONAPO (2023) e INEGI/ENOE (varios años)."

	* Grafica sexo = 1 como negativos y sexo = 2 como positivos por grupos etarios, en el presente y futuro *
	twoway (bar `pob2' edad if sexo == 1 & anio == `anio', horizontal) ///
		(bar `pob2' edad if sexo == 2 & anio == `anio', horizontal) ///
		(sc edad2 zero if anio == `anio', msymbol(i) mlabel(edad2) mlabsize(vsmall) mlabcolor("114 113 118")), ///
		legend(label(1 "Hombres") label(2 "Mujeres")) ///
		legend(order(1 2) rows(1) on region(margin(zero))) ///
		yscale(noline) ylabel(none) xscale(noline) ///
		name(SegSoc_`anio', replace) ///
		xlabel(-1500000 `"`=string(1500000,"%15.0fc")'"' ///
		`=-1500000/2' `"`=string(1500000/2,"%15.0fc")'"' 0 ///
		`=1500000/2' `"`=string(1500000/2,"%15.0fc")'"' ///
		1500000 `"`=string(1500000,"%15.0fc")'"', angle(horizontal)) ///
		title(`"{bf:Población con seguridad social}"') ///
		subtitle(`"{bf:`anio'}: `=string(`P`anio''[1,1],"%20.0fc")'"') ///
		caption("`graphfuente'") ///

	graph export "$export/SegSoc_`anio'.png", replace name(SegSoc_`anio')
}


capture drop __*
compress
save "`c(sysdir_personal)'/SIM/PoblacionSegSoc.dta", replace


