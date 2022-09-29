******************************
*** 3. Tasas de mortalidad ***
******************************
if "$pais" == "" & (`tm2044' != -1 | `tm4564' != -1 | `tm65' != -1 | `tf' != -1) {
	if `tm2044' != -1 {
		replace defunciones = defunciones*(1+`tm2044'/100) if edad >= 20 & edad <= 44
	}
	
	if `tm4564' != -1 {
		replace defunciones = defunciones*(1+`tm4564'/100) if edad >= 45 & edad <= 64	
	}
	
	if `tm65' != -1 {
		replace defunciones = defunciones*(1+`tm65'/100) if edad >= 65		
	}

	g tasamortalidad = defunciones/poblacion*100
	replace tasamortalidad = 100 if tasamortalidad >= 100
	label var tasamortalidad "Porcentaje de muertes"

	reshape wide poblacion defunciones tasamortalidad *migrantes, i(anio edad) j(sexo)
	xtset edad anio
	g difTF = tasafecundidad-L.tasafecundidad

	if `tf' != -1 {
		replace tasafecundidad = `tf' if anio == 2020
	}
	replace tasafecundidad = L.tasafecundidad + difTF if anio > 2020

	g nacimientosSIM = mujeresfert*tasafecundidad/1000 if edad == 0
	drop mujeresfert tasafecundidad difTF

	g poblacionSIM1 = nacimientosSIM*poblacion1/(poblacion1+poblacion2) if edad == 0
	g poblacionSIM2 = nacimientosSIM*poblacion2/(poblacion1+poblacion2) if edad == 0

	xtset anio edad
	replace inmigrantes1 = L.inmigrantes1 if inmigrantes1 == .
	replace inmigrantes2 = L.inmigrantes2 if inmigrantes2 == .
	replace emigrantes1 = L.emigrantes1 if emigrantes1 == .
	replace emigrantes2 = L.emigrantes2 if emigrantes2 == .

	format *SIM* %10.0fc
	drop nacimientosSIM

	levelsof anio, local(anio)
	levelsof edad, local(edad)
	reshape wide poblacion* tasamortalidad* *migrantes* defunciones*, i(anio) j(edad)
	tsset anio

	foreach k of local anio {
		foreach j of local edad {
			if `k' > `aniohoy' {
				if `j' > 0 {
					replace poblacionSIM1`j' = L.poblacionSIM1`=`j'-1' * (1 - tasamortalidad1`=`j'-1'/100) + inmigrantes1`=`j'-1' - emigrantes1`=`j'-1' if anio == `k'
					replace poblacionSIM2`j' = L.poblacionSIM2`=`j'-1' * (1 - tasamortalidad2`=`j'-1'/100) + inmigrantes2`=`j'-1' - emigrantes2`=`j'-1' if anio == `k'
				}
			}
			else {
					replace poblacionSIM1`j' = poblacion1`j' if anio == `k'
					replace poblacionSIM2`j' = poblacion2`j' if anio == `k'
			}
		}
	}
	reshape long poblacion1 poblacionSIM1 emigrantes1 inmigrantes1 tasamortalidad1 ///
			poblacion2 poblacionSIM2 emigrantes2 inmigrantes2 tasamortalidad2 ///
			defunciones1 defunciones2, i(anio) j(edad)
	label values edad .
	reshape long poblacion poblacionSIM emigrantes inmigrantes tasamortalidad defunciones, i(anio edad) j(sexo)
	label values sexo sexo

	* Texto *
	tabstat poblacionSIM if anio == `aniofinal', f(%20.0fc) stat(sum) save
	tempname POBFINS
	matrix `POBFINS' = r(StatTotal)
	noisily di in g "  Simulaci{c o'}n " in y `aniofinal' in g ": " in y %14.0fc `POBFINS'[1,1]

	tempvar edad2 zero poblacionTF poblacionTFSIM
	g `edad2' = edad
	replace `edad2' = . if edad != 5 & edad != 10 & edad != 15 & edad != 20 ///
		& edad != 25 & edad != 30 & edad != 35 & edad != 40 & edad != 45 ///
		& edad != 50 & edad != 55 & edad != 60 & edad != 65 & edad != 70 ///
		& edad != 75 & edad != 80 & edad != 85 & edad != 90 & edad != 95 ///
		& edad != 100 & edad != 105

	g `zero' = 0
	g `poblacionTF' = -poblacion if sexo == 1
	replace `poblacionTF' = poblacion if sexo == 2
	g `poblacionTFSIM' = -poblacionSIM if sexo == 1
	replace `poblacionTFSIM' = poblacionSIM if sexo == 2

	* X label *
	tabstat poblacion if (anio == `aniohoy' | anio == `aniofinal'), ///
		stat(max) f(%15.0fc) by(sexo) save
	tempname MaxHS MaxMS
	matrix `MaxHS' = r(Stat1)
	matrix `MaxMS' = r(Stat2)

	twoway (bar `poblacionTF' edad if sexo == 1 & anio == `aniofinal', horizontal lwidth(none)) ///
		(bar `poblacionTF' edad if sexo == 2 & anio == `aniofinal', horizontal lwidth(none)) ///
		(bar `poblacionTFSIM' edad if sexo == 1 & anio == `aniofinal', horizontal lwidth(none) barwidth(.33)) ///
		(bar `poblacionTFSIM' edad if sexo == 2 & anio == `aniofinal', horizontal lwidth(none) barwidth(.33)) ///
		(sc `edad2' `zero' if anio == `aniofinal', msymbol(i) mlabel(`edad2') mlabsize(vsmall) mlabcolor("114 113 118")), ///
		legend(label(1 "Hombres CONAPO") label(2 "Mujeres CONAPO") ///
		label(3 "Hombres Simulado") ///
		label(4 "Mujeres Simulado") order(1 2 3 4) region(margin(zero))) ///
		yscale(noline) ylabel(none) xscale(noline) ///
		name(PiramideSIM, replace) ///
		xlabel(`=-`MaxHS'[1,1]' `"`=string(`MaxHS'[1,1],"%15.0fc")'"' ///
		`=-`MaxHS'[1,1]/2' `"`=string(`MaxHS'[1,1]/2,"%15.0fc")'"' 0 ///
		`=`MaxMS'[1,1]/2' `"`=string(`MaxMS'[1,1]/2,"%15.0fc")'"' ///
		`=`MaxMS'[1,1]' `"`=string(`MaxMS'[1,1],"%15.0fc")'"', angle(horizontal)) ///
		///caption("Fuente: Elaborado con el Simulador Fiscal CIEP v5, utilizando informaci{c o'}n de CONAPO.") ///
		///xtitle("Personas") ///
		title("Pir{c a'}mide {bf:demogr{c a'}fica}: CONAPO vs. simulado") ///
		subtitle("$pais `aniofinal'")

	capture drop __*
	drop tasamortalidad
	rename poblacion poblacionOriginal
	rename poblacionSIM poblacion
	if `c(version)' > 13.1 {
		preserve
		saveold "`c(sysdir_site)'/SIM//Poblacion.dta", replace version(13)
		collapse (sum) poblacion, by(anio)
		saveold "`c(sysdir_site)'/SIM//Poblaciontot.dta", replace version(13)
		restore
	}
	else {
		preserve
		save "`c(sysdir_site)'/SIM//Poblacion.dta", replace
		collapse (sum) poblacion, by(anio)
		save "`c(sysdir_site)'/SIM//Poblaciontot.dta", replace
		restore
	}
}
