PIBDeflactor, nog
tempfile PIBDeflactor
save `PIBDeflactor'

forvalues k = 2019(1)2024 {
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
			local cells = "Z10:AD27"
			local uno "Z"
			local dos "AA"
			local tres "AB"
			local cuatro "AC"
			local cinco "AD"
		}

		capture import excel "https://www.finanzaspublicas.hacienda.gob.mx/work/models/Finanzas_Publicas/docs/congreso/infotrim/`k'/`j't/04afp/itanfp02_`k'`arab'.xlsx", clear sheet("I.II RecGobFed") cellrange("`cells'")
		if _rc == 603 continue
		
		g anio = `k'
		g trim = `arab'
		gen qdate = yq(anio, trim)
		format qdate %tq
		
		keep if `tres' != ""
		rename `uno' Contribuyente
		rename `dos' Total
		rename `tres' Morales
		rename `cuatro' Fisicas
		rename `cinco' Otros
		drop in 1
		
		destring _all, replace
		
		tempfile ex_`k'_`j'
		save `ex_`k'_`j''
	}
}


forvalues k = 2019(1)2024 {
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

replace Contribuyente = subinstr(Contribuyente,",","",.)
replace Contribuyente = subinstr(Contribuyente,"/","",.)
replace Contribuyente = subinstr(Contribuyente," ","_",.)
reshape wide Total Morales Fisicas Otros, i(qdate) j(Contribuyente) string

merge m:1 anio using `PIBDeflactor', nogen

tsset qdate
*replace Total100000_≤_500000 = D.Total100000_≤_500000 if trim > 1


*replace TotalMás_de_500_mil = TotalMás_de_500_mil/deflator
twoway connected TotalMás_de_500_mil qdate if trim == 4, mlabel(TotalMás_de_500_mil)
