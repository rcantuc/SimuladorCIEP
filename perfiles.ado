program define perfiles
quietly {
	version 13.1
	syntax varname [if/] [fweight/] , MONTOpc(real) [Kernel Graphs POST]

	noisily di _newline in y "  perfiles.ado"



	********************************
	*** 0. Guardar base original ***
	********************************
	preserve
	use if entidad == "Nacional" using `"`c(sysdir_personal)'/SIM/$pais/Poblacion.dta"', clear
	local edadmax = edad[_N]
	restore
	preserve



	****************************
	*** 1 Variables internas ***
	****************************
	sort edad
	local edadmaxEncuesta = edad[_N]
	local title : variable label `varlist'

	tempvar pob for rec
	g double `pob' = 1

	if "`if'" != "" {
		g double `for' = `if'
		g double `rec' = `varlist' if `if'
	}
	else {
		g double `for' = 1
		g double `rec' = `varlist'
	}



	******************
	*** 2 Collapse ***
	******************
	replace edad = `edadmax' if edad > `edadmax' & edad != . 		// Por si hay observaciones mayores a `edadmax' (PoblacionBase.ado).
	collapse (sum) `rec' `pob' `for' [`weight' = `exp'], by(sexo edad)


	*********************
	** 2.1 Recaudacion **
	tempname REC
	tabstat `rec', stat(sum) f(%25.2fc) save
	matrix `REC' = r(StatTotal)


	************************
	** 2.2 Contribuyentes **
	tempname FOR
	tabstat `for', stat(sum) f(%12.0fc) save
	matrix `FOR' = r(StatTotal)


	*******************
	** 2.3 Poblacion **
	tempname POB
	tabstat `pob', stat(sum) f(%12.0fc) save
	matrix `POB' = r(StatTotal)


	**************************
	** 2.4 Completar edades **
	destring sexo, replace

	* Observaciones no encontradas *
	sort sexo edad
	forvalues k=0(1)`edadmax' {						// Edades segun PoblacionBase.ado
		forvalues j=1(1)2 {
			count if edad == `k' & sexo == `j'
			if r(N) == 0 {
				set obs `=_N+1'
				replace edad = `k' in -1
				replace sexo = `j' in -1
			}
		}
	}



	****************/
	*** 3 Reshape ***
	*****************
	keep `rec' `for' `pob' edad sexo
	reshape wide `rec' `for' `pob', i(edad) j(sexo)


	************************
	** 3.1 Perfil de pago **
	tsset edad
	tempvar perfil1 perfil2
	g double `perfil1' = `rec'1/`for'1/`montopc'
	g double `perfil2' = `rec'2/`for'2/`montopc'
	replace `perfil1' = L.`perfil1' if `perfil1' == . & edad >= `edadmaxEncuesta'-5
	replace `perfil2' = L.`perfil2' if `perfil2' == . & edad >= `edadmaxEncuesta'-5
	replace `perfil1' = 0 if `perfil1' == .
	replace `perfil2' = 0 if `perfil2' == .


	*********************************
	** 3.2 Perfil de participacion **
	tempvar pcont1 pcont2
	g double `pcont1' = `for'1/`pob'1*100
	g double `pcont2' = `for'2/`pob'2*100
	replace `pcont1' = L.`pcont1' if `pcont1' == . & edad >= `edadmaxEncuesta'-5
	replace `pcont2' = L.`pcont2' if `pcont2' == . & edad >= `edadmaxEncuesta'-5
	replace `pcont1' = 0 if `pcont1' == .
	replace `pcont2' = 0 if `pcont2' == .



	*********************************
	*** 4 Guardar resultados POST ***
	*********************************
	if "`post'" == "post" {
		forvalues k=1(1)`=_N' {
			post PERF (edad[`k']) (`perfil1'[`k']) (`perfil2'[`k']) (`pcont1'[`k']) (`pcont2'[`k']) ///
				(`rec'1[`k']) (`rec'2[`k']) (`for'1[`k']) (`for'2[`k']) (`pob'1[`k']) (`pob'2[`k'])
		}
	}


	****************
	** 4.1 A Mata **
	sort edad
	mkmat `perfil1' `perfil2', matrix(PERFIL)
	mkmat `pcont1' `pcont2', matrix(CONT)

	mata: PERFIL = st_matrix("PERFIL")
	mata: CONTBEN = st_matrix("CONT")



	******************
	*** 5 Regresar ***
	******************
	restore
}
end
