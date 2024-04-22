*!*******************************************
*!***                                    ****
*!***    Poblacion y defunciones         ****
*!***    Bases: CONAPO 1950-2070         ****
*!***    Autor: Ricardo                  ****
*!***    Fecha: 20/04/2024               ****
*!***                                    ****
*!***    Sintaxis:                       ****
*!***    Poblacion [if] [, ANIO(int) ANIOFINal(int) NOGraphs UPDATE]
*!*******************************************
program define Poblacion, return
quietly {
	timer on 14

	** 0.1 Revisa si se puede usar la base de datos **
	capture use `"SIM/Poblacion.dta"', clear
	if _rc != 0 {
		UpdatePoblacion
	}

	** 0.2 Revisa si existe el scalar aniovp **
	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}
	else {
		local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)
	}



	*******************
	*** 1. Sintaxis ***
	*******************
	syntax [if] [, ANIO(int `aniovp') ANIOFINal(int -1) NOGraphs UPDATE]

	* 1.1 Si la opción "update" es llamada, ejecuta el do-file UpdatePoblacion.do *
	if "`update'" == "update" {
		UpdatePoblacion
	}

	* if default *
	if `"`if'"' == `"if entidad == """' | `"`if'"' == "" {
		local if = `"if entidad == "Nacional""'
	}



	************************
	*** 2. Base de datos ***
	************************
	use `if' using `"SIM/Poblacion.dta"', clear
	noisily di _newline(2) in g _dup(20) "." "{bf:   Poblaci{c o'}n: " in y "`=entidad[1]'   }" in g _dup(20) "." _newline

	* Obtiene el año inicial de la base *
	local anioinicial = anio in 1
	local entidadGName = "`=entidad[1]'"
	
	tokenize $entidadesC
	local j = 1
	foreach k of global entidadesL {
		if "`entidadGName'" == "`k'" {
			local entidadGName = "``j''"
			continue, break
		}
		local ++j
	}
	
	local entidadGName = strtoname("`entidadGName'")

	* Si no hay opción aniofinal, utiliza el último año del vector "anio" *
	if `aniofinal' == -1 {
		local aniofinal = anio in -1
	}


	** 2.1 Display inicial **
	forvalues k=`anio'(1)`aniofinal' {
		tabstat poblacion if anio == `k', f(%20.0fc) stat(sum) save
		tempname POBTOT
		matrix `POBTOT' = r(StatTotal)
		noisily di in g " Personas " in y `k' in g ": " in y %15.0fc `POBTOT'[1,1]
		if `k' == `anio' {
			scalar pobtot`entidadGName' = `POBTOT'[1,1]
		}
		if `k' == `aniofinal' {
			scalar pobfin`entidadGName' = `POBTOT'[1,1]
		}
	}



	***************************
	*** 3. Gráfica Pirámide ***
	***************************
	if "`nographs'" != "nographs" & "$nographs" == "" {
		preserve
		local poblacion : variable label poblacion
		
		tempvar pob2
		g `pob2' = -poblacion if sexo == 1
		replace `pob2' = poblacion if sexo == 2		
		format `pob2' %10.0fc

		* Calcula las estadísticas descriptivas y las guarda en matrices *
		* Mediana *
		tabstat edad [fw=round(abs(poblacion),1)] if anio == `anio', stat(median) by(sexo) save
		tempname H`anio' M`anio'
		matrix `H`anio'' = r(Stat1)
		matrix `M`anio'' = r(Stat2)

		tabstat edad [fw=round(abs(poblacion),1)] if anio == `aniofinal', stat(median) by(sexo) save
		tempname H`aniofinal' M`aniofinal'
		matrix `H`aniofinal'' = r(Stat1)
		matrix `M`aniofinal'' = r(Stat2)

		* Distribucion inicial *
		tabstat poblacion if anio == `anio' & edad < 18, stat(sum) f(%15.0fc) save
		tempname P18_`anio'
		matrix `P18_`anio'' = r(StatTotal)

		tabstat poblacion if anio == `anio' & edad >= 18 & edad < 65, stat(sum) f(%15.0fc) save
		tempname P1865_`anio'
		matrix `P1865_`anio'' = r(StatTotal)

		tabstat poblacion if anio == `anio' & edad >= 65, stat(sum) f(%15.0fc) save
		tempname P65_`anio'
		matrix `P65_`anio'' = r(StatTotal)

		tabstat poblacion if anio == `anio', stat(sum) f(%15.0fc) save
		tempname P`anio'
		matrix `P`anio'' = r(StatTotal)

		* Distribucion final *
		tabstat poblacion if anio == `aniofinal' & edad < 18, stat(sum) f(%15.0fc) save
		tempname P18_`aniofinal'
		matrix `P18_`aniofinal'' = r(StatTotal)

		tabstat poblacion if anio == `aniofinal' & edad >= 18 & edad < 65, stat(sum) f(%15.0fc) save
		tempname P1865_`aniofinal'
		matrix `P1865_`aniofinal'' = r(StatTotal)

		tabstat poblacion if anio == `aniofinal' & edad >= 65, stat(sum) f(%15.0fc) save
		tempname P65_`aniofinal'
		matrix `P65_`aniofinal'' = r(StatTotal)

		tabstat poblacion if anio == `aniofinal', stat(sum) f(%15.0fc) save
		tempname P`aniofinal'
		matrix `P`aniofinal'' = r(StatTotal)

		* Poblacion viva *
		tempname Pviva
		capture tabstat poblacion if anio == `aniofinal' & edad >= `aniofinal'-`anio', stat(sum) f(%15.0fc) save
		if _rc != 0 {
			matrix `Pviva' = J(1,1,0)
		
		}
		else {
			matrix `Pviva' = r(StatTotal)
		}

		* Población no nacida *
		tempname Pnacida
		capture tabstat poblacion if anio == `aniofinal' & edad < `aniofinal'-`anio', stat(sum) f(%15.0fc) save
		if _rc != 0 {
			matrix `Pnacida' = J(1,1,0)
		
		}
		else {
			matrix `Pnacida' = r(StatTotal)
		}

		* Población hoy *
		tempname Phoy
		capture tabstat poblacion if anio == `anio' & edad < 109 - (`aniofinal'-`anio'), stat(sum) f(%15.0fc) save
		if _rc != 0 {
			matrix `Phoy' = J(1,1,0)
		
		}
		else {
			matrix `Phoy' = r(StatTotal)
		}

		* X label *
		tabstat poblacion if (anio == `anio' | anio == `aniofinal'), stat(max) f(%15.0fc) by(sexo) save
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

		if "$textbook" == "" {
			local graphtitle "{bf:Pirámides demográficas}"
			///local graphtitle "{bf:Population} pyramid"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de CONAPO (2023)."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		* Grafica sexo = 1 como negativos y sexo = 2 como positivos por grupos etarios, en el presente y futuro *
		twoway (bar `pob2' edad if sexo == 1 & anio == `anio' & edad+`aniofinal'-`anio' <= 109, horizontal) ///
			(bar `pob2' edad if sexo == 2 & anio == `anio' & edad+`aniofinal'-`anio' <= 109, horizontal) ///
			(bar `pob2' edad if sexo == 1 & anio == `anio' & edad+`aniofinal'-`anio' > 109, horizontal barwidth(.5) bstyle(p1bar)) ///
			(bar `pob2' edad if sexo == 2 & anio == `anio' & edad+`aniofinal'-`anio' > 109, horizontal barwidth(.5) bstyle(p2bar)) ///
			(sc edad2 zero if anio == `anio', msymbol(i) mlabel(edad2) mlabsize(vsmall) mlabcolor("114 113 118")), ///
			legend(label(1 "Hombres") label(2 "Mujeres")) ///
			legend(off order(1 2) rows(1) region(margin(zero))) ///
			yscale(noline) ylabel(none) xscale(noline) ///
			///text(105 `=-`MaxH'[1,1]*.5' "{bf:Edad mediana}") ///
			///text(97.5 `=-`MaxH'[1,1]*.5' "Hombres: `=`H`anio''[1,1]'") ///
			///text(90 `=-`MaxH'[1,1]*.5' "Mujeres: `=`M`anio''[1,1]'") ///
			text(`=(109-(`aniofinal'-`anio'))/2' `=-`MaxH'[1,1]*.5' "{bf: Vivos en `aniofinal'}", size(huge) color(black)) ///
			text(`=(109-(`aniofinal'-`anio'))/2' `=`MaxH'[1,1]*.5' `"`=string(`Phoy'[1,1],"%20.0fc")'"', size(huge) color(black)) ///
			/*legend(label(1 "Men") label(2 "Women")) ///
			text(105 `=`MaxH'[1,1]*.618' "{bf:Population}") ///
			text(100 `=`MaxH'[1,1]*.618' `"`=string(`P`anio''[1,1],"%20.0fc")'"') ///
			text(105 `=-`MaxH'[1,1]*.618' "{bf:Median age}") ///
			text(100 `=-`MaxH'[1,1]*.618' "Men: `=`H`anio''[1,1]'") ///
			text(95 `=-`MaxH'[1,1]*.618' "Women: `=`M`anio''[1,1]'")*/ ///
			name(P_`anio'_`aniofinal'_`entidadGName'A, replace) ///
			xlabel(`=-`MaxH'[1,1]' `"`=string(`MaxH'[1,1],"%15.0fc")'"' ///
			`=-`MaxH'[1,1]/2' `"Hombres"' 0 ///
			`=`MaxM'[1,1]/2' `"Mujeres"' ///
			`=`MaxM'[1,1]' `"`=string(`MaxM'[1,1],"%15.0fc")'"', angle(horizontal)) ///
			title(`"{bf:`anio'}"') ///
			subtitle(`"`=string(`P`anio''[1,1],"%20.0fc")'"') ///
		

		twoway (bar `pob2' edad if sexo == 1 & anio == `aniofinal' & edad < `aniofinal'-`anio', horizontal barwidth(.5)) ///
			(bar `pob2' edad if sexo == 2 & anio == `aniofinal' & edad < `aniofinal'-`anio', horizontal barwidth(.5)) ///
			(bar `pob2' edad if sexo == 1 & anio == `aniofinal' & edad >= `aniofinal'-`anio', horizontal barwidth(1) bstyle(p1bar)) ///
			(bar `pob2' edad if sexo == 2 & anio == `aniofinal' & edad >= `aniofinal'-`anio', horizontal barwidth(1) bstyle(p2bar)) ///
			(sc edad2 zero if anio == `anio', msymbol(i) mlabel(edad2) mlabsize(vsmall) mlabcolor("114 113 118")), ///
			legend(label(1 "Hombres") label(2 "Mujeres")) ///
			legend(off order(1 2) rows(1) region(margin(zero))) ///
			yscale(noline) ylabel(none) xscale(noline) ///
			text(`=((`aniofinal'-`anio'))/2' `=-`MaxH'[1,1]*.5' "{bf: Por nacer}", size(huge) color(black)) ///
			text(`=((`aniofinal'-`anio'))/2' `=`MaxH'[1,1]*.5' `"`=string(`Pnacida'[1,1],"%20.0fc")'"', size(huge) color(black)) ///
			text(`=(`aniofinal'-`anio')+(109-(`aniofinal'-`anio'))/2' `=-`MaxH'[1,1]*.5' "{bf: Vivos en `anio'}", size(huge) color(black)) ///
			text(`=(`aniofinal'-`anio')+(109-(`aniofinal'-`anio'))/2' `=`MaxH'[1,1]*.5' `"`=string(`Pviva'[1,1],"%20.0fc")'"', size(huge) color(black)) ///
			///text(105 `=-`MaxH'[1,1]*.5' "{bf:Edad mediana}") ///
			///text(97.5 `=-`MaxH'[1,1]*.5' "Hombres: `=`H`aniofinal''[1,1]'") ///
			///text(90 `=-`MaxH'[1,1]*.5' "Mujeres: `=`M`aniofinal''[1,1]'") ///
			///text(105 `=`MaxH'[1,1]*.5' "{bf:Nacidos después de `anio'} ") ///
			///text(97.5 `=`MaxH'[1,1]*.5' `"`=string(`Pnacida'[1,1],"%20.0fc")' (`=string(`Pnacida'[1,1]/`P`aniofinal''[1,1]*100,"%7.1fc")'%)"') ///
			/*legend(label(1 "Men") label(2 "Women")) ///
			text(105 `=`MaxH'[1,1]*.618' "{bf:Population}") ///
			text(100 `=`MaxH'[1,1]*.618' `"`=string(`P`anio''[1,1],"%20.0fc")'"') ///
			text(105 `=-`MaxH'[1,1]*.618' "{bf:Median age}") ///
			text(100 `=-`MaxH'[1,1]*.618' "Men: `=`H`anio''[1,1]'") ///
			text(95 `=-`MaxH'[1,1]*.618' "Women: `=`M`anio''[1,1]'")*/ ///
			name(P_`anio'_`aniofinal'_`entidadGName'B, replace) ///
			xlabel(`=-`MaxH'[1,1]' `"`=string(`MaxH'[1,1],"%15.0fc")'"' ///
			`=-`MaxH'[1,1]/2' `"Hombres"' 0 ///
			`=`MaxM'[1,1]/2' `"Mujeres"' ///
			`=`MaxM'[1,1]' `"`=string(`MaxM'[1,1],"%15.0fc")'"', angle(horizontal)) ///
			title(`"{bf:`aniofinal'}"') ///
			subtitle(`"`=string(`P`aniofinal''[1,1],"%20.0fc")'"') ///


		graph combine P_`anio'_`aniofinal'_`entidadGName'A P_`anio'_`aniofinal'_`entidadGName'B, ///
			title("`graphtitle'") ///
			subtitle(${pais} `=entidad[1]') ///
			caption("`graphfuente'") ///
			name(P_`anio'_`aniofinal'_`entidadGName', replace) ///

		capture window manage close graph P_`anio'_`aniofinal'_`entidadGName'A
		capture window manage close graph P_`anio'_`aniofinal'_`entidadGName'B

		capture mkdir "SIM/graphs"
		graph save P_`anio'_`aniofinal'_`entidadGName' "SIM/graphs/P_`anio'_`aniofinal'_`entidadGName'", replace
		if "$export" != "" {
			graph export "$export/P_`anio'_`aniofinal'_`entidadGName'.png", replace name(P_`anio'_`aniofinal'_`entidadGName')
		}



		*****************************************
		*** 4. Gráfica transición demográfica ***
		*****************************************
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
				local y3 = (pob3560[`k']/2 + (pob1934[`k'] + pob18[`k']))/1000000
				local p3 = `k'
			}
			if pob61_2[`k'] == `MAX'[1,4] {
				local x4 = anio[`k']
				local y4 = (pob61[`k']/2 + (pob3560[`k'] + pob1934[`k'] + pob18[`k']))/1000000
				local p4 = `k'
			}
			
			* Minimos *
			* Busca la población mínima y guarda el año y el número *
			if pob18_2[`k'] == `MAX'[2,1] {
				local m1 = anio[`k']
				local z1 = (pob18[`k']/2)/1000000
				local q1 = `k'
			}
			if pob1934_2[`k'] == `MAX'[2,2] {
				local m2 = anio[`k']
				local z2 = (pob1934[`k']/2 + pob18[`k'])/1000000
				local q2 = `k'
				if `m2' < 1980 {
					local place21 = "e"
					local place22 = "e"
				}
				else {
					local place21 = "w"
					local place22 = "w"
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

		if "$textbook" == "" {
			local graphtitle "{bf:Transici{c o'}n demogr{c a'}fica}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de CONAPO (2023)."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (area `pob61' `pob3560' `pob1934' `pob18' anio if anio <= `anio') ///
			(area `pob61' anio if anio > `anio', astyle(p1area)) ///
			(area `pob3560' anio if anio > `anio', astyle(p2area)) ///
			(area `pob1934' anio if anio > `anio', astyle(p3area)) ///
			(area `pob18' anio if anio > `anio', astyle(p4area)), ///
			///text(`y1' `x1' `"{bf:Max:} `=string(`MAX'[1,1],"%5.1fc")' % (`x1')"', place(s)) ///
			///text(`y1' `x1' `"{bf:<18:} `=string(pob18[`p1'],"%12.0fc")'"', place(n)) ///
			///text(`y2' `x2' `"{bf:Max:} `=string(`MAX'[1,2],"%5.1fc")' % (`x2')"', place(s)) ///
			///text(`y2' `x2' `"{bf:19-34:} `=string(pob1934[`p2'],"%12.0fc")'"', place(n)) ///
			text(`y3' `x3' `"{bf:Max:} `=string(`MAX'[1,3],"%5.1fc")' % (`x3')"', place(c) size(medlarge) color(black)) ///
			///text(`y3' `x3' `"{bf:35-60:} `=string(pob3560[`p3'],"%12.0fc")'"', place(nw)) ///
			text(`y4' `x4' `"{bf:Max:} `=string(`MAX'[1,4],"%5.1fc")' % (`x4')"', place(w) size(medlarge) color(black)) ///
			///text(`y4' `x4' `"{bf:61+:} `=string(pob61[`p4'],"%12.0fc")'"', place(nw)) ///
			text(`z1' `m1' `"{bf:Min:} `=string(`MAX'[2,1],"%5.1fc")' % (`m1')"', place(w) size(medlarge) color(black)) ///
			///text(`z1' `m1' `"{bf:<18:} `=string(pob18[`q1'],"%12.0fc")'"', place(nw)) ///
			text(`z2' `m2' `"{bf:Min:} `=string(`MAX'[2,2],"%5.1fc")' % (`m2')"', place(`place21') size(medlarge) color(black)) ///
			///text(`z2' `m2' `"{bf:19-34:} `=string(pob1934[`q2'],"%12.0fc")'"', place(`place22')) ///
			///text(`z3' `m3' `"{bf:Min:} `=string(`MAX'[2,3],"%5.1fc")' % (`m3')"', place(s)) ///
			///text(`z3' `m3' `"{bf:35-60:} `=string(pob3560[`q3'],"%12.0fc")'"', place(n)) ///
			///text(`z4' `m4' `"{bf:Min:} `=string(`MAX'[2,4],"%5.1fc")' % (`m4')"', place(s)) ///
			///text(`z4' `m4' `"{bf:61+:} `=string(pob61[`q4'],"%12.0fc")'"', place(n)) ///
			text(`=`POBTOT'[1,1]/1000000*.015' `=`anio'-.5' "{bf:`anio'}", place(nw)) ///
			xtitle("") ///
			ytitle("millones de personas") ///
			xline(`=`anio'+.5') ///
			title("`graphtitle'") ///
			subtitle(${pais} `=entidad[1]') ///
			caption("`graphfuente'") ///
			legend(on label(1 "61 y más") label(2 "35 -- 60") label(3 "19 -- 34") label(4 "18 y menos") order(- "{bf:Edades:}" 4 3 2 1) ///
			position(6) region(margin(zero)) rows(1)) ///
			ylabel(, format(%20.0fc)) yscale(range(0)) ///
			xlabel(`anioinicial'(10)`=anio[_N]') ///
			name(E_`anio'_`aniofinal'_`entidadGName', replace)
			
		graph save E_`anio'_`aniofinal'_`entidadGName' "SIM/graphs/E_`anio'_`aniofinal'_`entidadGName'", replace
		if "$export" != "" {
			graph export "$export/E_`anio'_`aniofinal'_`entidadGName'.png", replace name(E_`anio'_`aniofinal'_`entidadGName')
		}

		*****************************************
		*** 5. Gráfica de tasa de dependencia ***
		*****************************************
		g tasaDependencia = (pob18 + pob61)/(pob3560 + pob1934)*100
		format tasaDependencia %10.1fc

		tabstat tasaDependencia, stat(min max) save
		forvalues k = 1(1)`=_N' {
			if tasaDependencia[`k'] == r(StatTotal)[1,1] {
				local aniotdmin = anio[`k']
			}
			if tasaDependencia[`k'] == r(StatTotal)[2,1] {
				local aniotdmax = anio[`k']
			}

		}

		noisily di _newline in g " Año con mayor tasa de dependencia: " in y `aniotdmax'
		noisily di in g " Año con menor tasa de dependencia: " in y `aniotdmin'

		if "$textbook" == "" {
			local graphtitle "{bf:Tasa de dependencia}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de CONAPO (2023)."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (connected tasaDependencia anio if anio <= `anio') ///
			(connected tasaDependencia anio if anio > `anio'), ///
			title("`graphtitle'") ///
			subtitle(${pais} `=entidad[1]') ///
			caption("`graphfuente'") ///
			xtitle("") ///
			text(`=r(StatTotal)[2,1]' `aniotdmax' "`=string(r(StatTotal)[2,1],"%7.1fc")'", place(n) size(large) color(black)) ///
			text(`=r(StatTotal)[1,1]' `aniotdmin' "`=string(r(StatTotal)[1,1],"%7.1fc")'", place(n) size(large) color(black)) ///
			text(`=tasaDependencia[_N]' `=anio[_N]' "`=string(tasaDependencia[_N],"%7.1fc")'", place(n) size(large) color(black)) ///
			xlabel(`anioinicial'(10)`=anio[_N]') ///
			ytitle("Dependientes por cada 100 personas en edad de trabajar") ///
			xline(`=`anio'+.5') ///
			legend(off label(1 "Observado") label(2 "Proyectado") region(margin(zero)) rows(1)) ///
			name(T_`anio'_`aniofinal'_`entidadGName', replace)

		graph save T_`anio'_`aniofinal'_`entidadGName' "SIM/graphs/T_`anio'_`aniofinal'_`entidadGName'", replace
		if "$export" != "" {
			graph export "$export/T_`anio'_`aniofinal'_`entidadGName'.png", replace name(T_`anio'_`aniofinal'_`entidadGName')
		}
		restore
	}


	** END **
	timer off 14
	timer list 14
	noisily di _newline in y round(`=r(t14)/r(nt14)',.1) in g " segs  "
}
end



****************************************************************************************
****                                                                                ****
****   Bases de datos de Mexico: Población, defunciones y migración internacional   ****
****                                                                                ****
****************************************************************************************
program define UpdatePoblacion
	noisily di in g "  Updating Poblacion.dta..." _newline



	********************
	*** A. Poblacion ***
	********************

	** 1. Base de datos (online) **
	import delimited "http://conapo.segob.gob.mx/work/models/CONAPO/Datos_Abiertos/pry23/00_Pob_Mitad_1950_2070.csv", clear
	*import excel "`c(sysdir_site)'../BasesCIEP/CONAPO/ConDem50a19_ProyPob20a70/0_Pob_Mitad_1950_2070.xlsx", sheet("Hoja1") firstrow case(lower) clear


	** 2. Limpia **
	capture drop renglon
	capture rename año anio
	capture rename ao anio

	rename sexo sexo0
	encode sexo0, generate(sexo)
	drop sexo0


	** 3. Guardar **
	tempfile poblacion
	save "`poblacion'"



	**********************
	*** B. Defunciones ***
	**********************

	** 1. Base de datos (online) **
	import delimited "http://conapo.segob.gob.mx/work/models/CONAPO/Datos_Abiertos/pry23/01_Defunciones_1950_2070.csv", clear
	*import excel "`c(sysdir_site)'../BasesCIEP/CONAPO/ConDem50a19_ProyPob20a70/1_Defunciones_1950_2070.xlsx", sheet("Hoja1") firstrow case(lower) clear


	** 2. Limpia **
	capture rename año anio
	capture rename ao anio
	capture rename aão anio

	rename sexo sexo0
	encode sexo0, generate(sexo)
	drop *renglon sexo0


	** 3. Guardar **
	tempfile defunciones
	save "`defunciones'"



	**********************************
	*** C. Migracion Internacional ***
	**********************************

	** 1. Base de datos (online) **
	import delimited "http://conapo.segob.gob.mx/work/models/CONAPO/Datos_Abiertos/pry23/02_mig_inter_quinquen_proyecciones.csv", clear
	*import excel "`c(sysdir_site)'../BasesCIEP/CONAPO/ConDem50a19_ProyPob20a70/2_mig_inter_quinquen_proyecciones.xlsx", sheet("Hoja1") firstrow case(lower) clear


	** 2. Limpia **
	capture rename año anio
	if _rc != 0 {
		rename ao anio
	}
	split anio, parse("-") destring
	split edad, parse("--") destring

	rename sexo sexo0
	encode sexo0, generate(sexo)
	drop renglon sexo0 anio edad

	* 2.1 Se expanden los años para rellenar los espacios entre rangos. Por ejemplo: de 0-4 a 0,1,2,3,4. *
	expand anio2-anio1
	replace emigrantes = emigrantes/(anio2-anio1)
	replace inmigrantes = inmigrantes/(anio2-anio1)
	sort entidad anio1 anio2 edad1 edad2 sexo
	by entidad anio1 anio2 edad1 edad2 sexo: g n = _n
	replace anio1 = anio1 + n
	drop anio2 n
	rename anio1 anio

	* 2.2 Se distribuyen entre edades *
	expand edad2-edad1+1
	replace emigrantes = emigrantes/(edad2-edad1+1)
	replace inmigrantes = inmigrantes/(edad2-edad1+1)
	sort entidad anio edad1 edad2 sexo
	by entidad anio edad1 edad2 sexo: g n = _n
	replace edad1 = edad1 + n - 1
	drop edad2 n
	rename edad1 edad


	** 3. Guardar **
	tempfile migracion
	save "`migracion'"



	***************/
	*** D. Union ***
	****************

	** 1. Base de datos (temporales) **
	use "`poblacion'", clear
	merge 1:1 (anio edad sexo entidad) using "`defunciones'", nogen
	merge 1:1 (anio edad sexo entidad) using "`migracion'", nogen


	** 2. Limpia **
	replace poblacion = 0 if poblacion == .
	replace emigrantes = 0 if emigrantes == .
	replace inmigrantes = 0 if inmigrantes == .

	replace entidad = "Nacional" if substr(entidad,1,3) == "Rep"
	replace entidad = "Estado de México" if entidad == "M?xico" | entidad == "México"


	** 3. Labels y formato *
	label var anio "Año"
	label var sexo "Sexo"
	label var edad "Edad"
	label var entidad "Entidad federativa"
	label var poblacion "Población"
	label var emigrantes "Emigrantes internacionales"
	label var inmigrantes "Inmigrantes internacionales"
	label var defunciones "Defunciones"
	format poblacion defunciones *migrantes %10.0fc


	** 4. Tasa de fertilidad **
	tempvar mujeresf nacimien nacimientos mujeresfert
	egen `mujeresf' = sum(poblacion) if edad >= 16 & edad <= 49 & sexo == 2, by(anio)
	egen `nacimien' = sum(poblacion) if edad == 0, by(anio)
	egen `nacimientos' = mean(`nacimien'), by(anio)
	egen `mujeresfert' = mean(`mujeresf'), by(anio)

	g tasafecundidad = `nacimientos'/`mujeresfert'*1000
	tabstat tasafecundidad, stat(mean) by(anio) f(%10.1fc) save
	label var tasafecundidad "Nacimientos por cada mil mujeres"


	** 5. Guardar bases SIM **
	order anio sexo edad entidad poblacion defunciones
	drop cve_geo 
	capture drop __*
	compress
	capture mkdir "SIM/"

	if `c(version)' > 13.1 {
		saveold "SIM/Poblacion.dta", replace version(13)
	}
	else {
		save "SIM/Poblacion.dta", replace
	}

	collapse (sum) poblacion, by(anio entidad)
	keep if entidad == "Nacional"
	if `c(version)' > 13.1 {
		saveold `"SIM/Poblaciontot.dta"', replace version(13)
	}
	else {
		save `"SIM/Poblaciontot.dta"', replace
	}
end