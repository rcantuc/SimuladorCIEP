*! Poblacion.ado: 4 de diciembre de 2019. Autor: Ricardo Cantú
program define Poblacion
quietly {

	version 13.1

	local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)

	syntax [anything] [, ANIOinicial(int `aniovp') ANIOFinal(int -1) Graphs UPDATE]

	* Si la funcion se llama sin argumento, utiliza población *
	if "`anything'" == "" {
		local anything = "poblacion"
	}

	*Si no hay año inicial utiliza la fecha más reciente*
	if `anioinicial' == -1 {
		local anioinicial : di %td_CY-N-D  date("$S_DATE", "DMY")
		local anioinicial = substr(`"`=trim("`aniovp'")'"',1,4)
	}


	************************
	*** 0. Base de datos ***
	************************

	* Revisa si se puede usar la base de datos *
	capture use `"`c(sysdir_site)'../basesCIEP/SIM/`=proper("`anything'")'`=subinstr("${pais}"," ","",.)'.dta"', clear

	* Si hay un error o la opción "update" es llamada, limpia la base de datos y la usa *
	if _rc != 0 | "`update'" == "update" {
		run `"`c(sysdir_personal)'/PoblacionBase`=subinstr("${pais}"," ","",.)'.do"'
		use `"`c(sysdir_site)'../basesCIEP/SIM/`=proper("`anything'")'`=subinstr("${pais}"," ","",.)'.dta"', clear
	}

	* Si no hay año final, utiliza el último elemento del vector "anio" *
	local poblacion : variable label `anything'
	if `aniofinal' == -1 {
		sort anio
		local aniofinal = anio[_N]
	}



	****************
	* EstadÃ­sticos *
	****************
	
	* Calcula las estadísticas descriptivas y las guarda en matrices *
	
	* Mediana *
	tabstat edad [fw=round(abs(`anything'),1)] if anio == `anioinicial', ///
		stat(median) by(sexo) save
	tempname H`anioinicial' M`anioinicial'
	matrix `H`anioinicial'' = r(Stat1)
	matrix `M`anioinicial'' = r(Stat2)

	tabstat edad [fw=round(abs(`anything'),1)] if anio == `aniofinal', ///
		stat(median) by(sexo) save
	tempname H`aniofinal' M`aniofinal'
	matrix `H`aniofinal'' = r(Stat1)
	matrix `M`aniofinal'' = r(Stat2)

	* Distribucion inicial *
	tabstat `anything' if anio == `anioinicial' & edad < 18, ///
		stat(sum) f(%15.0fc) save
	tempname P18_`anioinicial'
	matrix `P18_`anioinicial'' = r(StatTotal)

	tabstat `anything' if anio == `anioinicial' & edad >= 18 & edad < 65, ///
		stat(sum) f(%15.0fc) save
	tempname P1865_`anioinicial'
	matrix `P1865_`anioinicial'' = r(StatTotal)

	tabstat `anything' if anio == `anioinicial' & edad >= 65, ///
		stat(sum) f(%15.0fc) save
	tempname P65_`anioinicial'
	matrix `P65_`anioinicial'' = r(StatTotal)

	tabstat `anything' if anio == `anioinicial', stat(sum) f(%15.0fc) save
	tempname P`anioinicial'
	matrix `P`anioinicial'' = r(StatTotal)

	* Distribucion final *
	tabstat `anything' if anio == `aniofinal' & edad < 18, ///
		stat(sum) f(%15.0fc) save
	tempname P18_`aniofinal'
	matrix `P18_`aniofinal'' = r(StatTotal)

	tabstat `anything' if anio == `aniofinal' & edad >= 18 & edad < 65, ///
		stat(sum) f(%15.0fc) save
	tempname P1865_`aniofinal'
	matrix `P1865_`aniofinal'' = r(StatTotal)

	tabstat `anything' if anio == `aniofinal' & edad >= 65, ///
		stat(sum) f(%15.0fc) save
	tempname P65_`aniofinal'
	matrix `P65_`aniofinal'' = r(StatTotal)

	tabstat `anything' if anio == `aniofinal', stat(sum) f(%15.0fc) save
	tempname P`aniofinal'
	matrix `P`aniofinal'' = r(StatTotal)

	* Poblacion viva *
	tabstat `anything' if anio == `aniofinal' & edad > `aniofinal'-`anioinicial', ///
		stat(sum) f(%15.0fc) save
	tempname Pviva
	matrix `Pviva' = r(StatTotal)

	tabstat `anything' if anio == `aniofinal' & edad <= `aniofinal'-`anioinicial', ///
		stat(sum) f(%15.0fc) save
	tempname Pnacida
	matrix `Pnacida' = r(StatTotal)

	preserve



	***********************
	* Grafica 1: Piramide *
	***********************
	if "$graphs" == "on" | "`graphs'" == "graphs" {

		* Variables a graficar *
		tempvar pob2
		g `pob2' = -`anything' if sexo == 1
		replace `pob2' = `anything' if sexo == 2
		format `pob2' %10.0fc

		* X label *
		tabstat `anything' if (anio == `anioinicial' | anio == `aniofinal'), ///
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
		twoway (bar `pob2' edad if sexo == 1 & anio == `anioinicial' ///
			& edad+`aniofinal'-`anioinicial' <= 109, horizontal lwidth(none)) ///
			(bar `pob2' edad if sexo == 2 & anio == `anioinicial' ///
			& edad+`aniofinal'-`anioinicial' <= 109, horizontal lwidth(none)) ///
			(bar `pob2' edad if sexo == 1 & anio == `aniofinal' ///
			& edad <= `aniofinal'-`anioinicial', horizontal barwidth(.15) ///
			lwidth(none) /*color("83 144 0")*/) ///
			(bar `pob2' edad if sexo == 2 & anio == `aniofinal' ///
			& edad <= `aniofinal'-`anioinicial', horizontal barwidth(.15) ///
			lwidth(none) /*color("149 191 75")*/) ///
			(bar `pob2' edad if sexo == 1 & anio == `aniofinal' ///
			& edad > `aniofinal'-`anioinicial', horizontal barwidth(.66) ///
			lwidth(none) color("255 107 24")) ///
			(bar `pob2' edad if sexo == 2 & anio == `aniofinal' ///
			& edad > `aniofinal'-`anioinicial', horizontal barwidth(.66) ///
			lwidth(none) color("255 189 0")) ///
			(bar `pob2' edad if sexo == 1 & anio == `anioinicial' ///
			& edad+`aniofinal'-`anioinicial' > 109, horizontal barwidth(.5) ///
			lwidth(none)) ///
			(bar `pob2' edad if sexo == 2 & anio == `anioinicial' ///
			& edad+`aniofinal'-`anioinicial' > 109, horizontal barwidth(.5) ///
			lwidth(none)) ///
			(sc edad2 zero if anio == `anioinicial', msymbol(i) mlabel(edad2) ///
			mlabsize(vsmall) mlabcolor("114 113 118")), ///
			legend(label(1 "Hombres") label(2 "Mujeres") ///
			label(3 "Hombres nacidos desde `anioinicial'") ///
			label(4 "Mujeres nacidas desde `anioinicial'")) ///
			legend(label(5 "Hombres `aniofinal'") label(6 "Mujeres `aniofinal'") ///
			label(7 "Hombres fallecidos para `aniofinal'") ///
			label(8 "Mujeres fallecidas para `aniofinal'")) ///
			legend(order(1 2 3 4 7 8) holes(1 4) rows(2) on) ///
			yscale(noline) ylabel(none) xscale(noline) ///
			text(105 `=-`MaxH'[1,1]*.6' "{bf:Edad mediana `anioinicial'}") ///
			text(100 `=-`MaxH'[1,1]*.6' "Hombres: `=`H`anioinicial''[1,1]'") ///
			text(95 `=-`MaxH'[1,1]*.6' "Mujeres: `=`M`anioinicial''[1,1]'") ///
			text(105 `=`MaxH'[1,1]*.6' "{bf:Edad mediana `aniofinal'}") ///
			text(100 `=`MaxH'[1,1]*.6' "Hombres: `=`H`aniofinal''[1,1]'") ///
			text(95 `=`MaxH'[1,1]*.6' "Mujeres: `=`M`aniofinal''[1,1]'") ///
			text(90 `=-`MaxH'[1,1]*.6' "{bf:Poblaci{c o'}n `anioinicial'}") ///
			text(85 `=-`MaxH'[1,1]*.6' `"`=string(`P`anioinicial''[1,1],"%20.0fc")'"') ///
			text(80 `=-`MaxH'[1,1]*.6' "{bf: Poblaci{c o'}n `anioinicial' viva en `aniofinal'} ") ///
			text(75 `=-`MaxH'[1,1]*.6' `"`=string(`Pviva'[1,1],"%20.0fc")' (`=string(`Pviva'[1,1]/`P`anioinicial''[1,1]*100,"%7.1fc")'%)"') ///
			text(90 `=`MaxH'[1,1]*.6' "{bf:Poblaci{c o'}n `aniofinal'}") ///
			text(85 `=`MaxH'[1,1]*.6' `"`=string(`P`aniofinal''[1,1],"%20.0fc")'"') ///
			text(80 `=`MaxH'[1,1]*.6' "{bf:Poblaci{c o'}n `aniofinal' nacida desde `anioinicial'} ") ///
			text(75 `=`MaxH'[1,1]*.6' `"`=string(`Pnacida'[1,1],"%20.0fc")' (`=string(`Pnacida'[1,1]/`P`aniofinal''[1,1]*100,"%7.1fc")'%)"') ///
			name(Piramide_`anything'_`anioinicial'_`aniofinal', replace) ///
			xlabel(`=-`MaxH'[1,1]' `"`=string(`MaxH'[1,1],"%15.0fc")'"' ///
			`=-`MaxH'[1,1]/2' `"`=string(`MaxH'[1,1]/2,"%15.0fc")'"' 0 ///
			`=`MaxM'[1,1]/2' `"`=string(`MaxM'[1,1]/2,"%15.0fc")'"' ///
			`=`MaxM'[1,1]' `"`=string(`MaxM'[1,1],"%15.0fc")'"', angle(horizontal)) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			/*xtitle("personas")*/ ///
			title("{bf:Pir{c a'}mide demogr{c a'}fica}") subtitle(${pais})

		if "$export" != "" {
			graph export "$export/Piramide_`anything'_`anioinicial'_`aniofinal'.png", ///
				replace name(Piramide_`anything'_`anioinicial'_`aniofinal')
		}

	}



	***************************************
	** GrÃ¡fica 2: TransiciÃ³n demogrÃ¡fica **
	***************************************
	g pob18 = `anything' if edad <= 18
	g pob1934 = `anything' if edad >= 19 & edad <= 34
	g pob3560 = `anything' if edad >= 35 & edad <= 60
	g pob61 = `anything' if edad >= 61

	collapse (sum) pob18 pob1934 pob3560 pob61 `anything', by(anio)
	format `anything' pob* %15.0fc

	* Distribucion *
	g pob18_2 = pob18/`anything'*100
	g pob1934_2 = pob1934/`anything'*100
	g pob3560_2 = pob3560/`anything'*100
	g pob61_2 = pob61/`anything'*100

	* Valores maximos *
	tabstat pob18_2 pob1934_2 pob3560_2 pob61_2, stat(max min) save
	tempname MAX
	matrix `MAX' = r(StatTotal)

	* Valores finales *
	tabstat pob18 pob1934 pob3560 pob61 if anio == `aniofinal', stat(mean) save
	tempname FIN
	matrix `FIN' = r(StatTotal)

	forvalues k = 1(1)`=_N' {
		* Maximos *
		
		* Busca la población máxima y guarda el año y el número *
		
		if pob18_2[`k'] == `MAX'[1,1] {
			local x1 = anio[`k']
			local y1 = pob18[`k']
		}
		if pob1934_2[`k'] == `MAX'[1,2] {
			local x2 = anio[`k']
			local y2 = pob1934[`k']
		}
		if pob3560_2[`k'] == `MAX'[1,3] {
			local x3 = anio[`k']
			local y3 = pob3560[`k']
		}
		if pob61_2[`k'] == `MAX'[1,4] {
			local x4 = anio[`k']
			local y4 = pob61[`k']
		}
		
		* Minimos *
		
		* Busca la población mínima y guarda el año y el número *
		
		if pob18_2[`k'] == `MAX'[2,1] {
			local m1 = anio[`k']
			local z1 = pob18[`k']
		}
		if pob1934_2[`k'] == `MAX'[2,2] {
			local m2 = anio[`k']
			local z2 = pob1934[`k']
		}
		if pob3560_2[`k'] == `MAX'[2,3] {
			local m3 = anio[`k']
			local z3 = pob3560[`k']
		}		
		if pob61_2[`k'] == `MAX'[2,4] {
			local m4 = anio[`k']
			local z4 = pob61[`k']
		}
	}

	if "$graphs" == "on" | "`graphs'" == "graphs" {
		twoway (line pob18_2 anio) (line pob1934_2 anio) (line pob3560_2 anio) (line pob61_2 anio), ///
			legend(label(1 "0-18") label(2 "19-34") label(3 "35-60") label(4 "61+") cols(4)) ///
			text(`=`MAX'[1,1]+2.5' `x1' `"{bf:Max:} `=string(`MAX'[1,1],"%5.1fc")' % (`x1')"', place(ne)) ///
			text(`=`MAX'[1,1]' `x1' `"{bf:`poblacion':} `=string(`y1',"%12.0fc")'"', place(ne)) ///
			text(`=`MAX'[1,2]+2.5' `x2' `"{bf:Max:} `=string(`MAX'[1,2],"%5.1fc")' % (`x2')"', place(nw)) ///
			text(`=`MAX'[1,2]' `x2' `"{bf:`poblacion':} `=string(`y2',"%12.0fc")'"', place(nw)) ///
			text(`=`MAX'[1,3]+2.5' `x3' `"{bf:Max:} `=string(`MAX'[1,3],"%5.1fc")' % (`x3')"', place(nw)) ///
			text(`=`MAX'[1,3]' `x3' `"{bf:`poblacion':} `=string(`y3',"%12.0fc")'"', place(nw)) ///
			text(`=`MAX'[1,4]+2.5' `x4' `"{bf:Max:} `=string(`MAX'[1,4],"%5.1fc")' % (`x4')"', place(nw)) ///
			text(`=`MAX'[1,4]' `x4' `"{bf:`poblacion':} `=string(`y4',"%12.0fc")'"', place(nw)) ///
			text(`=`MAX'[2,1]' `m1' `"{bf:Min:} `=string(`MAX'[2,1],"%5.1fc")' % (`m1')"', place(nw)) ///
			text(`=`MAX'[2,1]-2.5' `m1' `"{bf:`poblacion':} `=string(`z1',"%12.0fc")'"', place(nw)) ///
			text(`=`MAX'[2,2]' `m2' `"{bf:Min:} `=string(`MAX'[2,2],"%5.1fc")' % (`m2')"', place(sw)) ///
			text(`=`MAX'[2,2]-2.5' `m2' `"{bf:`poblacion':} `=string(`z2',"%12.0fc")'"', place(sw)) ///
			text(`=`MAX'[2,3]' `m3' `"{bf:Min:} `=string(`MAX'[2,3],"%5.1fc")' % (`m3')"', place(s)) ///
			text(`=`MAX'[2,3]-2.5' `m3' `"{bf:`poblacion':} `=string(`z3',"%12.0fc")'"', place(s)) ///
			text(`=`MAX'[2,4]' `m4' `"{bf:Min:} `=string(`MAX'[2,4],"%5.1fc")' % (`m4')"', place(s)) ///
			text(`=`MAX'[2,4]-2.5' `m4' `"{bf:`poblacion':} `=string(`z4',"%12.0fc")'"', place(s)) ///
			text(2 `=`anioinicial'-1' "{bf:Hoy:} `anioinicial'", place(w)) ///
			xtitle("") ytitle("Distribuci{c o'}n (%)") ///
			xlabel(1950(10)`aniofinal') ///
			xline(`anioinicial', lpattern(dash) lcolor("52 70 78")) ///
			xline(`aniofinal', lpattern(dash) lcolor("52 70 78")) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			name(Estructura_`anything'_`anioinicial'_`aniofinal', replace) ///
			title("{bf:Transici{c o'}n demogr{c a'}fica}") subtitle(${pais})
			
			if "$export" != "" {
				graph export "$export/Estructura_`anything'_`anioinicial'_`aniofinal'.png", replace name(Estructura_`anything'_`anioinicial'_`aniofinal')
			}
	}

	restore

}
end
