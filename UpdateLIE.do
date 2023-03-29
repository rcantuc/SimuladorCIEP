*****************************
*** UPDATE Base Entidades ***
*****************************
tokenize $entidadesC



**********************
*** 1. PIB Estatal ***
import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/PIB entidades federativas.xlsx", clear
LimpiaBIE
rename A anio
local j = 1
foreach k of varlist B-AG {
	rename `k' pibYEnt``j''
	local ++j
}
reshape long pibYEnt, i(anio) j(entidad) string
tempfile PIBEntidades
save `PIBEntidades'


** PIB Deflactor **
PIBDeflactor, nographs
tempfile PIBDeflactor
save `PIBDeflactor'


** ITAEE **
import excel "`c(sysdir_site)'../BasesCIEP/UPDATE/SCN/ITAEE.xlsx", clear
LimpiaBIE, nomultiply
split A, parse("/")
drop A
rename A1 anio
rename A2 trimestre
destring anio trimestre, replace
order anio trimestre

collapse (mean) B-AG, by(anio)
set obs `=_N+1'
replace anio = anio[_N-1]+1 in -1

local j = 1
foreach k of varlist B-AG {
	replace `k' = 3.4 in -1
	rename `k' ITAEE``j''
	local ++j
}
reshape long ITAEE, i(anio) j(entidad) string

** Merge **
merge 1:1 (anio entidad) using `PIBEntidades', nogen
merge m:1 (anio) using `PIBDeflactor', nogen keepus(deflator)

encode entidad, gen(entidadx)
xtset entidadx anio
replace pibYEnt = L.pibYEnt*(1+ITAEE/100)*deflator if pibYEnt == .

keep if anio >= 2003 & anio <= 2022

tempfile PIBEntidades
save `PIBEntidades'



******************************************/
*** 2. Poblacion por Entidad Federativa ***
local j = 1
foreach k of global entidadesL {
	Poblacion if entidad == "`k'", nographs
	
	g pob1664 = poblacion if edad >= 16 & edad <= 64
	replace pob1664 = 0 if pob1664 == .
	
	collapse (sum) pob*, by(entidad anio)
	format pob* %15.0fc
	rename entidad entidad1
	g entidad = "``j''"

	tempfile Pob``j''
	save `Pob``j'''
	local ++j

	scalar poblacion``j'' = poblaciontotal
}
local j = 1
forvalues k=1(1)33 {
	if `k' == 1 {
		use `Pob``j''', clear
	}
	else {
		append using `Pob``j'''
	}
	local ++j
}
drop entidad1
*noisily scalarlatex, logname(pob)
tempfile PobTot
save `PobTot'



*****************************************/
*** 3. Gasto Federalizado y sus Fondos ***
DatosAbiertos XFA0000, nographs
split nombre, gen(entidad) parse(":")
drop nombre
replace entidad1 = "Nacional"
rename entidad2 concepto
tempfile XFA0000
save `XFA0000'

local series28 `""" A B C D E F G H I J K L M"'
*local series28 `""""'

local series33 `""" A B C D E F G H I J K L M N O"'
*local series33 `""""'

local series23 `""" A B C"'
*local series23 `""""'

local seriesCD `""" A D E"'
*local seriesCD `""""'

local seriesCR `""""'

local seriesPSS `""""'

* Obtener las bases de Datos Abiertos *
foreach gastofed in 28 33 PSS 23 CD CR {
	foreach fondo of local series`gastofed' {

		local serie "XAC`gastofed'`fondo'"
		local j = 1

		forvalues k=1(1)32 {
			noisily DatosAbiertos `serie'`=string(`k',"%02.0f")', nographs
			if r(error) != 2000 {
				* Limpiar base intermedia *
				split nombre, gen(entidad) parse(":")
				drop nombre
				rename entidad2 concepto
				g entidad = "``j''"
			}

			* Guardar bases estados *
			tempfile `serie'`=string(`k',"%02.0f")'
			save ``serie'`=string(`k',"%02.0f")''
			local ++j
		}

		* Unir bases estados *
		use ``serie'01', clear
		forvalues k=2(1)32 {
			append using ``serie'`=string(`k',"%02.0f")''
		}
		tempfile XAC`gastofed'`fondo'
		save `XAC`gastofed'`fondo''
	}
}

* Unir todas las bases obtenidas *
local j = 0
foreach gastofed in 28 33 PSS 23 CD CR {
	foreach fondo of local series`gastofed' {
		if `j' == 0 {
			use `XAC`gastofed'', clear
			local ++j
		}
		else {
			append using `XAC`gastofed'`fondo''
		}
	}
}
append using `XFA0000'
replace entidad = "Nacional" if entidad == ""
tempfile GastoFedBase
save `GastoFedBase'




*********************
*** 4. BASE FINAL ***
use `GastoFedBase', clear
merge m:1 (anio entidad) using `PIBEntidades', nogen
merge m:1 (anio entidad) using `PobTot', nogen
save "`c(sysdir_personal)'/SIM/EstadosBase.dta", replace
