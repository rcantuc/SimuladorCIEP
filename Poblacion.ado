*! Poblacion.ado: 4 de diciembre de 2019. Autor: Ricardo Cantú
program define Poblacion
quietly {

	timer on 14

	local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)

	* Revisa si se puede usar la base de datos *
	capture use `"`c(sysdir_site)'/SIM/$pais/Poblacion.dta"', clear
	if _rc != 0 {
		if "$pais" == "" {
			noisily run `"`c(sysdir_site)'/UpdatePoblacion.do"'
		}
		else {
			run `"`c(sysdir_site)'/UpdatePoblacionMundial.do"'
		}
	}

	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}

	syntax [if] [, ANIOhoy(int `aniovp') ANIOFINal(int -1) NOGraphs UPDATE ///
		TF(real -1) TM2044(real -1) TM4564(real -1) TM65(real -1)]

	* Si no hay año inicial, utiliza la fecha de hoy *
	if `aniohoy' == -1 {
		local aniohoy : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniohoy = substr(`"`=trim("`aniovp'")'"',1,4)
	}

	* If default *
	if `"`if'"' == "" {
		local if = `"if entidad == "Nacional""'
	}

	use `if' using `"`c(sysdir_site)'/SIM/$pais/Poblacion.dta"', clear
	noisily di _newline(2) in g _dup(20) "." "{bf:   Poblaci{c o'}n: " in y "`=entidad[1]'   }" in g _dup(20) "." _newline

	* Si hay un error o la opción "update" es llamada, limpia la base de datos y la usa *
	if "`update'" == "update" {
		if "$pais" == "" {
			noisily run `"`c(sysdir_site)'/UpdatePoblacion.do"'
		}
		else {
			run `"`c(sysdir_site)'/UpdatePoblacionMundial.do"'
		}
		use `if' using `"`c(sysdir_site)'/SIM/$pais/Poblacion.dta"', clear
	}

	* Si no hay año final, utiliza el último elemento del vector "anio" *
	if `aniofinal' == -1 {
		local aniofinal = anio in -1
	}
	local anioinicial = anio in 1
	capture drop __*


	************************
	*** 0. Base de datos ***
	************************
	replace entidad = "Estado de México" if entidad == "M?xico" | entidad == "México"

	tabstat poblacion if anio == `aniohoy', f(%20.0fc) stat(sum) save
	tempname POBTOT
	matrix `POBTOT' = r(StatTotal)
	noisily di in g " POBLACI{c O'}N " in y `aniohoy' in g ": " in y %15.0fc `POBTOT'[1,1] in g " personas"
	scalar poblaciontotal = string(`POBTOT'[1,1],"%20.0fc")

	tabstat poblacion if anio == `aniofinal', f(%20.0fc) stat(sum) save
	tempname POBFIN
	matrix `POBFIN' = r(StatTotal)
	noisily di in g " POBLACI{c O'}N " in y `aniofinal' in g ": " in y %15.0fc `POBFIN'[1,1] in g " personas"
	scalar poblacionfinal = string(`POBFIN'[1,1],"%20.0fc")



	*****************************
	*** 1 Tasas de fecundidad ***
	*****************************
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



	***************************
	*** 1. Grafica Piramide ***
	***************************
	if "`nographs'" != "nographs" & "$nographs" == "" {
		local poblacion : variable label poblacion

		*local entidadGName = substr("`=entidad[1]'",1,4) + substr("`=entidad[1]'",-1,1)
		local entidadGName = "`=entidad[1]'"
		local entidadGName = strtoname("`entidadGName'")
		
		tempvar pob2
		capture confirm variable poblacionSIM
		if _rc == 0 {
			g `pob2' = -poblacionSIM if sexo == 1
			replace `pob2' = poblacionSIM if sexo == 2
		}
		else {
			g `pob2' = -poblacion if sexo == 1
			replace `pob2' = poblacion if sexo == 2		
		}
		format `pob2' %10.0fc


		****************
		* Estadisticos *
		* Calcula las estadísticas descriptivas y las guarda en matrices *
		* Mediana *
		tabstat edad [fw=round(abs(poblacion),1)] if anio == `aniohoy', ///
			stat(median) by(sexo) save
		tempname H`aniohoy' M`aniohoy'
		matrix `H`aniohoy'' = r(Stat1)
		matrix `M`aniohoy'' = r(Stat2)

		tabstat edad [fw=round(abs(poblacion),1)] if anio == `aniofinal', ///
			stat(median) by(sexo) save
		tempname H`aniofinal' M`aniofinal'
		matrix `H`aniofinal'' = r(Stat1)
		matrix `M`aniofinal'' = r(Stat2)

		* Distribucion inicial *
		tabstat poblacion if anio == `aniohoy' & edad < 18, ///
			stat(sum) f(%15.0fc) save
		tempname P18_`aniohoy'
		matrix `P18_`aniohoy'' = r(StatTotal)

		tabstat poblacion if anio == `aniohoy' & edad >= 18 & edad < 65, ///
			stat(sum) f(%15.0fc) save
		tempname P1865_`aniohoy'
		matrix `P1865_`aniohoy'' = r(StatTotal)

		tabstat poblacion if anio == `aniohoy' & edad >= 65, ///
			stat(sum) f(%15.0fc) save
		tempname P65_`aniohoy'
		matrix `P65_`aniohoy'' = r(StatTotal)

		tabstat poblacion if anio == `aniohoy', stat(sum) f(%15.0fc) save
		tempname P`aniohoy'
		matrix `P`aniohoy'' = r(StatTotal)

		* Distribucion final *
		tabstat poblacion if anio == `aniofinal' & edad < 18, ///
			stat(sum) f(%15.0fc) save
		tempname P18_`aniofinal'
		matrix `P18_`aniofinal'' = r(StatTotal)

		tabstat poblacion if anio == `aniofinal' & edad >= 18 & edad < 65, ///
			stat(sum) f(%15.0fc) save
		tempname P1865_`aniofinal'
		matrix `P1865_`aniofinal'' = r(StatTotal)

		tabstat poblacion if anio == `aniofinal' & edad >= 65, ///
			stat(sum) f(%15.0fc) save
		tempname P65_`aniofinal'
		matrix `P65_`aniofinal'' = r(StatTotal)

		tabstat poblacion if anio == `aniofinal', stat(sum) f(%15.0fc) save
		tempname P`aniofinal'
		matrix `P`aniofinal'' = r(StatTotal)

		* Poblacion viva *
		tempname Pviva
		capture tabstat poblacion if anio == `aniofinal' & edad > `aniofinal'-`aniohoy', ///
			stat(sum) f(%15.0fc) save
		if _rc != 0 {
			matrix `Pviva' = J(1,1,0)
		
		}
		else {
			matrix `Pviva' = r(StatTotal)
		}

		tempname Pnacida
		capture tabstat poblacion if anio == `aniofinal' & edad <= `aniofinal'-`aniohoy', ///
			stat(sum) f(%15.0fc) save
		if _rc != 0 {
			matrix `Pnacida' = J(1,1,0)
		
		}
		else {
			matrix `Pnacida' = r(StatTotal)
		}

		* X label *
		tabstat poblacion if (anio == `aniohoy' | anio == `aniofinal'), ///
			stat(max) f(%15.0fc) by(sexo) save
		tempname MaxH MaxM
		matrix `MaxH' = r(Stat1)
		matrix `MaxM' = r(Stat2)

		g edad2 = edad
		replace edad2 = . if edad != 5 & edad != 10 & edad != 15 & edad != 20 ///
			& edad != 25 & edad != 30 & edad != 35 & edad != 40 & edad != 45 ///
			& edad != 50 & edad != 55 & edad != 60 & edad != 65 & edad != 70 ///
			& edad != 75 & edad != 80 & edad != 85 & edad != 90 & edad != 95 ///
			& edad != 100 & edad != 105
		g zero = 0

		* Grafica sexo = 1 como negativos y sexo = 2 como positivos por grupos etarios, en el presente y futuro *
		* 1. Vivios en el año inicial y con una edad menor a 109  para el año final *
		* 2. Vivos en el año final; nacidos durante o después del año inicial *
		* 3. Vivos en el año final;  nacidos antes del año inicial *
		* 4. Vivios en el año inicial y  mayores a 109 en el año final *
		twoway (bar `pob2' edad if sexo == 1 & anio == `aniohoy' ///
			& edad+`aniofinal'-`aniohoy' <= 109, horizontal lwidth(none)) ///
			(bar `pob2' edad if sexo == 2 & anio == `aniohoy' ///
			& edad+`aniofinal'-`aniohoy' <= 109, horizontal lwidth(none)) ///
			(bar `pob2' edad if sexo == 1 & anio == `aniofinal' ///
			& edad <= `aniofinal'-`aniohoy', horizontal barwidth(.15) ///
			lwidth(none) /*color("83 144 0")*/) ///
			(bar `pob2' edad if sexo == 2 & anio == `aniofinal' ///
			& edad <= `aniofinal'-`aniohoy', horizontal barwidth(.15) ///
			lwidth(none) /*color("149 191 75")*/) ///
			(bar `pob2' edad if sexo == 1 & anio == `aniofinal' ///
			& edad > `aniofinal'-`aniohoy', horizontal barwidth(.66) ///
			lwidth(none) color("255 107 24")) ///
			(bar `pob2' edad if sexo == 2 & anio == `aniofinal' ///
			& edad > `aniofinal'-`aniohoy', horizontal barwidth(.66) ///
			lwidth(none) color("255 189 0")) ///
			(bar `pob2' edad if sexo == 1 & anio == `aniohoy' ///
			& edad+`aniofinal'-`aniohoy' > 109, horizontal barwidth(.5) ///
			lwidth(none) /*color("255 129 0")*/) ///
			(bar `pob2' edad if sexo == 2 & anio == `aniohoy' ///
			& edad+`aniofinal'-`aniohoy' > 109, horizontal barwidth(.5) ///
			lwidth(none) /*color("255 189 0")*/) ///
			(sc edad2 zero if anio == `aniohoy', msymbol(i) mlabel(edad2) ///
			mlabsize(vsmall) mlabcolor("114 113 118")), ///
			legend(label(1 "Hombres") label(2 "Mujeres")) ///
			legend(label(3 "H. nacidos post `aniohoy'") ///
			label(4 "M. nacidas post `aniohoy'") ///
			///label(5 "H. `aniofinal'") ///
			///label(6 "M. `aniofinal'") ///
			label(7 "H. fallecidos para `aniofinal'") ///
			label(8 "M. fallecidas para `aniofinal'")) ///
			legend(order(1 2 3 4 7 8) holes(1 2 5 6) rows(2) on region(margin(zero))) ///
			yscale(noline) ylabel(none) xscale(noline) ///
			text(105 `=-`MaxH'[1,1]*.618' "{bf:Edad mediana `aniohoy'}") ///
			text(100 `=-`MaxH'[1,1]*.618' "Hombres: `=`H`aniohoy''[1,1]'") ///
			text(95 `=-`MaxH'[1,1]*.618' "Mujeres: `=`M`aniohoy''[1,1]'") ///
			text(105 `=`MaxH'[1,1]*.618' "{bf:Edad mediana `aniofinal'}") ///
			text(100 `=`MaxH'[1,1]*.618' "Hombres: `=`H`aniofinal''[1,1]'") ///
			text(95 `=`MaxH'[1,1]*.618' "Mujeres: `=`M`aniofinal''[1,1]'") ///
			text(90 `=-`MaxH'[1,1]*.618' "{bf:Poblaci{c o'}n `aniohoy'}") ///
			text(85 `=-`MaxH'[1,1]*.618' `"`=string(`P`aniohoy''[1,1],"%20.0fc")'"') ///
			text(80 `=-`MaxH'[1,1]*.618' "{bf: Personas de `aniohoy' vivas en `aniofinal'} ") ///
			text(75 `=-`MaxH'[1,1]*.618' `"`=string(`Pviva'[1,1],"%20.0fc")' (`=string(`Pviva'[1,1]/`P`aniohoy''[1,1]*100,"%7.1fc")'%)"') ///
			text(90 `=`MaxH'[1,1]*.618' "{bf:Poblaci{c o'}n `aniofinal'}") ///
			text(85 `=`MaxH'[1,1]*.618' `"`=string(`P`aniofinal''[1,1],"%20.0fc")'"') ///
			text(80 `=`MaxH'[1,1]*.618' "{bf:Personas post `aniohoy' vivas en `aniofinal'} ") ///
			text(75 `=`MaxH'[1,1]*.618' `"`=string(`Pnacida'[1,1],"%20.0fc")' (`=string(`Pnacida'[1,1]/`P`aniofinal''[1,1]*100,"%7.1fc")'%)"') ///
			///legend(label(1 "Men") label(2 "Women")) ///
			/*text(105 `=`MaxH'[1,1]*.618' "{bf:Population}") ///
			text(100 `=`MaxH'[1,1]*.618' `"`=string(`P`aniohoy''[1,1],"%20.0fc")'"') ///
			text(105 `=-`MaxH'[1,1]*.618' "{bf:Median age}") ///
			text(100 `=-`MaxH'[1,1]*.618' "Men: `=`H`aniohoy''[1,1]'") ///
			text(95 `=-`MaxH'[1,1]*.618' "Women: `=`M`aniohoy''[1,1]'")*/ ///
			name(P_`aniohoy'_`aniofinal'_`entidadGName', replace) ///
			xlabel(`=-`MaxH'[1,1]' `"`=string(`MaxH'[1,1],"%15.0fc")'"' ///
			`=-`MaxH'[1,1]/2' `"`=string(`MaxH'[1,1]/2,"%15.0fc")'"' 0 ///
			`=`MaxM'[1,1]/2' `"`=string(`MaxM'[1,1]/2,"%15.0fc")'"' ///
			`=`MaxM'[1,1]' `"`=string(`MaxM'[1,1],"%15.0fc")'"', angle(horizontal)) ///
			///caption("Elaborado por el CIEP con informaci{c o'}n de: CONAPO (2018).") ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con información de CONAPO.") ///
			title("{bf:Pir{c a'}mide} demogr{c a'}fica") ///
			///subtitle($pais `=entidad[1]') ///
			///title("{bf:Population} pyramid")


		if "$export" != "" {
			graph export "$export/P_`entidadGName'.png", replace name(P_`aniohoy'_`aniofinal'_`entidadGName')
		}

		**************************************
		*** Grafica Transicion demografica ***
		**************************************
		capture confirm variable poblacionSIM
		if _rc != 0 {
			g pob18 = poblacion if edad <= 18
			g pob1934 = poblacion if edad >= 19 & edad <= 34
			g pob3560 = poblacion if edad >= 35 & edad <= 60
			g pob61 = poblacion if edad >= 61
		}
		else {
			g pob18 = poblacionSIM if edad <= 18
			g pob1934 = poblacionSIM if edad >= 19 & edad <= 34
			g pob3560 = poblacionSIM if edad >= 35 & edad <= 60
			g pob61 = poblacionSIM if edad >= 61
		}

		preserve
		collapse (sum) pob18 pob1934 pob3560 pob61 poblacion*, by(anio entidad)
		format poblacion pob* %15.0fc

		* Distribucion *
		capture confirm variable poblacionSIM
		if _rc != 0 {
			g pob18_2 = pob18/poblacion*100
			g pob1934_2 = pob1934/poblacion*100
			g pob3560_2 = pob3560/poblacion*100
			g pob61_2 = pob61/poblacion*100
		}
		else {
			g pob18_2 = pob18/poblacionSIM*100
			g pob1934_2 = pob1934/poblacionSIM*100
			g pob3560_2 = pob3560/poblacionSIM*100
			g pob61_2 = pob61/poblacionSIM*100
		}

		* Valores maximos *
		tabstat pob18_2 pob1934_2 pob3560_2 pob61_2, stat(max min) save
		tempname MAX
		matrix `MAX' = r(StatTotal)

		forvalues k = 1(1)`=_N' {
			* Maximos *
			* Busca la población máxima y guarda el año y el número *
			if pob18_2[`k'] == `MAX'[1,1] {
				local x1 = anio[`k']
				local y1 = (pob18[`k'])/1000000
				local p1 = `k'
			}
			if pob1934_2[`k'] == `MAX'[1,2] {
				local x2 = anio[`k']
				local y2 = (pob1934[`k'] + pob18[`k'])/1000000
				local p2 = `k'
			}
			if pob3560_2[`k'] == `MAX'[1,3] {
				local x3 = anio[`k']
				local y3 = (pob3560[`k'] + pob1934[`k'] + pob18[`k'])/1000000
				local p3 = `k'
			}
			if pob61_2[`k'] == `MAX'[1,4] {
				local x4 = anio[`k']
				local y4 = (pob61[`k'] + pob3560[`k'] + pob1934[`k'] + pob18[`k'])/1000000
				local p4 = `k'
			}
			
			* Minimos *
			* Busca la población mínima y guarda el año y el número *
			if pob18_2[`k'] == `MAX'[2,1] {
				local m1 = anio[`k']
				local z1 = (pob18[`k'])/1000000
				local q1 = `k'
			}
			if pob1934_2[`k'] == `MAX'[2,2] {
				local m2 = anio[`k']
				local z2 = (pob1934[`k'] + pob18[`k'])/1000000
				local q2 = `k'
				if `m2' < 1980 {
					local place21 = "se"
					local place22 = "ne"
				}
				else {
					local place21 = "sw"
					local place22 = "nw"
				}
			}
			if pob3560_2[`k'] == `MAX'[2,3] {
				local m3 = anio[`k']
				local z3 = (pob3560[`k'] + pob1934[`k'] + pob18[`k'])/1000000
				local q3 = `k'
			}		
			if pob61_2[`k'] == `MAX'[2,4] {
				local m4 = anio[`k']
				local z4 = (pob61[`k'] + pob3560[`k'] + pob1934[`k'] + pob18[`k'])/1000000
				local q4 = `k'
			}
		}

		tempvar pob18 pob1934 pob3560 pob61
		g `pob18' = pob18/1000000
		g `pob1934' = (pob1934 + pob18)/1000000
		g `pob3560' = (pob3560 + pob1934 + pob18)/1000000
		g `pob61' = (pob61 + pob3560 + pob1934 + pob18)/1000000

		twoway (area `pob61' `pob3560' `pob1934' `pob18' anio if anio <= `aniohoy') ///
			(area `pob61' anio if anio > `aniohoy', color("255 129 0")) ///
			(area `pob3560' anio if anio > `aniohoy', color("255 189 0")) ///
			(area `pob1934' anio if anio > `aniohoy', color("39 97 47")) ///
			(area `pob18' anio if anio > `aniohoy', color("53 200 71")), ///
			text(`y1' `x1' `"{bf:Max:} `=string(`MAX'[1,1],"%5.1fc")' % (`x1')"', place(s)) ///
			text(`y1' `x1' `"{bf:<18:} `=string(pob18[`p1'],"%12.0fc")'"', place(n)) ///
			text(`y2' `x2' `"{bf:Max:} `=string(`MAX'[1,2],"%5.1fc")' % (`x2')"', place(s)) ///
			text(`y2' `x2' `"{bf:19-34:} `=string(pob1934[`p2'],"%12.0fc")'"', place(n)) ///
			text(`y3' `x3' `"{bf:Max:} `=string(`MAX'[1,3],"%5.1fc")' % (`x3')"', place(sw)) ///
			text(`y3' `x3' `"{bf:35-60:} `=string(pob3560[`p3'],"%12.0fc")'"', place(nw)) ///
			text(`y4' `x4' `"{bf:Max:} `=string(`MAX'[1,4],"%5.1fc")' % (`x4')"', place(sw)) ///
			text(`y4' `x4' `"{bf:61+:} `=string(pob61[`p4'],"%12.0fc")'"', place(nw)) ///
			text(`z1' `m1' `"{bf:Min:} `=string(`MAX'[2,1],"%5.1fc")' % (`m1')"', place(sw)) ///
			text(`z1' `m1' `"{bf:<18:} `=string(pob18[`q1'],"%12.0fc")'"', place(nw)) ///
			text(`z2' `m2' `"{bf:Min:} `=string(`MAX'[2,2],"%5.1fc")' % (`m2')"', place(`place21')) ///
			text(`z2' `m2' `"{bf:19-34:} `=string(pob1934[`q2'],"%12.0fc")'"', place(`place22')) ///
			text(`z3' `m3' `"{bf:Min:} `=string(`MAX'[2,3],"%5.1fc")' % (`m3')"', place(s)) ///
			text(`z3' `m3' `"{bf:35-60:} `=string(pob3560[`q3'],"%12.0fc")'"', place(n)) ///
			text(`z4' `m4' `"{bf:Min:} `=string(`MAX'[2,4],"%5.1fc")' % (`m4')"', place(s)) ///
			text(`z4' `m4' `"{bf:61+:} `=string(pob61[`q4'],"%12.0fc")'"', place(n)) ///
			text(`=`POBTOT'[1,1]/1000000*.01' `=`aniohoy'-.5' "{bf:`aniohoy'}", place(nw)) ///
			xtitle("") ///
			ytitle("millones de personas") ///
			xline(`=`aniohoy'+.5') ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con información de CONAPO.") ///
			legend(on label(1 "61+") label(2 "35 - 60") label(3 "19 - 34") label(4 "<18") order(4 3 2 1) region(margin(zero))) ///
			title("{bf:Transici{c o'}n} demogr{c a'}fica") ///
			///subtitle(${pais} `=entidad[1]') ///
			ylabel(, format(%20.1fc)) yscale(range(0)) ///
			xlabel(`anioinicial'(10)`=anio[_N]') ///
			name(E_`entidadGName', replace)
			
			if "$export" != "" {
				graph export "$export/E_`entidadGName'.png", replace name(E_`entidadGName')
			}

			restore
	}


	** END **
	timer off 14
	timer list 14
	noisily di _newline in y round(`=r(t14)/r(nt14)',.1) in g " segs  "
}
end
