****
**** CIEP - Simulador de Informes Trimestrales 
****
capture mkdir "`c(sysdir_site)'/01_raw/InformesTrimestrales/"


***
*** 1. PIB Deflactor
***
PIBDeflactor, nog
tempfile PIBDeflactor
save `PIBDeflactor'


***
*** 2. Descargar informes trimestrales
***
forvalues k = 2019(1)`=aniovp' {
	foreach j in i ii iii iv {
		if "`j'" == "i" {
			local arab = "01"
		}
		else if "`j'" == "ii" {
			local arab = "02"
		}
		else if "`j'" == "iii" {
			local arab = "03"
		}
		else if "`j'" == "iv" {
			local arab = "04"
		}

		noisily di "Año: `k' Trimestre: `j'"
		
		capture confirm file "`c(sysdir_site)'/01_raw/InformesTrimestrales/Actividad_`k'_`j'.dta"
		if _rc == 0 continue

		set sslrelax on
		capture import excel "https://www.finanzaspublicas.hacienda.gob.mx/work/models/Finanzas_Publicas/docs/congreso/infotrim/`k'/`j't/04afp/itanfp02_`k'`arab'.xlsx", clear sheet("I.II RecGobFed")
		if _rc == 603 continue
		set sslrelax off

		* Serie de tiempo *
		g anio = `k'
		g trim = `arab'
		gen qdate = yq(anio, trim)
		format qdate %tq
		
		* Limpia *
		keep if B != ""
		drop A

		local uno "B"
		local dos "C"
		local tres "D"
		local cuatro "E"
		local cinco "F"

		rename `uno' Actividad
		rename `dos' Total
		rename `tres' Morales
		rename `cuatro' FisicasCAE
		rename `cinco' FisicasSAE
		keep anio trim qdate Actividad Total Morales FisicasCAE FisicasSAE

		drop if Total == ""
		drop if Total == "Total"
		destring _all, replace

		foreach l of varlist Total Morales FisicasCAE FisicasSAE {
			replace `l' = `l'*1000000
			format `l' %20.0fc
		}

		noisily list anio trim qdate Actividad Total Morales FisicasCAE FisicasSAE
		order anio trim qdate Actividad Total Morales FisicasCAE FisicasSAE

		save "`c(sysdir_site)'/01_raw/InformesTrimestrales/Actividad_`k'_`j'.dta", replace
	}
}
forvalues k = 2019(1)`=aniovp' {
	foreach j in i ii iii iv {
		noisily di `k' "`j'"
		if "`first'" == "" {
			use "`c(sysdir_site)'/01_raw/InformesTrimestrales/Actividad_`k'_`j'.dta", clear
			local first "first"
		}
		else {
			capture append using "`c(sysdir_site)'/01_raw/InformesTrimestrales/Actividad_`k'_`j'.dta"
		}
	}
}





ex

foreach l in "Contribuyente" "Actividad" {
forvalues k = 2019(1)2025 {
	foreach j in i ii iii iv {
		if "`j'" == "i" {
			local arab = "01"
		}
		else if "`j'" == "ii" {
			local arab = "02"
		}
		else if "`j'" == "iii" {
			local arab = "03"
		}
		else if "`j'" == "iv" {
			local arab = "04"
		}

		if "`l'" == "Contribuyente" {
			if `k' == 2019 | (`k' == 2020 & "`arab'" < "03") {
				local cells = "U10:Y28"
				local uno "U"
				local dos "V"
				local tres "W"
				local cuatro "X"
				local cinco "Y"
			}
			else if `k' == 2020 & "`arab'" == "03" {
				local cells = "AG10:AK28"
				local uno "AG"
				local dos "AH"
				local tres "AI"
				local cuatro "AJ"
				local cinco "AK"
			}
			else {
				local cells = "Z10:AD28"
				local uno "Z"
				local dos "AA"
				local tres "AB"
				local cuatro "AC"
				local cinco "AD"
			}
		}

		if "`l'" == "Actividad" {
			if `k' == 2019 | (`k' == 2020 & "`arab'" < "03") {
				local cells = "U10:Y28"
				local uno "U"
				local dos "V"
				local tres "W"
				local cuatro "X"
				local cinco "Y"
			}
			else if `k' == 2020 & "`arab'" == "03" {
				local cells = "AG10:AK28"
				local uno "AG"
				local dos "AH"
				local tres "AI"
				local cuatro "AJ"
				local cinco "AK"
			}
			else {
				local cells = "B7:F38"
				local uno "B"
				local dos "C"
				local tres "D"
				local cuatro "E"
				local cinco "F"
			}
		}

		set sslrelax on
		capture import excel "https://www.finanzaspublicas.hacienda.gob.mx/work/models/Finanzas_Publicas/docs/congreso/infotrim/`k'/`j't/04afp/itanfp02_`k'`arab'.xlsx", clear sheet("I.II RecGobFed") cellrange("`cells'")
		if _rc == 603 continue
		set sslrelax off
		
		g anio = `k'
		g trim = `arab'
		gen qdate = yq(anio, trim)
		format qdate %tq
		
		keep if `tres' != ""
		rename `uno' `l'
		rename `dos' Total
		rename `tres' Morales
		rename `cuatro' Fisicas
		rename `cinco' Otros
		drop in 1
		
		destring _all, replace
		
		capture mkdir "`c(sysdir_site)'/01_raw/InformesTrimestrales/"
		save "`c(sysdir_site)'/01_raw/InformesTrimestrales/`k'_`j'_`l'", replace
	}
}
forvalues k = 2019(1)2025 {
	foreach j in i ii iii iv {
		noisily di `k' "`j'"
		if "`first'" == "" {
			use `ex_`k'_`j'', clear
			local first "first"
		}
		else {
			capture append using `ex_`k'_`j''
		}
	}
}
replace `l' = subinstr(`l',",","",.)
replace `l' = subinstr(`l',"/","",.)
replace `l' = subinstr(`l'," ","_",.)
}
ex


reshape wide Total Morales Fisicas Otros, i(qdate) j(Contribuyente) string

merge m:1 anio using `PIBDeflactor', nogen

tsset qdate
*replace Total100000_≤_500000 = D.Total100000_≤_500000 if trim > 1


*replace TotalMás_de_500_mil = TotalMás_de_500_mil/deflator
twoway connected TotalMás_de_500_mil qdate if trim == 4, mlabel(TotalMás_de_500_mil)
