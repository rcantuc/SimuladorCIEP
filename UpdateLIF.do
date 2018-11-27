*****************************
**** BASE DE DATOS: LIFs ****
*****************************




************************
*** 1. BASE DE DATOS ***
************************
import excel "`c(sysdir_site)'/bases/LIFs/LIFs.xlsx", clear firstrow

** Encode **
foreach k of varlist div* {
	capture confirm variable num`k'
	if _rc == 0 {
		labmask num`k', values(`k')
		drop `k'
		rename num`k' `k'
		continue
	}
	rename `k' `k's
	encode `k's, gen(`k')
	drop `k's
}
order div* concepto
reshape long LIF ILIF, i(div* modulo* concepto serie nombrecorto) j(anio)
format div* LIF* ILIF* %20.0fc
format concepto %30s




*******************************
*** 2. SHCP: Datos Abiertos ***
*******************************
preserve
levelsof serie, local(serie)
foreach k of local serie {
	noisily DatosAbiertos `k'

	rename clave_de_concepto serie
	keep anio serie nombre monto mes

	tempfile `k'
	quietly save ``k''
}
restore


** 2.1.1 Append **
*replace serie = "Diferimientos" if concepto == "Diferimiento de pagos"
collapse (sum) LIF ILIF, by(div* modulo* serie anio)
foreach k of local serie {
	joinby (anio serie) using ``k'', unmatched(both) update
	drop _merge
}

rename serie series
encode series, generate(serie)
drop series


** 2.1.2 Fill the blanks **
forvalues j=1(1)`=_N' {
	foreach k of varlist div* modulo* serie nombre {
		capture confirm numeric variable `k'
		if _rc == 0 {
			if `k'[`j'] != . {
				quietly replace `k' = `k'[`j'] if `k' == . & serie == serie[`j']
			}
		}
		else {
			if `k'[`j'] != "" {
				quietly replace `k' = `k'[`j'] if `k' == "" & serie == serie[`j']		
			}
		}
	}
}


g double recaudacion = monto if mes == 12					// Se reemplazan cuando la serie esta completa
replace recaudacion = monto if mes < 12 //| mes == . 				// De lo contrario, es LIF
*replace recaudacion = LIF if mes < 12 | mes == . 				// De lo contrario, es LIF
replace recaudacion = ILIF if mes == . & LIF == 0 & ILIF != 0			// De lo contrario, es ILIF
format recaudacion %20.0fc

order div* nombre modulo* serie anio LIF ILIF monto
compress
save "`c(sysdir_site)'/bases/SIM/LIF.dta", replace
