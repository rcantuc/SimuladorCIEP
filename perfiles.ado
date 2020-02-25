program define perfiles
quietly {
	version 13.1
	syntax varname [if/] [fweight/] , MONTOpc(real) [Kernel Graphs POST]

	noisily di _newline in y "  perfiles.ado"



	********************************
	*** 0. Guardar base original ***
	********************************
	preserve
	use`"`c(sysdir_site)'../basesCIEP/SIM/Poblacion`=subinstr("${pais}"," ","",.)'.dta"', clear
	local edadmax = edad[_N]
	restore
	preserve


	*****************************
	*** 1. Variables internas ***
	*****************************
	sort edad
	local edadmaxEncuesta = edad[_N]
	local title : variable label `varlist'

	tempvar pob for rec
	quietly g double `pob' = 1

	if "`if'" != "" {
		g double `for' = `if'
		g double `rec' = `varlist' if `if'
	}
	else {
		g double `for' = 1
		g double `rec' = `varlist'
	}

	* Labels *
	label variable `pob' "Poblaci{c o'}n"
	label variable `for' "Contribuyentes/Beneficiarios"
	label variable `rec' "`title'"

	* Edades `edadmax'+ y collapse *
	replace edad = `edadmax' if edad > `edadmax' & edad != . 					// Si hay observaciones mayores a `edadmax' anios.
	collapse (sum) `rec' `pob' `for' [`weight' = `exp'], by(sexo edad)


	**********************
	** 1.1. Recaudacion **
	tempname REC
	tabstat `rec', stat(sum) f(%25.2fc) save
	matrix `REC' = r(StatTotal)
	*noisily di in g "  Amount (" in y `"`=upper("`varlist'")'"' in g "):" _column(40) in y %25.0fc `REC'[1,1]

	* Por edades *
	tempname REC16
	tabstat `rec' if edad < 18, stat(sum) f(%25.2fc) save
	matrix `REC16' = r(StatTotal)

	tempname REC1764
	tabstat `rec' if edad < 65 & edad >= 18, stat(sum) f(%25.2fc) save
	matrix `REC1764' = r(StatTotal)

	tempname REC65
	tabstat `rec' if edad >= 65, stat(sum) f(%25.2fc) save
	matrix `REC65' = r(StatTotal)


	*************************
	** 1.2. Contribuyentes **
	tempname FOR
	tabstat `for', stat(sum) f(%12.0fc) save
	matrix `FOR' = r(StatTotal)
	*noisily di in g "  Taxpay./Benef. (" in y `"`=upper("`varlist'")'"' in g "):" _column(40) in y %25.0fc `FOR'[1,1]

	* Por edades *
	tempname FOR16
	tabstat `for' if edad < 18, stat(sum) f(%25.2fc) save
	matrix `FOR16' = r(StatTotal)

	tempname FOR1764
	tabstat `for' if edad < 65 & edad >= 18, stat(sum) f(%25.2fc) save
	matrix `FOR1764' = r(StatTotal)

	tempname FOR65
	tabstat `for' if edad >= 65, stat(sum) f(%25.2fc) save
	matrix `FOR65' = r(StatTotal)


	********************
	** 1.3. Poblacion **
	tempname POB
	tabstat `pob', stat(sum) f(%12.0fc) save
	matrix `POB' = r(StatTotal)
	*noisily di in g "  Poblaci{c o'}n:" _column(40) in y %25.0fc `POB'[1,1]
	noisily di in g "  Per c{c a'}pita:" _column(40) in y %25.0fc `montopc'


	***************************
	** 1.4. Completar edades **
	destring sexo, replace

	/* Edades de 97 a `edadmax' *
	tabstat `rec' `for' `pob' if edad >= `edadmaxEncuesta'-8 & sexo == 1, stat(sum) save
	tempname RES1
	matrix `RES1' = r(StatTotal)
	tabstat `rec' `for' `pob' if edad >= `edadmaxEncuesta'-8 & sexo == 2, stat(sum) save
	tempname RES2
	matrix `RES2' = r(StatTotal)

	* Observaciones no encontradas */
	forvalues k=0(1)`edadmax' {									// Edades segun CONAPO
		forvalues j=1(1)2 {
			count if edad == `k' & sexo == `j'
			if r(N) == 0 {
				set obs `=_N+1'
				replace edad = `k' in -1
				replace sexo = `j' in -1
			}
		}
	}

	/* Mayores de 92 anios *
	replace `rec' = `RES1'[1,1]/(`edadmax'-`edadmaxEncuesta'-1) if edad >= `edadmaxEncuesta' & sexo == 1
	replace `for' = `RES1'[1,2]/(`edadmax'-`edadmaxEncuesta'-1) if edad >= `edadmaxEncuesta' & sexo == 1
	replace `pob' = `RES1'[1,3]/(`edadmax'-`edadmaxEncuesta'-1) if edad >= `edadmaxEncuesta' & sexo == 1

	replace `rec' = `RES2'[1,1]/(`edadmax'-`edadmaxEncuesta'-1) if edad >= `edadmaxEncuesta' & sexo == 2
	replace `for' = `RES2'[1,2]/(`edadmax'-`edadmaxEncuesta'-1) if edad >= `edadmaxEncuesta' & sexo == 2
	replace `pob' = `RES2'[1,3]/(`edadmax'-`edadmaxEncuesta'-1) if edad >= `edadmaxEncuesta' & sexo == 2

	capture drop `rect' `fort' `pobt'


	* Validation */
	tempname REC
	tabstat `rec', stat(sum) f(%25.2fc) save
	matrix `REC' = r(StatTotal)
	noisily di in g "  Monto:" _column(40) in y %25.0fc `REC'[1,1]

	tempname FOR
	tabstat `for', stat(sum) f(%12.0fc) save
	matrix `FOR' = r(StatTotal)
	noisily di in g "  Contribuyentes/Beneficiarios:" _column(40) in y %25.0fc `FOR'[1,1]

	tempname POB
	tabstat `pob', stat(sum) f(%12.0fc) save
	matrix `POB' = r(StatTotal)
	noisily di in g "  Poblaci{c o'}n:" _column(40) in y %25.0fc `POB'[1,1]



	********************
	*** 2.0. Reshape ***
	********************
	reshape wide `rec' `for' `pob', i(edad) j(sexo)


	*************************
	** 2.1. Perfil de pago **
	tempvar perfil1 perfil2
	g double `perfil1' = `rec'1/`for'1/`montopc'
	g double `perfil2' = `rec'2/`for'2/`montopc'
	replace `perfil1' = 0 if `perfil1' == .
	replace `perfil2' = 0 if `perfil2' == .

	if "`kernel'" == "kernel" {
		lpoly `perfil1' edad, generate(perfil1) at(edad) bwidth(2) nograph kernel
		lpoly `perfil2' edad, generate(perfil2) at(edad) bwidth(2) nograph kernel
	}
	else {
		g double perfil1 = `perfil1'
		g double perfil2 = `perfil2'
	}
	label variable perfil1 "{bf:Profile}: Hombres"
	label variable perfil2 "{bf:Profile}: Mujeres"


	**********************************
	** 2.2. Perfil de participacion **
	tempvar pcont1 pcont2
	quietly g double `pcont1' = `for'1/`pob'1*100
	quietly g double `pcont2' = `for'2/`pob'2*100
	quietly replace `pcont1' = 0 if `pcont1' == .
	quietly replace `pcont2' = 0 if `pcont2' == .

	if "`kernel'" == "kernel" {
		lpoly `pcont1' edad, generate(pcont1) at(edad) bwidth(2) nograph kernel
		lpoly `pcont2' edad, generate(pcont2) at(edad) bwidth(2) nograph kernel
	}
	else {
		g double pcont1 = `pcont1'
		g double pcont2 = `pcont2'
	}
	label variable pcont1 "{bf:Participation}: Hombres"
	label variable pcont2 "{bf:Participation}: Mujeres"



	************************************
	*** 3.0. Guardar resultados POST ***
	************************************
	if "`post'" == "post" {
		forvalues k=1(1)`=_N' {
			post PERF (edad[`k']) (perfil1[`k']) (perfil2[`k']) (pcont1[`k']) (pcont2[`k']) ///
				(`rec'1[`k']) (`rec'2[`k']) (`for'1[`k']) (`for'2[`k']) (`pob'1[`k']) (`pob'2[`k'])
		}
	}


	*****************
	** 3.1. A mata **
	sort edad
	mkmat perfil1 perfil2, matrix(PERFIL)
	mkmat pcont1 pcont2, matrix(CONT)

	mata: PERFIL = st_matrix("PERFIL")
	mata: CONTBEN = st_matrix("CONT")



	*********************
	*** 4.0. Regresar ***
	*********************
	restore
}
end
