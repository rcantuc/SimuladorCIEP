program define CuentasGeneracionales, rclass
quietly {
	timer on 10
	version 13.1

	** Anio valor presente **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	syntax varname [, ANIObase(int `aniovp') BOOTstrap(int 1) Graphs POST DIScount(real 3)]

	noisily di _newline(2) in g _dup(20) "." "{bf:   Cuentas Generacionales " in y "$pais" `aniobase' "   }" in g _dup(20) "."
	local title : variable label `varlist'



	*******************************
	*** 0 Guardar base original ***
	*******************************
	*preserve



	*******************
	*** 1 Poblacion ***
	*******************
	use `"`c(sysdir_site)'/04_master/Poblacion.dta"', clear

	sort anio
	local anio = anio[1]
	local aniofin = anio[_N]
	local edadmax = edad[_N]+1

	keep if anio >= `aniobase' & entidad == "Nacional"
	keep poblacion edad sexo anio
	
	reshape wide poblacion, i(edad sexo) j(anio)

	mkmat poblacion* if sexo == 1, matrix(HOM)
	mata: HOM = st_matrix("HOM")
	mkmat poblacion* if sexo == 2, matrix(MUJ)
	mata: MUJ = st_matrix("MUJ")

	mata: lambda = `=scalar(llambda)'


	
	****************
	** 2 Perfiles **
	****************
	use `"`c(sysdir_site)'/users/$pais/$id/bootstraps/`bootstrap'/`varlist'PERF"', clear
	collapse perfil1 perfil2 contribuyentes1 contribuyentes2, by(edad)

	sort edad
	mkmat perfil1 perfil2, matrix(PERFIL)
	mkmat contribuyentes1 contribuyentes2, matrix(CONT)

	mata: PERFIL = st_matrix("PERFIL")
	mata: CONTBEN = st_matrix("CONT")



	**************************
	*** 3 Monto per capita ***
	**************************
	use `"`c(sysdir_site)'/users/$pais/$id/bootstraps/`bootstrap'/`varlist'PC"', clear

	ci montopc
	local montopc = r(mean)

	ci edad39
	local edad39 = r(mean)

	if `edad39' == . | `edad39' == 0 {
		local pc = `montopc'
	}
	else {
		local pc = `edad39'
	}

	mata: PC = `pc'



	*****************************
	*** 4 Proyecciones Modulo ***
	*****************************
	mata GA = J(`edadmax',3,0)
	forvalues edad = 1(1)`edadmax' {
		forvalues row = 1(1)`edadmax' {
			forvalues col = 1(1)`edadmax' {
				if `row' == `col'+`edad'-1 {
					if `col' <= `aniofin'-`aniobase'+1 {
						mata GA[`edad',1] = GA[`edad',1] + ///
							PERFIL[`row',1] :* HOM[`row',`col'] * PC * ///
							(1 + lambda[1,1]/100)^(`col'-1) / (1 + `discount'/100)^(`col'-1)
						mata GA[`edad',2] = GA[`edad',2] + ///
							PERFIL[`row',2] :* MUJ[`row',`col'] * PC * ///
							(1 + lambda[1,1]/100)^(`col'-1) / (1 + `discount'/100)^(`col'-1)
					}
					else {
						mata GA[`edad',1] = GA[`edad',1] + ///
							PERFIL[`row',1] :* HOM[`row',`=`aniofin'-`aniobase'+1'] * PC * ///
							(1 + lambda[1,1]/100)^(`col'-1) / (1 + `discount'/100)^(`col'-1)
						mata GA[`edad',2] = GA[`edad',2] + ///
							PERFIL[`row',2] :* MUJ[`row',`=`aniofin'-`aniobase'+1'] * PC * ///
							(1 + lambda[1,1]/100)^(`col'-1) / (1 + `discount'/100)^(`col'-1)
					}
				}
			}
		}
	}
	mata GA[.,3] = (GA[.,1] + GA[.,2]) :/ (HOM[.,1] + MUJ[.,1])
	mata GA[.,1] = GA[.,1] :/ HOM[.,1] 
	mata GA[.,2] = GA[.,2] :/ MUJ[.,1]


	** a Stata **
	mata: st_matrix("GA",GA)

	levelsof edad, local(edades)
	noisily di _newline in g " Edad" ///
		_column(10) %20s "Hombres" ///
		_column(20) %20s "Mujeres" ///
		_column(30) %20s "Total"
	forvalues k = 0(5)`=`edadmax'-1' {
		noisily di in g _col(3) "`k'" _cont
		noisily di in g _column(10) in y %20.0fc GA[`k'+1,1] _cont
		noisily di in g _column(20) in y %20.0fc GA[`k'+1,2] _cont
		noisily di in g _column(30) in y %20.0fc GA[`k'+1,3]
	}





	**************
	*** OUTPUT ***
	**************
	if "$textbook" == "textbook" {
		local i = 1
		forvalues k = 0(5)`=`edadmax'-1' {
				local GAH = "`GAH' `=string(GA[`k'+1,1],"%20.0f")',"
				local GAM = "`GAM' `=string(GA[`k'+1,2],"%20.0f")',"
				local GAT = "`GAT' `=string(GA[`k'+1,3],"%20.0f")',"

				local letter = char(64 + `i')
				scalar GAH`letter' = string(GA[`k'+1,1],"%20.0fc")
				scalar GAM`letter' = string(GA[`k'+1,2],"%20.0fc")
				scalar GAT`letter' = string(GA[`k'+1,3],"%20.0fc")
				local i = `i' + 1
		}

		local lenghtGAH = strlen("`GAH'")
		local lenghtGAM = strlen("`GAM'")
		local lenghtGAT = strlen("`GAT'")
		noisily di in w _col(3) "GAH: [`=substr("`GAH'",1,`=`lenghtGAH'-1')']"
		noisily di in w _col(3) "GAM: [`=substr("`GAM'",1,`=`lenghtGAM'-1')']"
		noisily di in w _col(3) "GAT: [`=substr("`GAT'",1,`=`lenghtGAT'-1')']"
	}





	***************
	*** 5 Final ***
	***************
	*restore

	timer off 10
	timer list 10
	noisily di _newline in g "  {bf:Cuentas Generacionales de `title' time}: " in y round(`=r(t10)/r(nt10)',.1) in g " segs."
}
end
