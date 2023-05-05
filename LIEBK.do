



exit










restore
* Scalars *
drop `montograph'
g `montograph' = monto/poblacion/deflator

replace `montograph' = . if round(`montograph') == 0
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Federalizado" {
		scalar LIEFed`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Propios" {
		scalar LIERec`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Organismos y empresas" {
		scalar LIEOyE`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Financiamiento" {
		scalar LIEFin`=entidad[`k']' = `montograph'[`k']
	}
}

preserve
collapse (sum) monto (mean) poblacion deflator pibYEnt if anio == 2022, by(anio entidad)
tempvar montograph
g `montograph' = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
		scalar LIETot`=entidad[`k']' = `montograph'[`k']
		scalar LIETotPIB`=entidad[`k']' = monto[`k']/pibYEnt[`k']*100

}

restore
collapse (sum) monto poblacion (mean) deflator, by(anio tipo_ingreso)
tempvar montograph
g `montograph' = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Federalizado" {
		scalar LIEFedNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Propios" {
		scalar LIERecNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Organismos y empresas" {
		scalar LIEOyENac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Financiamiento" {
		scalar LIEFinNac = `montograph'[`k']
	}
}
scalar LIETotNac = LIEFedNac+LIERecNac+LIEOyENac+LIEFinNac
noisily scalarlatex, logname(gastotot)















collapse (sum) monto `montograph' (mean) poblacion deflator pibYEnt, by(entidad anio concepto_propio)
reshape wide monto `montograph' deflator pibYEnt, i(anio entidad) j(concepto) string
reshape long
replace `montograph' = . if `montograph' == 0
preserve
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & concepto[`k'] == "Aprovechamientos" {
		scalar RPaprov`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Derechos" {
		scalar RPder`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos" {
		scalar RPimp`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Otros" {
		scalar RPotros`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Productos" {
		scalar RPprod`=entidad[`k']' = `montograph'[`k']
	}
}

collapse (sum) monto (mean) poblacion deflator pibYEnt, by(entidad anio)
g montograph = monto/poblacion/deflator
g montopibYE = monto/pibYEnt*100

forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 {
		scalar RPTot`=entidad[`k']' = montograph[`k']
		scalar RePrPIB`=entidad[`k']' = montopibYE[`k']
	}
}

restore

collapse (sum) monto poblacion (mean) deflator, by(anio concepto)

*tempfile aux_final
*save "`aux_final'"
*use "C:\Users\Admin\Dropbox (CIEP)\Hewlett Subnacional\Base de datos\PobTot.dta" , replace
*keep if anio==2022
*merge 1:m entidad using "`aux_final'"
*exit
g montograph = monto/poblacion/deflator

forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & concepto[`k'] == "Aprovechamientos" {
		scalar RPaprovNac= montograph[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Contribuciones" {
		scalar RPcontriNac= montograph[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Derechos" {
		scalar RPderNac= montograph[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos" {
		scalar RPimpNac = montograph[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Otros" {
		scalar RPotrosNac = montograph[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Productos" {
		scalar RPprodNac= montograph[`k']
	}
}
scalar RPTotNac = RPaprovNac + RPderNac + RPimpNac+ RPotrosNac + RPprodNac
/*collapse (sum) monto poblacion (mean) deflator, by(anio)
g montograph = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 {
		scalar RPTotNac = montograph[`k']
	}
}
*/
noisily scalarlatex, logname(Recursos_propios)













































exit
*************************************************************************************
*IMPUESTOS
***********************************************************************************


drop `montograph'

****************************

*Checkponit*

***************************
collapse (sum) monto (mean) poblacion deflator pibYEnt, by(entidad anio concepto)

*reshape wide monto poblacion, i(anio concepto deflator pibYEnt) j(entidad) string
*reshape long
g `montograph' = monto/poblacion/deflator
preserve

forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & concepto[`k'] == "Accesorios" {
		scalar ImpAcc`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Adicionales" {
		scalar ImpAdi`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "ISN" {
		scalar ImpISN`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuesto Sobre La Producci{c o'}n, Consumo Y Las Transacciones" {
		scalar ImpConsu`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos Sobre Ingresos" {
		scalar ImpIng`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos Sobre Patrimonio" {
		scalar ImpPatri`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Otros Impuestos" {
		scalar ImpOtros`=entidad[`k']' = `montograph'[`k']
	}
	
}
restore
preserve
collapse (sum) monto (mean) poblacion deflator pibYEnt, by(entidad anio)
tempvar montograph montopibYE
g `montograph' = monto/poblacion/deflator
g `montopibYE' = monto/pibYEnt*100

forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 {
		scalar ImpTot`=entidad[`k']' = `montograph'[`k']
		scalar ImpPIB`=entidad[`k']' = `montopibYE'[`k']
	}
}
restore
preserve
collapse (sum) monto poblacion (mean) deflator, by(anio concepto)
tempvar montograph
g `montograph' = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & concepto[`k'] == "Accesorios" {
		scalar ImpAccNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Adicionales" {
		scalar ImpAdiNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "ISN" {
		scalar ImpISNNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuesto Sobre La Producci{c o'}n, Consumo Y Las Transacciones" {
		scalar ImpConsuNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos Sobre Ingresos" {
		scalar ImpIngNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos Sobre Patrimonio" {
		scalar ImpPatriNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Otros Impuestos" {
		scalar ImpOtrosNac = `montograph'[`k']
	}
}


restore
collapse (sum) monto poblacion (mean) deflator, by(anio)
tempvar montograph
g `montograph' = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 {
		scalar ImpTotNac = `montograph'[`k']
	}
}

noisily scalarlatex, logname(Impuestos)

