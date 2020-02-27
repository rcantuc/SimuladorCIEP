************************************************
**** Base de datos: PIB e índice de precios ****
************************************************


***************
*** 0 BASES ***
***************
if "`c(os)'" == "Unix" {
	cd "/home/ciepmx/Dropbox (CIEP)/UNICEF GA/Datos/"
}
if "`c(os)'" == "MacOSX" {
	cd "/Users/ricardo/Dropbox (CIEP)/UNICEF GA/Datos/"
}


* 0.1.1. PIB *
import delimited "API_NY.GDP.MKTP.CD_DS2_en_csv_v2_713242/API_NY.GDP.MKTP.CD_DS2_en_csv_v2_713242.csv", clear
keep if v2 == "SLV"

local anio = 1960
foreach k of varlist v5 - v64 {
	rename `k' v`anio'
	local ++anio
}
drop v1-v4 v65

g i = 1
reshape long v, i(i) j(anio)
drop i
rename v pibY


* 0.1.5. Guardar *
compress
tempfile PIB
save `PIB'



* 0.2.1. Deflactor *
import delimited "API_NY.GDP.MKTP.KD_DS2_en_csv_v2_713008/API_NY.GDP.MKTP.KD_DS2_en_csv_v2_713008.csv", clear
keep if v2 == "SLV"

local anio = 1960
foreach k of varlist v5 - v64 {
	rename `k' v`anio'
	local ++anio
}
drop v1-v4 v65

g i = 1
reshape long v, i(i) j(anio)
drop i
rename v pibR

* 0.2.5. Guardar *
compress
tempfile PIBR
save `PIBR', replace




*************************
*** 1 PIB + Deflactor ***
*************************
use `PIB', clear
merge 1:1 (anio) using `PIBR', nogen

g indiceY = pibY/pibR*100

drop pibR
drop if pibY == .

format indiceY %10.4fc
format pibY %25.0fc

g currency = "USD"
g trimestre = 4


saveold "`c(sysdir_site)'../basesCIEP/SIM/PIBDeflactor`=subinstr("${pais}"," ","",.)'.dta", replace version(13)
