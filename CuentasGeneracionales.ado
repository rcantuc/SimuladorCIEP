program define cuentasgeneracionales, rclass
quietly {
	version 13.1
	syntax varname, POBlacion(string) ANIObase(int) [BOOTstrap(int 1) Graphs POST]

	noisily di _newline in y "  cuentasgeneracionales.ado"




	********************************
	*** 0. Guardar base original ***
	********************************
	preserve




	********************
	*** 1. Poblacion ***
	********************
	use `"`c(sysdir_site)'../basesCIEP/SIM/`poblacion'.dta"', clear
	

	sort anio
	local anio = anio[1]
	local aniofin = anio[_N]
	local edadmax = edad[_N]+1
	keep if anio >= `aniobase'
	
	reshape wide `poblacion', i(edad sexo) j(anio)

	mkmat `poblacion'* if sexo == 1, matrix(HOM)
	mata: HOM = st_matrix("HOM")
	mkmat `poblacion'* if sexo == 2, matrix(MUJ)
	mata: MUJ = st_matrix("MUJ")
	
	mata: lambda = st_numscalar("lambda")




	******************************
	*** 2. Proyecciones Modulo ***
	******************************
	mata GA = J(`edadmax',2,0)
	forvalues edad = 1(1)`edadmax' {
		forvalues row = 1(1)`edadmax' {
			forvalues col = 1(1)`edadmax' {
				if `row' == `col'+`edad'-1 {
					if `col' <= `aniofin'-`aniobase'+1 {
						mata GA[`edad',1] = GA[`edad',1] + ///
							PERFIL[`row',1] :* HOM[`row',`col'] * PC * ///
							(1 + lambda[1,1]/100)^(`col'-1) / (1 + ${discount}/100)^(`col'-1)
						mata GA[`edad',2] = GA[`edad',2] + ///
							PERFIL[`row',2] :* MUJ[`row',`col'] * PC * ///
							(1 + lambda[1,1]/100)^(`col'-1) / (1 + ${discount}/100)^(`col'-1)
						*if `edad' == 5 {
						*	noisily di "EDAD: " `edad' ", ROW: " `row' ", COL: " `col'
						*	noisily di "Anio: " 2017+`col'
						*	noisily mata GA[`edad',1] :/ HOM[`row',`col']
						*	noisily di (1 + ${pib`aniobase'}/100)^(`col'-1) / (1 + ${def`aniobase'}/100)^(`col'-1)
						*}
					}
					else {
						mata GA[`edad',1] = GA[`edad',1] + ///
							PERFIL[`row',1] :* HOM[`row',`=2030-`aniobase'+1'] * PC * ///
							(1 + lambda[1,1]/100)^(`col'-1) / (1 + ${discount}/100)^(`col'-1)
						mata GA[`edad',2] = GA[`edad',2] + ///
							PERFIL[`row',2] :* MUJ[`row',`=2030-`aniobase'+1'] * PC * ///
							(1 + lambda[1,1]/100)^(`col'-1) / (1 + ${discount}/100)^(`col'-1)
						*if `edad' == 5 {
						*	noisily di "EDAD: " `edad' ", ROW: " `row' ", COL: " `col'
						*	noisily di "Anio: " 2017+`col'
						*	noisily mata GA[`edad',1] :/ HOM[`row',`=2030-`aniobase'+1']
						*	noisily di (1 + ${pib`aniobase'}/100)^(`col'-1) / (1 + ${def`aniobase'}/100)^(`col'-1)
						*}
					}
				}
			}
		}
	}
	mata GA[.,1] = GA[.,1] :/ HOM[.,1] 
	mata GA[.,2] = GA[.,2] :/ MUJ[.,1] 


	** 2.4 A Stata **
	mata: st_matrix("GA",GA)


	******************************
	* 3. Guardar resultados POST *
	if "`post'" == "post" {
		forvalues k=1(1)`=rowsof(GA)' {
			post GA (1) (`=`k'-1') (GA[`k',1])
			post GA (2) (`=`k'-1') (GA[`k',2])
		}
	}



	***************
	** 4.0 Final **
	restore
}
end
