use "`c(sysdir_site)'../basesCIEP/Otros/EHPM2018.dta", clear
rename r106 edad
rename r104 sexo

g escol = 0 if r215a == 8 | r215a == 7 | r215a == .
replace escol = 1 if r215a == 0 | r215a == 1 | r215a == 2 | r215a == 6
replace escol = 2 if r215a == 3
replace escol = 3 if r215a == 4 | r215a == 5

label define escol 0 "Sin escolaridad" 1 "Basica" 2 "Media Superior" 3 "Superior"
label values escol escol
label var escol "Nivel de escolaridad"

xtile decil = ingpe [fw=fac00], n(10)

rename ingfa ing_bruto_tot
* 1,859.8

g formal = r422a == 1 | r422a == 2 | ///
	r422b == 1 | r422b == 2 | ///
	r422c == 1 | r422c == 2 | ///
	r422d == 1 | r422d == 2 | ///
	r422e == 1 | r422e == 2 | ///
	r422f == 1 | r422f == 2 | ///
	r422g == 1 | r422g == 2

rename fac00 factor
	

g ISR = ingre if formal == 1
replace ISR = 0 if ISR == .
label var ISR "Impuesto Sobre la Renta"



save `"`c(sysdir_site)'../basesCIEP/SIM/2018/income`=subinstr("${pais}"," ","",.)'.dta"', replace
