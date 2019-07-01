*! Poblacion: 30 de octubre de 2014. Autor: Ricardo
program define Poblacion
quietly {
	version 13.1
	
	local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)

	syntax [anything] [, ANIOInicial(int `aniovp') ANIOFinal(int 2050) Graphs UPDATE]

	if "`anything'" == "" {
		local anything = "poblacion"
	}

	capture use `"`c(sysdir_site)'../basesCIEP/SIM/`=proper("`anything'")'.dta"', clear
	if _rc != 0 | "`update'" == "update" {
		run "`c(sysdir_site)'/UpdatePoblacion.do"
	}
	use `"`c(sysdir_site)'../basesCIEP/SIM/`=proper("`anything'")'.dta"', clear
	local poblacion : variable label `anything'
	local poblacionl = lower("`poblacion'")

	
	*************
	* Gráfica 1 *
	* Mediana *
	tabstat edad [fw=round(abs(`anything'),1)] if anio == `anioinicial', stat(median) by(sexo) save
	tempname H`anioinicial' M`anioinicial'
	matrix `H`anioinicial'' = r(Stat1)
	matrix `M`anioinicial'' = r(Stat2)
	
	tabstat edad [fw=round(abs(`anything'),1)] if anio == `aniofinal', stat(median) by(sexo) save
	tempname H`aniofinal' M`aniofinal'
	matrix `H`aniofinal'' = r(Stat1)
	matrix `M`aniofinal'' = r(Stat2)

	* Distribucion inicial *
	tabstat `anything' if anio == `anioinicial' & edad < 18, stat(sum) f(%15.0fc) save
	tempname P18_`anioinicial'
	matrix `P18_`anioinicial'' = r(StatTotal)

	tabstat `anything' if anio == `anioinicial' & edad >= 18 & edad < 65, stat(sum) f(%15.0fc) save
	tempname P1865_`anioinicial'
	matrix `P1865_`anioinicial'' = r(StatTotal)

	tabstat `anything' if anio == `anioinicial' & edad >= 65, stat(sum) f(%15.0fc) save
	tempname P65_`anioinicial'
	matrix `P65_`anioinicial'' = r(StatTotal)

	tabstat `anything' if anio == `anioinicial', stat(sum) f(%15.0fc) save
	tempname P`anioinicial'
	matrix `P`anioinicial'' = r(StatTotal)

	* Distribucion final *
	tabstat `anything' if anio == `aniofinal' & edad < 18, stat(sum) f(%15.0fc) save
	tempname P18_`aniofinal'
	matrix `P18_`aniofinal'' = r(StatTotal)

	tabstat `anything' if anio == `aniofinal' & edad >= 18 & edad < 65, stat(sum) f(%15.0fc) save
	tempname P1865_`aniofinal'
	matrix `P1865_`aniofinal'' = r(StatTotal)

	tabstat `anything' if anio == `aniofinal' & edad >= 65, stat(sum) f(%15.0fc) save
	tempname P65_`aniofinal'
	matrix `P65_`aniofinal'' = r(StatTotal)

	tabstat `anything' if anio == `aniofinal', stat(sum) f(%15.0fc) save
	tempname P`aniofinal'
	matrix `P`aniofinal'' = r(StatTotal)
	
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
		tabstat `anything' if (anio == `anioinicial' | anio == `aniofinal'), stat(max) f(%15.0fc) by(sexo) save
		tempname MaxH MaxM
		matrix `MaxH' = r(Stat1)
		matrix `MaxM' = r(Stat2)

		*local poblacion "Population"
		g edad2 = edad
		replace edad2 = . if edad != 5 & edad != 10 & edad != 15 & edad != 20 & edad != 25 & edad != 30 & edad != 35 & edad != 40 & edad != 45 & edad != 50 ///
			 & edad != 55 & edad != 60 & edad != 65 & edad != 70 & edad != 75 & edad != 80 & edad != 85 & edad != 90 & edad != 95 & edad != 100 & edad != 105
		g zero = 0
		twoway (bar `pob2' edad if sexo == 1 & anio == `anioinicial', horizontal) ///
			(bar `pob2' edad if sexo == 2 & anio == `anioinicial', horizontal) ///
			(bar `pob2' edad if sexo == 1 & anio == `aniofinal', horizontal barwidth(.5) lwidth(none)) ///
			(bar `pob2' edad if sexo == 2 & anio == `aniofinal', horizontal barwidth(.5) lwidth(none)) ///
			(sc edad2 zero if anio == `anioinicial', msymbol(i) mlabel(edad2) mlabsize(vsmall)), ///
			legend(label(1 "Hombres `anioinicial'") label(2 "Mujeres `anioinicial'") ///
			label(3 "Hombres `aniofinal'") label(4 "Mujeres `aniofinal'")) ///
			legend(order(1 2 3 4) rows(1)) ///
			yscale(noline) ylabel(none) xscale(noline) ///
			text(105 `=-`MaxH'[1,1]*.6' "{bf:Edad mediana `anioinicial'}",) ///
			text(98 `=-`MaxH'[1,1]*.6' "Hombres: `=`H`anioinicial''[1,1]'",) ///
			text(92 `=-`MaxH'[1,1]*.6' "Mujeres: `=`M`anioinicial''[1,1]'",) ///
			text(105 `=`MaxH'[1,1]*.6' "{bf:Edad mediana `aniofinal'}",) ///
			text(98 `=`MaxH'[1,1]*.6' "Hombres: `=`H`aniofinal''[1,1]'",) ///
			text(92 `=`MaxH'[1,1]*.6' "Mujeres: `=`M`aniofinal''[1,1]'",) ///
			text(85 `=-`MaxH'[1,1]*.6' "{bf:Composici{c o'}n por edades `anioinicial'}",) ///
			text(78 `=-`MaxH'[1,1]*.6' `"0-17: `=string(`P18_`anioinicial''[1,1]/`P`anioinicial''[1,1]*100,"%5.1fc")' %"',) ///
			text(72 `=-`MaxH'[1,1]*.6' `"18-64: `=string(`P1865_`anioinicial''[1,1]/`P`anioinicial''[1,1]*100,"%5.1fc")' %"',) ///
			text(66 `=-`MaxH'[1,1]*.6' `"65+: `=string(`P65_`anioinicial''[1,1]/`P`anioinicial''[1,1]*100,"%5.1fc")' %"',) ///
			text(85 `=`MaxH'[1,1]*.6' "{bf:Composici{c o'}n por edades `aniofinal'}",) ///
			text(78 `=`MaxH'[1,1]*.6' `"0-17: `=string(`P18_`aniofinal''[1,1]/`P`aniofinal''[1,1]*100,"%5.1fc")' %"',) ///
			text(72 `=`MaxH'[1,1]*.6' `"18-64: `=string(`P1865_`aniofinal''[1,1]/`P`aniofinal''[1,1]*100,"%5.1fc")' %"',) ///
			text(66 `=`MaxH'[1,1]*.6' `"65+: `=string(`P65_`aniofinal''[1,1]/`P`aniofinal''[1,1]*100,"%5.1fc")' %"',) ///
			name(Piramide_`anything', replace) ///
			xlabel(`=-`MaxH'[1,1]' `"`=string(`MaxH'[1,1],"%15.0fc")'"' `=-`MaxH'[1,1]/2' ///
			`"`=string(`MaxH'[1,1]/2,"%15.0fc")'"' 0 `=`MaxM'[1,1]/2' `=`MaxM'[1,1]', angle(horizontal)) ///
			caption("{it:Fuente: CONAPO (2018).}") ///
			xtitle("`poblacion'") ///
			title({bf: Transici{c o'}n de `poblacionl'})
	}



	***************************************
	** Grafica 2: Transicion demografica **
	***************************************
	g pob18 = `anything' if edad < 18
	g pob1865 = `anything' if edad >= 18 & edad < 65
	g pob65 = `anything' if edad >= 65

	collapse (sum) pob18 pob1865 pob65 `anything' if anio <= `aniofinal', by(anio ent)
	format `anything' pob* %15.0fc

	* Distribucion *
	g pob18_2 = pob18/`anything'*100
	g pob1865_2 = pob1865/`anything'*100
	g pob65_2 = pob65/`anything'*100

	* Valores maximos *
	tabstat pob18_2 pob1865_2 pob65_2, stat(max min) save
	tempname MAX
	matrix `MAX' = r(StatTotal)

	* Valores finales *
	tabstat pob18 pob1865 pob65 if anio == `aniofinal', stat(mean) save
	tempname FIN
	matrix `FIN' = r(StatTotal)

	forvalues k = 1(1)`=_N' {
		* Maximos *
		if pob18_2[`k'] == `MAX'[1,1] {
			local x18 = anio[`k']
			local y18 = pob18[`k']
		}
		if pob1865_2[`k'] == `MAX'[1,2] {
			if anio[`k'] <= `=`anioinicial'+5' {
				local pos1865max = "se"
			}
			else {
				local pos1865max = "sw"
			}
			local x1865 = anio[`k']
			local y1865 = pob1865[`k']
		}
		if pob65_2[`k'] == `MAX'[1,3] {
			local x65 = anio[`k']
			local y65 = pob65[`k']
		}
		
		* Minimos *
		if pob18_2[`k'] == `MAX'[2,1] {
			local m18 = anio[`k']
			local ym18 = pob18[`k']
		}
		if pob1865_2[`k'] == `MAX'[2,2] {
			if anio[`k'] >= `=`aniofinal'-5' {
				local pos1865min = "nw"
			}
			else {
				local pos1865min = "ne"
			}
			local m1865 = anio[`k']
			local ym1865 = pob1865[`k']
		}
		if pob65_2[`k'] == `MAX'[2,3] {
			local m65 = anio[`k']
			local ym65 = pob65[`k']
		}
	}

	if "$graphs" == "on" | "`graphs'" == "graphs" {
		twoway (line pob18_2 anio) (line pob1865_2 anio) (line pob65_2 anio), ///
			legend(label(1 "0-17") label(2 "18-64") label(3 "65+") cols(3)) ///
			name(Estructura_`anything', replace) ///
			text(`=`MAX'[1,1]' `x18' `"{bf:Max:} `=string(`MAX'[1,1],"%5.1fc")' % (`x18')"', place(se)) ///
			text(`=`MAX'[1,1]-2.5' `x18' `"{bf:`poblacion':} `=string(`y18',"%12.0fc")'"', place(se)) ///
			text(`=`MAX'[1,2]' `x1865' `"{bf:Max:} `=string(`MAX'[1,2],"%5.1fc")' % (`x1865')"', place(`pos1865max')) ///
			text(`=`MAX'[1,2]-2.5' `x1865' `"{bf:`poblacion':} `=string(`y1865',"%12.0fc")'"', place(`pos1865max')) ///
			text(`=`MAX'[1,3]' `x65' `"{bf:Max:} `=string(`MAX'[1,3],"%5.1fc")' % (`x65')"', place(sw)) ///
			text(`=`MAX'[1,3]-2.5' `x65' `"{bf:`poblacion':} `=string(`y65',"%12.0fc")'"', place(sw)) ///
			text(`=`MAX'[2,1]' `m18' `"{bf:Min:} `=string(`MAX'[2,1],"%5.1fc")' % (`m18')"', place(nw)) ///
			text(`=`MAX'[2,1]-2.5' `m18' `"{bf:`poblacion':} `=string(`ym18',"%12.0fc")'"', place(nw)) ///
			text(`=`MAX'[2,2]' `m1865' `"{bf:Min:} `=string(`MAX'[2,2],"%5.1fc")' % (`m1865')"', place(`pos1865min')) ///
			text(`=`MAX'[2,2]-2.5' `m1865' `"{bf:`poblacion':} `=string(`ym1865',"%12.0fc")'"', place(`pos1865min')) ///
			text(`=`MAX'[2,3]' `m65' `"{bf:Min:} `=string(`MAX'[2,3],"%5.1fc")' % (`m65')"', place(ne)) ///
			text(`=`MAX'[2,3]-2.5' `m65' `"{bf:`poblacion':} `=string(`ym65',"%12.0fc")'"', place(ne)) ///
			xtitle("") ytitle("porcentaje") ///
			xlabel(1950(10)2050) ///
			caption("{it:Fuente: CONAPO (2018).}") ///
			title({bf: Transici{c o'}n de `poblacionl'})
	}

	restore
}
end
