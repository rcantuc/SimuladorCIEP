program define CuentasGeneracionales, rclass
quietly {
	version 13.1
	syntax varname, POBlacion(string) ANIObase(int) [BOOTstrap(int 1) Graphs POST]

	noisily di _newline in y "  CuentasGeneracionales.ado"




	********************************
	*** 0. Guardar base original ***
	********************************
	preserve




	********************
	*** 1. Poblacion ***
	********************
	capture confirm file `"`c(sysdir_personal)'/bases/SIM/Poblacion/`poblacion'`c(os)'.dta"'
	if _rc != 0 {
		if `"`=upper("`poblacion'")'"' == "POBLACION" | `"`=upper("`poblacion'")'"' == "DEFUNCIONES" {
			run "`c(sysdir_personal)'/bases/CONAPO/Poblacion.do"
		}
	}

	if "$entidad" == "" {
		local entidad = "Nacional"
	}
	else {
		local entidad = "$entidad"
	}
	use if entidad == "`entidad'" using `"`c(sysdir_personal)'/bases/SIM/Poblacion/`poblacion'`c(os)'.dta"', clear

	sort anio
	local anio = anio in 1
	keep if anio >= $anioVP
	
	reshape wide `poblacion', i(edad sexo ent) j(anio)

	mkmat `poblacion'* if sexo == 1, matrix(HOM)
	mata: HOM = st_matrix("HOM")
	mkmat `poblacion'* if sexo == 2, matrix(MUJ)
	mata: MUJ = st_matrix("MUJ")




	******************************
	*** 2. Proyecciones Modulo ***
	******************************
	mata GA = J(110,2,0)
	forvalues edad = 1(1)110 {
		forvalues row = 1(1)110 {
			forvalues col = 1(1)110 {
				if `row' == `col'+`edad'-1 {
					if `col' <= 2030-$anioVP+1 {
						mata GA[`edad',1] = GA[`edad',1] + ///
							PERFIL[`row',1] :* HOM[`row',`col'] * PC * ///
							(1 + ${pib$anioVP}/100)^(`col'-1) / (1 + ${def$anioVP}/100)^(`col'-1)
						mata GA[`edad',2] = GA[`edad',2] + ///
							PERFIL[`row',2] :* MUJ[`row',`col'] * PC * ///
							(1 + ${pib$anioVP}/100)^(`col'-1) / (1 + ${def$anioVP}/100)^(`col'-1)
						*if `edad' == 5 {
						*	noisily di "EDAD: " `edad' ", ROW: " `row' ", COL: " `col'
						*	noisily di "Anio: " 2017+`col'
						*	noisily mata GA[`edad',1] :/ HOM[`row',`col']
						*	noisily di (1 + ${pib$anioVP}/100)^(`col'-1) / (1 + ${def$anioVP}/100)^(`col'-1)
						*}
					}
					else {
						mata GA[`edad',1] = GA[`edad',1] + ///
							PERFIL[`row',1] :* HOM[`row',`=2030-$anioVP+1'] * PC * ///
							(1 + ${pib$anioVP}/100)^(`col'-1) / (1 + ${def$anioVP}/100)^(`col'-1)
						mata GA[`edad',2] = GA[`edad',2] + ///
							PERFIL[`row',2] :* MUJ[`row',`=2030-$anioVP+1'] * PC * ///
							(1 + ${pib$anioVP}/100)^(`col'-1) / (1 + ${def$anioVP}/100)^(`col'-1)
						*if `edad' == 5 {
						*	noisily di "EDAD: " `edad' ", ROW: " `row' ", COL: " `col'
						*	noisily di "Anio: " 2017+`col'
						*	noisily mata GA[`edad',1] :/ HOM[`row',`=2030-$anioVP+1']
						*	noisily di (1 + ${pib$anioVP}/100)^(`col'-1) / (1 + ${def$anioVP}/100)^(`col'-1)
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
