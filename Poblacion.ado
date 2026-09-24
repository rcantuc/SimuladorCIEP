*! version 8.0 CIEP 03jul2026
*!*******************************************
*!***                                    ****
*!***    Poblacion a mitad de año        ****
*!***    Bases: CONAPO pry23 1970-2070   ****
*!***    Autor: Ricardo                  ****
*!***    Version: 8.0                    ****
*!***    Última actualización: 03jul2026 ****
*!***                                    ****
*!***    Sintaxis:                       ****
*!***    Poblacion [if] [, ANIOinicial(int) ANIOFinal(int) NOGraphs UPDATE]
*!*******************************************
program define Poblacion, return
	SIMroot										// raiz del proyecto (global SIMROOT, v8.4)
quietly {
	timer on 2

	capture mkdir `"${SIMROOT}/master"'
	capture mkdir "${SIMROOT}/users/$id/graphs"

	** 0.1 Revisa si se puede usar la base de datos **
	capture use `"${SIMROOT}/master/Poblacion.dta"', clear
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
	syntax [if] [, ANIOinicial(int `aniovp') ANIOFinal(int -1) NOGraphs UPDATE TEXTBOOK]

	* 1.1 Si la opción "update" es llamada, ejecuta el comando UpdatePoblacion (definido al final del archivo) *
	if "`update'" == "update" {
		UpdatePoblacion
	}

	* if default *
	local ifentidad = strpos("`if'","ent")


	************************
	*** 2. Base de datos ***
	************************
	use `if' using `"${SIMROOT}/master/Poblacion.dta"', clear
	if `ifentidad' == 0 {
		keep if entidad == "Nacional"
	}
	
	noisily di _newline(2) in g _dup(30) "." "{bf:   Poblaci{c o'}n: " in y "`=entidad[1]'   }" in g _dup(30) "." ///
		_newline

	* Obtiene el año inicial de la base *
	local aniofirst = anio in 1
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

	scalar aniofinal = `aniofinal'

	** 2.1 Display inicial **
	noisily di in g _col(14) "Total" _col(25) "Hombres" _col(38) "Mujeres" _col(54) "0-17" _col(66) "18-65" _col(81) "65+"
	forvalues k=`anioinicial'(1)`aniofinal' {
		tabstat poblacion if anio == `k', f(%20.0fc) stat(sum) save
		tempname POBTOT
		matrix `POBTOT' = r(StatTotal)
		if `k' == `anioinicial' {
			escalar personas pobtot`entidadGName' = `POBTOT'[1,1]
		}
		if `k' == `aniofinal' {
			escalar personas pobfin`entidadGName' = `POBTOT'[1,1]
		}
		
		capture tabstat poblacion if anio == `k' & sexo == 1, f(%20.0fc) stat(sum) save
		tempname POBHOM
		if _rc == 0 {
			matrix `POBHOM' = r(StatTotal)
		}
		else {
			matrix `POBHOM' = J(1,1,0)
		}

		if "`k'" == "`anioinicial'" {
			escalar personas pobhomI`entidadGName' = `POBHOM'[1,1]
			escalar pct pobhompropI`entidadGName' = `POBHOM'[1,1]/`POBTOT'[1,1]*100
		}
		if "`k'" == "`aniofinal'" {
			escalar personas pobhomF`entidadGName' = `POBHOM'[1,1]
			escalar pct pobhompropF`entidadGName' = `POBHOM'[1,1]/`POBTOT'[1,1]*100
		}
		
		capture tabstat poblacion if anio == `k' & sexo == 2, f(%20.0fc) stat(sum) save
		tempname POBMUJ
		if _rc == 0 {
			matrix `POBMUJ' = r(StatTotal)
		}
		else {
			matrix `POBMUJ' = J(1,1,0)
		}

		if "`k'" == "`anioinicial'" {
			escalar personas pobmujI`entidadGName' = `POBMUJ'[1,1]
			escalar pct pobmujpropI`entidadGName' = `POBMUJ'[1,1]/`POBTOT'[1,1]*100
		}
		if "`k'" == "`aniofinal'" {
			escalar personas pobmujF`entidadGName' = `POBMUJ'[1,1]
			escalar pct pobmujpropF`entidadGName' = `POBMUJ'[1,1]/`POBTOT'[1,1]*100
		}
		
		capture tabstat poblacion if anio == `k' & edad < 18, f(%20.0fc) stat(sum) save
		tempname POB017
		if _rc == 0 {
			matrix `POB017' = r(StatTotal)
		}
		else {
			matrix `POB017' = J(1,1,0)
		}

		if "`k'" == "`anioinicial'" {
			escalar personas pobMenoresI`entidadGName' = `POB017'[1,1]
			escalar pct pobMenorespropI`entidadGName' = `POB017'[1,1]/`POBTOT'[1,1]*100
		}
		if "`k'" == "`aniofinal'" {
			escalar personas pobMenoresF`entidadGName' = `POB017'[1,1]
			escalar pct pobMenorespropF`entidadGName' = `POB017'[1,1]/`POBTOT'[1,1]*100
		}
		
		capture tabstat poblacion if anio == `k' & edad >= 18 & edad < 65, f(%20.0fc) stat(sum) save
		tempname POB1864
		if _rc == 0 {
			matrix `POB1864' = r(StatTotal)
		}
		else {
			matrix `POB1864' = J(1,1,0)
		}

		if "`k'" == "`anioinicial'" {
			escalar personas pobPrimeI`entidadGName' = `POB1864'[1,1]
			escalar pct pobPrimepropI`entidadGName' = `POB1864'[1,1]/`POBTOT'[1,1]*100
		}
		if "`k'" == "`aniofinal'" {
			escalar personas pobPrimeF`entidadGName' = `POB1864'[1,1]
			escalar pct pobPrimepropF`entidadGName' = `POB1864'[1,1]/`POBTOT'[1,1]*100
		}

		capture tabstat poblacion if anio == `k' & edad >= 65, f(%20.0fc) stat(sum) save
		tempname POB65
		if _rc == 0 {
			matrix `POB65' = r(StatTotal)
		}
		else {
			matrix `POB65' = J(1,1,0)
		}

		if "`k'" == "`anioinicial'" {
			escalar personas pobMayoresI`entidadGName' = `POB65'[1,1]
			escalar pct pobMayorespropI`entidadGName' = `POB65'[1,1]/`POBTOT'[1,1]*100
		}
		if "`k'" == "`aniofinal'" {
			escalar personas pobMayoresF`entidadGName' = `POB65'[1,1]
			escalar pct pobMayorespropF`entidadGName' = `POB65'[1,1]/`POBTOT'[1,1]*100
		}

		noisily di in g " " `k' _col(8) in y %12.0fc `POBTOT'[1,1] _col(21) in y %12.0fc `POBHOM'[1,1] _col(34) in y %12.0fc `POBMUJ'[1,1] _col(47) in y %12.0fc `POB017'[1,1] _col(60) in y %12.0fc `POB1864'[1,1] _col(73) in y %12.0fc `POB65'[1,1]
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
		tabstat edad [fw=round(abs(poblacion),1)] if anio == `anioinicial', stat(median) by(sexo) save
		tempname H`anioinicial' M`anioinicial'
		matrix `H`anioinicial'' = r(Stat1)
		matrix `M`anioinicial'' = r(Stat2)

		tabstat edad [fw=round(abs(poblacion),1)] if anio == `aniofinal', stat(median) by(sexo) save
		tempname H`aniofinal' M`aniofinal'
		matrix `H`aniofinal'' = r(Stat1)
		matrix `M`aniofinal'' = r(Stat2)

		* Distribucion inicial *
		capture tabstat poblacion if anio == `anioinicial' & edad < 18, stat(sum) f(%15.0fc) save
		tempname P18_`anioinicial'
		if _rc == 0 {
			matrix `P18_`anioinicial'' = r(StatTotal)
		}
		else {
			matrix `P18_`anioinicial'' = J(1,1,0)
		}

		capture tabstat poblacion if anio == `anioinicial' & edad >= 18 & edad < 65, stat(sum) f(%15.0fc) save
		tempname P1865_`anioinicial'
		if _rc == 0 {
			matrix `P1865_`anioinicial'' = r(StatTotal)
		}
		else {
			matrix `P1865_`anioinicial'' = J(1,1,0)
		}

		capture tabstat poblacion if anio == `anioinicial' & edad >= 65, stat(sum) f(%15.0fc) save
		tempname P65_`anioinicial'
		if _rc == 0 {
			matrix `P65_`anioinicial'' = r(StatTotal)
		}
		else {
			matrix `P65_`anioinicial'' = J(1,1,0)
		}

		capture tabstat poblacion if anio == `anioinicial', stat(sum) f(%15.0fc) save
		tempname P`anioinicial'
		if _rc == 0 {
			matrix `P`anioinicial'' = r(StatTotal)
		}
		else {
			matrix `P`anioinicial'' = J(1,1,0)
		}

		* Distribucion final *
		capture tabstat poblacion if anio == `aniofinal' & edad < 18, stat(sum) f(%15.0fc) save
		tempname P18_`aniofinal'
		if _rc == 0 {
			matrix `P18_`aniofinal'' = r(StatTotal)
		}
		else {
			matrix `P18_`aniofinal'' = J(1,1,0)
		}

		capture tabstat poblacion if anio == `aniofinal' & edad >= 18 & edad < 65, stat(sum) f(%15.0fc) save
		tempname P1865_`aniofinal'
		if _rc == 0 {
			matrix `P1865_`aniofinal'' = r(StatTotal)
		}
		else {
			matrix `P1865_`aniofinal'' = J(1,1,0)
		}

		capture tabstat poblacion if anio == `aniofinal' & edad >= 65, stat(sum) f(%15.0fc) save
		tempname P65_`aniofinal'
		if _rc == 0 {
			matrix `P65_`aniofinal'' = r(StatTotal)
		}
		else {
			matrix `P65_`aniofinal'' = J(1,1,0)
		}

		capture tabstat poblacion if anio == `aniofinal', stat(sum) f(%15.0fc) save
		tempname P`aniofinal'
		if _rc == 0 {
			matrix `P`aniofinal'' = r(StatTotal)
		}
		else {
			matrix `P`aniofinal'' = J(1,1,0)
		}

		* Poblacion viva *
		tempname Pviva
		capture tabstat poblacion if anio == `aniofinal' & edad >= `aniofinal'-`anioinicial', stat(sum) f(%15.0fc) save
		if _rc != 0 {
			matrix `Pviva' = J(1,1,0)
		
		}
		else {
			matrix `Pviva' = r(StatTotal)
		}

		* Población no nacida *
		tempname Pnacida
		capture tabstat poblacion if anio == `aniofinal' & edad < `aniofinal'-`anioinicial', stat(sum) f(%15.0fc) save
		if _rc != 0 {
			matrix `Pnacida' = J(1,1,0)
		
		}
		else {
			matrix `Pnacida' = r(StatTotal)
		}

		* Población hoy *
		tempname Phoy
		capture tabstat poblacion if anio == `anioinicial' & edad < 109 - (`aniofinal'-`anioinicial'), stat(sum) f(%15.0fc) save
		if _rc != 0 {
			matrix `Phoy' = J(1,1,0)
		
		}
		else {
			matrix `Phoy' = r(StatTotal)
		}

		* X label *
		tabstat poblacion if (anio == `anioinicial' | anio == `aniofinal'), stat(max) f(%15.0fc) by(sexo) save
		tempname MaxH MaxM

		matrix `MaxH' = r(Stat1)
		matrix `MaxM' = r(Stat2)
		
		if `MaxH'[1,1] == . {
			matrix `MaxH'[1,1] = 0
		}
		else {
			matrix `MaxH'[1,1] = r(Stat1)[1,1]
		}
		if `MaxM'[1,1] == . {
			matrix `MaxM'[1,1] = 0
		}
		else {
			matrix `MaxM'[1,1] = r(Stat2)[1,1]
		}

		g edad2 = edad
		replace edad2 = . if edad != 5 & edad != 10 & edad != 15 & edad != 20 ///
			& edad != 25 & edad != 30 & edad != 35 & edad != 40 & edad != 45 ///
			& edad != 50 & edad != 55 & edad != 60 & edad != 65 & edad != 70 ///
			& edad != 75 & edad != 80 & edad != 85 & edad != 90 & edad != 95 ///
			& edad != 100 & edad != 105
		g zero = 0

		if "$export" == "" {
			local graphtitle "{bf:Pirámides demográficas}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de CONAPO (2023)."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (bar `pob2' edad if sexo == 1 & anio == `anioinicial' & edad+`aniofinal'-`anioinicial' <= 109, horizontal) ///
			(bar `pob2' edad if sexo == 2 & anio == `anioinicial' & edad+`aniofinal'-`anioinicial' <= 109, horizontal) ///
			(bar `pob2' edad if sexo == 1 & anio == `anioinicial' & edad+`aniofinal'-`anioinicial' > 109, horizontal barwidth(1) bstyle(p1bar)) ///
			(bar `pob2' edad if sexo == 2 & anio == `anioinicial' & edad+`aniofinal'-`anioinicial' > 109, horizontal barwidth(1) bstyle(p2bar)) ///
			(sc edad2 zero if anio == `anioinicial', msymbol(i) mlabel(edad2) mlabsize(vsmall) mlabcolor("114 113 118")), ///
			legend(label(1 "Hombres") label(2 "Mujeres")) ///
			legend(off order(1 2) rows(1) region(margin(zero))) ///
			yscale(noline) ylabel(none) xscale(noline) ///
			text(105 `=-`MaxH'[1,1]*.5' "{bf:Edad mediana}") ///
			text(97.5 `=-`MaxH'[1,1]*.5' "Hombres: `=`H`anioinicial''[1,1]'") ///
			text(90 `=-`MaxH'[1,1]*.5' "Mujeres: `=`M`anioinicial''[1,1]'") ///
			text(`=(109-(`aniofinal'-`anioinicial'))/2' `=-`MaxH'[1,1]*.35' "{bf: `=entidad[1]'}", size(huge) color("111 111 111")) ///
			text(`=(109-(`aniofinal'-`anioinicial'))/2' `=`MaxH'[1,1]*.35' `"`=string(`P`anioinicial''[1,1],"%20.0fc")'"', size(huge) color("111 111 111")) ///
			text(105 `=`MaxH'[1,1]*.5' "{bf:Estructura poblacional}") ///
			text(97.5 `=`MaxH'[1,1]*.5' "0-18: `=string(`P18_`anioinicial''[1,1]/`P`anioinicial''[1,1]*100,"%7.1fc")'%") ///
			text(90 `=`MaxH'[1,1]*.5' "19-65: `=string(`P1865_`anioinicial''[1,1]/`P`anioinicial''[1,1]*100,"%7.1fc")'%") ///
			text(82.5 `=`MaxH'[1,1]*.5' "65+: `=string(`P65_`anioinicial''[1,1]/`P`anioinicial''[1,1]*100,"%7.1fc")'%") ///
			name(P_`anioinicial'_`aniofinal'_`entidadGName'A, replace) ///
			xlabel(`=-`MaxH'[1,1]' `"`=string(`MaxH'[1,1],"%15.0fc")'"' ///
			`=-`MaxH'[1,1]/2' `"Hombres"' 0 ///
			`=`MaxM'[1,1]/2' `"Mujeres"' ///
			`=`MaxM'[1,1]' `"`=string(`MaxM'[1,1],"%15.0fc")'"', angle(horizontal) labsize(small)) ///
			title(`"{bf:`anioinicial'}"')

		twoway (bar `pob2' edad if sexo == 1 & anio == `aniofinal' & edad < `aniofinal'-`anioinicial', horizontal barwidth(.5)) ///
			(bar `pob2' edad if sexo == 2 & anio == `aniofinal' & edad < `aniofinal'-`anioinicial', horizontal barwidth(.5)) ///
			(bar `pob2' edad if sexo == 1 & anio == `aniofinal' & edad >= `aniofinal'-`anioinicial', horizontal barwidth(1) bstyle(p1bar)) ///
			(bar `pob2' edad if sexo == 2 & anio == `aniofinal' & edad >= `aniofinal'-`anioinicial', horizontal barwidth(1) bstyle(p2bar)) ///
			(sc edad2 zero if anio == `anioinicial', msymbol(i) mlabel(edad2) mlabsize(vsmall) mlabcolor("114 113 118")), ///
			legend(label(1 "Hombres") label(2 "Mujeres")) ///
			legend(off order(1 2) rows(1) region(margin(zero))) ///
			yscale(noline) ylabel(none) xscale(noline) ///
			text(`=((`aniofinal'-`anioinicial'))/2' `=-`MaxH'[1,1]*.35' "{bf: Por nacer}", size(huge) color("111 111 111")) ///
			text(`=((`aniofinal'-`anioinicial'))/2' `=`MaxH'[1,1]*.35' `"`=string(`Pnacida'[1,1],"%20.0fc")'"', size(huge) color("111 111 111")) ///
			text(`=(`aniofinal'-`anioinicial')+(109-(`aniofinal'-`anioinicial'))/2' `=-`MaxH'[1,1]*.35' "{bf: Vivos en `anioinicial'}", size(huge) color("111 111 111")) ///
			text(`=(`aniofinal'-`anioinicial')+(109-(`aniofinal'-`anioinicial'))/2' `=`MaxH'[1,1]*.35' `"`=string(`Pviva'[1,1],"%20.0fc")'"', size(huge) color("111 111 111")) ///
			text(105 `=-`MaxH'[1,1]*.5' "{bf:Edad mediana}") ///
			text(97.5 `=-`MaxH'[1,1]*.5' "Hombres: `=`H`aniofinal''[1,1]'") ///
			text(90 `=-`MaxH'[1,1]*.5' "Mujeres: `=`M`aniofinal''[1,1]'") ///
			text(105 `=`MaxH'[1,1]*.5' "{bf:Estructura poblacional}") ///
			text(97.5 `=`MaxH'[1,1]*.5' "0-18: `=string(`P18_`aniofinal''[1,1]/`P`aniofinal''[1,1]*100,"%7.1fc")'%") ///
			text(90 `=`MaxH'[1,1]*.5' "19-65: `=string(`P1865_`aniofinal''[1,1]/`P`aniofinal''[1,1]*100,"%7.1fc")'%") ///
			text(82.5 `=`MaxH'[1,1]*.5' "65+: `=string(`P65_`aniofinal''[1,1]/`P`aniofinal''[1,1]*100,"%7.1fc")'%") ///
			name(P_`anioinicial'_`aniofinal'_`entidadGName'B, replace) ///
			xlabel(`=-`MaxH'[1,1]' `"`=string(`MaxH'[1,1],"%15.0fc")'"' ///
			`=-`MaxH'[1,1]/2' `"Hombres"' 0 ///
			`=`MaxM'[1,1]/2' `"Mujeres"' ///
			`=`MaxM'[1,1]' `"`=string(`MaxM'[1,1],"%15.0fc")'"', angle(horizontal) labsize(small)) ///
			title(`"{bf:`aniofinal'}"')

		graph combine P_`anioinicial'_`aniofinal'_`entidadGName'A P_`anioinicial'_`aniofinal'_`entidadGName'B, ///
			title("`graphtitle'") ///
			caption("`graphfuente'") ///
			name(PP_`anioinicial'_`aniofinal'_`entidadGName', replace)

		if "$export" != "" {
			graph export "$export/PP_`anioinicial'_`aniofinal'_`entidadGName'.png", replace name(PP_`anioinicial'_`aniofinal'_`entidadGName')
		}
		else {
			graph export "${SIMROOT}/users/$id/graphs/PP_`anioinicial'_`aniofinal'_`entidadGName'.png", replace name(PP_`anioinicial'_`aniofinal'_`entidadGName')
		}
		
		if "$export" != "" {
			graph export "$export/PA_`anioinicial'_`aniofinal'_`entidadGName'.png", replace name(P_`anioinicial'_`aniofinal'_`entidadGName'A)
		}
		else {
			graph export "${SIMROOT}/users/$id/graphs/PA_`anioinicial'_`aniofinal'_`entidadGName'.png", replace name(P_`anioinicial'_`aniofinal'_`entidadGName'A)
		}
		
		if "$export" != "" {
			graph export "$export/PB_`anioinicial'_`aniofinal'_`entidadGName'.png", replace name(P_`anioinicial'_`aniofinal'_`entidadGName'B)
		}
		else {
			graph export "${SIMROOT}/users/$id/graphs/PB_`anioinicial'_`aniofinal'_`entidadGName'.png", replace name(P_`anioinicial'_`aniofinal'_`entidadGName'B)
		}

		capture window manage close graph P_`anioinicial'_`aniofinal'_`entidadGName'A
		capture window manage close graph P_`anioinicial'_`aniofinal'_`entidadGName'B



		*****************************************
		*** 4. Gráfica transición demográfica ***
		*****************************************
		g pob18 = poblacion if edad <= 18
		g pob1860 = poblacion if edad > 18 & edad <= 60
		g pob60 = poblacion if edad > 60

		collapse (sum) pob18 pob1860 pob60 poblacion*, by(anio entidad)
		format poblacion pob* %15.0fc

		* Distribucion *
		g pob18_2 = pob18/poblacion*100
		g pob1860_2 = pob1860/poblacion*100
		g pob60_2 = pob60/poblacion*100

		* Valores maximos *
		tabstat pob18_2 pob1860_2 pob60_2 if anio <= `aniofinal', stat(max min) save
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
			if pob1860_2[`k'] == `MAX'[1,2] {
				local x2 = anio[`k']
				local y2 = (pob1860[`k'] + pob18[`k'])/1000000
				local p2 = `k'
			}
			if pob60_2[`k'] == `MAX'[1,3] {
				local x3 = anio[`k']
				local y3 = (pob60[`k'] + pob1860[`k'] + pob18[`k'])/1000000
				local p3 = `k'
			}
			
			* Minimos *
			* Busca la población mínima y guarda el año y el número *
			if pob18_2[`k'] == `MAX'[2,1] {
				local m1 = anio[`k']
				local z1 = (pob18[`k']/2)/1000000
				local q1 = `k'
			}
			if pob1860_2[`k'] == `MAX'[2,2] {
				local m2 = anio[`k']
				local z2 = (pob1860[`k']/2 + pob18[`k'])/1000000
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
			if pob60_2[`k'] == `MAX'[2,3] {
				local m3 = anio[`k']
				local z3 = (pob60[`k'] + pob1860[`k'] + pob18[`k'])/1000000
				local q3 = `k'
			}
		}

		tempvar pob18 pob1860 pob60
		g `pob18' = pob18/1000000
		g `pob1860' = (pob1860 + pob18)/1000000
		g `pob60' = (pob60 + pob1860 + pob18)/1000000

		local graphtitle "{bf:Transici{c o'}n demogr{c a'}fica}"
		local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de CONAPO (2023)."
		twoway (area `pob60' `pob1860' `pob18' anio if anio <= `anioinicial') ///
			(area `pob60' anio if anio > `anioinicial' & anio <= `aniofinal', astyle(p1area)) ///
			(area `pob1860' anio if anio > `anioinicial' & anio <= `aniofinal', astyle(p2area)) ///
			(area `pob18' anio if anio > `anioinicial' & anio <= `aniofinal', astyle(p3area)), ///
			text(`y1' `x1' `"{bf:Max (0-18):} `=string(`MAX'[1,1],"%5.1fc")' % (`x1')"', place(s) size(medlarge) color("111 111 111")) ///
			text(`y2' `x2' `"{bf:Max (19-60):} `=string(`MAX'[1,2],"%5.1fc")' % (`x2')"', place(s) size(medlarge) color("111 111 111")) ///
			text(`y3' `x3' `"{bf:Max (61+):} `=string(`MAX'[1,3],"%5.1fc")' % (`x3')"', place(nw) size(medlarge) color("111 111 111")) ///
			///text(`z1' `m1' `"{bf:Min (0-18):} `=string(`MAX'[2,1],"%5.1fc")' % (`m1')"', place(w) size(medlarge) color("111 111 111")) ///
			///text(`z2' `m2' `"{bf:Min (19-60):} `=string(`MAX'[2,2],"%5.1fc")' % (`m2')"', place(`place21') size(medlarge) color("111 111 111")) ///
			///text(`z3' `m3' `"{bf:Min (61+):} `=string(`MAX'[2,3],"%5.1fc")' % (`m3')"', place(ne) size(medlarge) color("111 111 111")) ///
			text(`=`POBTOT'[1,1]/1000000*.015' `=`anioinicial'-.5' "{bf:`anioinicial'}", place(nw)) ///
			xtitle("") ///
			ytitle("millones de personas") ///
			xline(`=`anioinicial'+.5') ///
			///title("`graphtitle'") ///
			title("{bf:`=entidad[1]'}") ///
			///caption("`graphfuente'") ///
			legend(on label(1 "61 y más") label(2 "19 -- 60") label(3 "18 y menos") order(- "{bf:Edades:}" 3 2 1) ///
			position(6) region(margin(zero)) rows(1)) ///
			ylabel(, format(%20.0fc)) yscale(range(0)) ///
			xlabel(`aniofirst'(10)`aniofinal') ///
			name(E_`anioinicial'_`aniofinal'_`entidadGName', replace)



		*****************************************
		*** 5. Gráfica de tasa de dependencia ***
		*****************************************
		g tasaDependencia = (pob18 + pob60)/(pob1860)*100
		format tasaDependencia %10.0fc

		tabstat tasaDependencia, stat(min max) save
		forvalues k = 1(1)`=_N' {
			if tasaDependencia[`k'] == r(StatTotal)[1,1] {
				escalar anio aniotdmin = anio[`k']
				local aniotdmin = `k'
			}
			if tasaDependencia[`k'] == r(StatTotal)[2,1] {
				escalar anio aniotdmax = anio[`k']
				local aniotdmax = `k'
			}
			if anio[`k'] == `anioinicial' {
				local obsini = `k'
			}
		}

		noisily di _newline in g " Año con mayor tasa de dependencia: " in y aniotdmax
		noisily di in g " Año con menor tasa de dependencia: " in y aniotdmin

		twoway (connected tasaDependencia anio if anio >= 1950 & anio <= `anioinicial') ///
			(connected tasaDependencia anio if anio > `anioinicial' & anio <= `aniofinal'), ///
			///title("`graphtitle'") ///
			title("{bf:Dependientes por c/100 personas en edad de trabajar}") ///
			///caption("`graphfuente'") ///
			xtitle("") ///
			text(`=tasaDependencia[`obsini']' `=anio[`obsini']' "{bf:`anioinicial'}: `=string(tasaDependencia[`obsini'],"%7.2fc")'", place(n) size(large) color("111 111 111")) ///
			text(`=tasaDependencia[`aniotdmin']' `=anio[`aniotdmin']' "{bf:Min (`=anio[`aniotdmin']')}: `=string(tasaDependencia[`aniotdmin'],"%7.2fc")'", place(s) size(large) color("111 111 111")) ///
			text(`=tasaDependencia[`aniotdmax']' `=anio[`aniotdmax']' "{bf:Max (`=anio[`aniotdmax']')}: `=string(tasaDependencia[`aniotdmax'],"%7.2fc")'", place(n) size(large) color("111 111 111")) ///
			///xlabel(`=round(`anioinicial',5)'(5)`=round(`aniofinal',5)') ///
			xlabel(`aniofirst'(10)`aniofinal') ///
			ytitle("") ///
			yscale(range(65)) ///
			///ylabel(, format(%10.0fc)) ///
			legend(off label(1 "Observado") label(2 "Proyectado") region(margin(zero)) rows(1)) ///
			name(T_`anioinicial'_`aniofinal'_`entidadGName', replace)

		if "$export" == "" {
			local graphtitle "{bf:Tasa de dependencia}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de CONAPO (2023)."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		graph combine E_`anioinicial'_`aniofinal'_`entidadGName' T_`anioinicial'_`aniofinal'_`entidadGName', ///
			title("`graphtitle'") ///
			caption("`graphfuente'") ///
			name(ET_`anioinicial'_`aniofinal'_`entidadGName', replace)


		if "$export" != "" {
			graph export "$export/ET_`anioinicial'_`aniofinal'_`entidadGName'.png", replace name(ET_`anioinicial'_`aniofinal'_`entidadGName')
		}
		else {
			graph export "${SIMROOT}/users/$id/graphs/ET_`anioinicial'_`aniofinal'_`entidadGName'.png", replace name(ET_`anioinicial'_`aniofinal'_`entidadGName')
		}
		if "$export" != "" {
			graph export "$export/T_`anioinicial'_`aniofinal'_`entidadGName'.png", replace name(T_`anioinicial'_`aniofinal'_`entidadGName')
		}
		else {
			graph export "${SIMROOT}/users/$id/graphs/T_`anioinicial'_`aniofinal'_`entidadGName'.png", replace name(T_`anioinicial'_`aniofinal'_`entidadGName')
		}
		if "$export" != "" {
			graph export "$export/E_`anioinicial'_`aniofinal'_`entidadGName'.png", replace name(E_`anioinicial'_`aniofinal'_`entidadGName')
		}
		else {
			graph export "${SIMROOT}/users/$id/graphs/E_`anioinicial'_`aniofinal'_`entidadGName'.png", replace name(E_`anioinicial'_`aniofinal'_`entidadGName')
		}

		capture window manage close graph E_`anioinicial'_`aniofinal'_`entidadGName'
		capture window manage close graph T_`anioinicial'_`aniofinal'_`entidadGName'
		restore
	}

	if "`textbook'" == "textbook" {
		capture which scalarlatex
		if _rc {
			noisily di in g "Nota: la opcion textbook (scalarlatex) es solo-repo; no viaja al endpoint publico."
		}
		else {
			noisily scalarlatex, log(poblacion) alt(pob)
		}
	}

	** END **
	timer off 2
	timer list 2
	noisily di _newline in g "Tiempo: " in y round(`=r(t2)/r(nt2)',.1) in g " segs  "
}
end





****************************************************************************************
****                                                                                ****
****   Base de datos de Mexico: Población a mitad de año (CONAPO pry23 vía DGIS)   ****
****                                                                                ****
****************************************************************************************
program define UpdatePoblacion
	SIMroot										// raiz del proyecto (global SIMROOT, v8.4)
	noisily di in g "  Updating Poblacion.dta..." _newline

	* FUENTE (v8.4.1). CONAPO, Conciliación Demográfica de México 1970-2019 y
	* Proyecciones de la población de México y de las entidades federativas
	* 2020-2070 (pry23, publicadas el 11-sep-2023). Hasta v8.4.0 se leían en vivo
	* los tres CSV de conapo.segob.gob.mx/work/models/CONAPO/Datos_Abiertos/pry23/
	* (00_Pob_Mitad_1950_2070, 01_Defunciones_1950_2070,
	* 02_mig_inter_quinquen_proyecciones); CONAPO dejó de servirlos en sep-2026.
	* La misma proyección la redistribuye la DGIS-Salud en
	*   http://www.dgis.salud.gob.mx/descargas/datosabiertos/poblacion/proyecciones_censo/Poblacion_Estimada_Mitad_Anio.zip
	* y viaja como asset del data sidecar (05_scripts/manifest.json, SHA-256
	* verificado por ensure_asset), para que la reconstrucción no dependa de un
	* servidor de gobierno. Cobertura 1970-2070 (antes 1950-2070); las 555,500
	* celdas comunes coinciden exactamente con el vintage anterior. Ya no se
	* traen defunciones ni migración internacional: ningún módulo las consumía.



	********************
	*** A. Poblacion ***
	********************

	** 1. Base de datos (asset del sidecar) **
	ensure_asset "Poblacion_Estimada_Mitad_Anio.zip"
	capture mkdir "${SIMROOT}/raw/temp"
	capture mkdir "${SIMROOT}/raw/temp/CONAPO"
	local here `"`c(pwd)'"'
	quietly cd "${SIMROOT}/raw/temp/CONAPO"
	unzipfile "${SIMROOT}/raw/CONAPO/Poblacion_Estimada_Mitad_Anio.zip", replace
	quietly cd `"`here'"'
	import delimited "${SIMROOT}/raw/temp/CONAPO/Poblacion_Estimada_Mitad_Anio.csv", ///
		clear varnames(1) encoding(utf-8) case(lower)


	** 2. Limpia **
	keep anio clave_entidad clave_edad clave_sexo poblacion_a_mitad_anio
	rename (clave_entidad clave_edad clave_sexo poblacion_a_mitad_anio) (cve_geo edad sexo poblacion)
	destring anio cve_geo edad sexo poblacion, replace

	label define sexo 1 "Hombres" 2 "Mujeres"
	label values sexo sexo

	* Nombres de entidad como los usa el Simulador (mismos que el vintage CONAPO) *
	g entidad = ""
	replace entidad = "Aguascalientes"      if cve_geo == 1
	replace entidad = "Baja California"     if cve_geo == 2
	replace entidad = "Baja California Sur" if cve_geo == 3
	replace entidad = "Campeche"            if cve_geo == 4
	replace entidad = "Coahuila"            if cve_geo == 5
	replace entidad = "Colima"              if cve_geo == 6
	replace entidad = "Chiapas"             if cve_geo == 7
	replace entidad = "Chihuahua"           if cve_geo == 8
	replace entidad = "Ciudad de México"    if cve_geo == 9
	replace entidad = "Durango"             if cve_geo == 10
	replace entidad = "Guanajuato"          if cve_geo == 11
	replace entidad = "Guerrero"            if cve_geo == 12
	replace entidad = "Hidalgo"             if cve_geo == 13
	replace entidad = "Jalisco"             if cve_geo == 14
	replace entidad = "Estado de México"    if cve_geo == 15
	replace entidad = "Michoacán"           if cve_geo == 16
	replace entidad = "Morelos"             if cve_geo == 17
	replace entidad = "Nayarit"             if cve_geo == 18
	replace entidad = "Nuevo León"          if cve_geo == 19
	replace entidad = "Oaxaca"              if cve_geo == 20
	replace entidad = "Puebla"              if cve_geo == 21
	replace entidad = "Querétaro"           if cve_geo == 22
	replace entidad = "Quintana Roo"        if cve_geo == 23
	replace entidad = "San Luis Potosí"     if cve_geo == 24
	replace entidad = "Sinaloa"             if cve_geo == 25
	replace entidad = "Sonora"              if cve_geo == 26
	replace entidad = "Tabasco"             if cve_geo == 27
	replace entidad = "Tamaulipas"          if cve_geo == 28
	replace entidad = "Tlaxcala"            if cve_geo == 29
	replace entidad = "Veracruz"            if cve_geo == 30
	replace entidad = "Yucatán"             if cve_geo == 31
	replace entidad = "Zacatecas"           if cve_geo == 32
	assert entidad != ""
	replace poblacion = 0 if poblacion == .


	** 3. Nacional = suma de las 32 entidades (CONAPO publicaba la fila "República Mexicana") **
	preserve
		collapse (sum) poblacion, by(anio edad sexo)
		g entidad = "Nacional"
		g cve_geo = 0
		tempfile nacional
		save "`nacional'"
	restore
	append using "`nacional'"
	isid anio edad sexo entidad
	sort anio edad sexo entidad



	***********************
	*** B. Labels y tasa ***
	***********************

	** 1. Labels y formato *
	label var anio "Año"
	label var sexo "Sexo"
	label var edad "Edad"
	label var entidad "Entidad federativa"
	label var poblacion "Población"
	format poblacion %15.0fc


	** 2. Tasa de fertilidad **
	tempvar mujeresf nacimien nacimientos mujeresfert
	egen `mujeresf' = sum(poblacion) if edad >= 16 & edad <= 49 & sexo == 2, by(anio)
	egen `nacimien' = sum(poblacion) if edad == 0, by(anio)
	egen `nacimientos' = mean(`nacimien'), by(anio)
	egen `mujeresfert' = mean(`mujeresf'), by(anio)

	g tasafecundidad = `nacimientos'/`mujeresfert'*1000
	tabstat tasafecundidad, stat(mean) by(anio) f(%10.1fc) save
	label var tasafecundidad "Nacimientos por cada mil mujeres"


	** 3. Guardar bases SIM **
	order anio sexo edad entidad poblacion
	drop cve_geo
	capture drop __*
	compress

	if `c(version)' > 13.1 {
		saveold "${SIMROOT}/master/Poblacion.dta", replace version(13)
	}
	else {
		save "${SIMROOT}/master/Poblacion.dta", replace
	}

	collapse (sum) poblacion, by(anio entidad)
	keep if entidad == "Nacional"
	if `c(version)' > 13.1 {
		saveold `"${SIMROOT}/master/Poblaciontot.dta"', replace version(13)
	}
	else {
		save `"${SIMROOT}/master/Poblaciontot.dta"', replace
	}
end
