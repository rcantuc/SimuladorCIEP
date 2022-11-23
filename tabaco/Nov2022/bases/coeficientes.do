********************************************************************************
*******CÃ¡lculo de Coeficientes para la InfografÃ­a de Entidades Federativas******
********************************************************************************


/*  1. Descargar las bases de datos de la recaudaciÃ³n del IEPS por entidad 
	   federativa de ESTOPOR, los datos serÃ¡n por mes y se decargarÃ¡n del 
	   Ãºltimo enero a la fecha de actualizaciÃ³n del simulador. Se utilizarÃ¡n 
	   las participaciones por (fgp, litoral, directo del 8% y ffr).
	   
	2. Se harÃ¡ una regla de tres con el total de cada participaciÃ³n para 
	   determinar el coeficiente de reparto a cada entidad.
	   
	3. Se harÃ¡ un promedio con los coeficientes existentes, por entidad 
	   federativa y por tipo de participaciÃ³n para incorporarlos al simulador. 
	   Es decir, la suma de los coeficientes de cada meses/12 */

drop _all
capture log close _all
	   
	   
*PASO 1  (AquÃ­ se puede sustituir el Excel con la descarga directa de ESTOPOR)


import excel "C:\Users\Admin\CIEP Dropbox\Leslie Badillo\SimuladorCIEP\tabaco\Nov2022\bases\coeficientes.xlsx", sheet("Stata") firstrow
	

*PASO 2
drop if cve_ent==33
local mes ene feb mar abr may jun jul ago sep oct nov dic


foreach x of varlist `mes' {
	tabstat `x' if impuesto=="fgp" , stat(sum) f(%20.10fc) save
	local tot_fgp = r(StatTotal)[1,1]
	di `tot_fgp'
	gen coef_`x'=`x'/`tot_fgp' if impuesto=="fgp"

	
	tabstat `x' if impuesto=="litoral", stat(sum) f(%20.10fc) save
	local tot_litoral = r(StatTotal)[1,1]
	di `tot_litoral'
	replace coef_`x'=`x'/`tot_litoral' if impuesto=="litoral"

	
	tabstat `x' if impuesto=="ffr", stat(sum) f(%20.10fc) save
	local tot_ffr = r(StatTotal)[1,1]
	di `tot_ffr'
	replace coef_`x'=`x'/`tot_ffr' if impuesto=="ffr"

	
	tabstat `x' if impuesto=="ffm", stat(sum) f(%20.10fc) save
	local tot_ffm = r(StatTotal)[1,1]
	di `tot_ffm'
	replace coef_`x'=`x'/`tot_ffm' if impuesto=="ffm"

	tabstat `x' if impuesto=="directo", stat(sum) f(%20.10fc) save
	local tot_directo = r(StatTotal)[1,1]
	di `tot_directo'
	replace coef_`x'=`x'/`tot_directo' if impuesto=="directo"
	
}

*PASO 3

gen fgp_estatal_1= ((coef_ene + coef_feb + coef_mar + coef_abr + coef_may + coef_jun + coef_jul + coef_ago + coef_sep)/9) if impuesto=="fgp"
















