**********************************************
****    FOR PROGRAMMING PURPOSES ONLY    ****
**** SECTION MUST BE COMMENTED OTHERWISE ****
/*********************************************
clear all
macro drop _all
capture log close _all

noisily di _newline(20) in g _col(35) "8) " in w "8) " in y "8) " in g "8)"

if "`c(os)'" == "Unix" {
	sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	global export "/home/ciepmx/Dropbox (CIEP)/Textbook/images/"
}
if "`c(os)'" == "MacOSX" {
	sysdir set PERSONAL "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	global export "/Users/ricardo/Dropbox (CIEP)/Textbook/images/"
}
adopath ++ PERSONAL
timer on 1




***************************************/
*** Cap. 2. El sistema de la ciencia ***
***  Simulador v5: PIB + Deflactor   ***
****************************************
*global id = "PE2021"
global pais = "El Salvador"
local aniovp = 2021

noisily run "`c(sysdir_personal)'/2PIBWeb.do" `aniovp'




******************************************/
*** Cap. 3. La economia antropocentrica ***
***        Simulador v5: Set up         ***
*******************************************
noisily Poblacion, //nographs //update
noisily run `"`c(sysdir_personal)'/Households`=subinstr("${pais}"," ","",.)'.do"' `aniovp'

if "$pais" == "" {
	*noisily run "`c(sysdir_personal)'/Expenditure.do" 2018 // 	<-- a calibrar!!!
	use "`c(sysdir_site)'../basesCIEP/SIM/2018/households.dta", clear

	* ENIGH + SCN *
	Simulador ingbrutotot [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs anio(2018)
	Simulador TOTgasto_anual [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs anio(2018)
	Simulador Yl [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs anio(2018)
	Simulador Yk [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs anio(2018)
	Simulador Ahorro [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs anio(2018)
	Simulador Ciclodevida [fw=factor_cola], base("ENIGH 2018") boot(1) reboot graphs anio(2018)
	
	* Gastos *
	Simulador Pension [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(2018)
	Simulador Educacion [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(2018)
	Simulador Salud [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(2018)
	Simulador OtrosGas [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(2018)
	Simulador PenBienestar if edad >= 68 [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(2018)
	Simulador IngBasico [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(2018)

	* Ingresos *
	Simulador Laboral [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(2018)
	Simulador Consumo [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(2018)
	Simulador OtrosC [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(2018)	

	* Sankey *
	foreach k in grupo_edad decil escol sexo {
		use "`c(sysdir_site)'../basesCIEP/SIM/2018/households.dta", clear
		noisily run "`c(sysdir_personal)'/Sankey.do" `k' 2018
	}
}




************************/
*** PARTE III: GASTOS ***
*************************
if "$pais" == "" {
	noisily run "`c(sysdir_personal)'/3GastosWeb.do" `aniovp'
	use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear

	Simulador Pension [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(`aniovp')
	Simulador Educacion [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(`aniovp')
	Simulador Salud [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(`aniovp')
	Simulador OtrosGas [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(`aniovp')
	Simulador PenBienestar if edad >= 68 [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(`aniovp')
	Simulador IngBasico [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(`aniovp')
}
else if "$pais" == "El Salvador" {
	noisily PEF, anio(`aniovp') by(divGA)
	local Pension = r(Pensiones)
	local Educacion = r(Educaci_c_o__n)
	local Salud = r(Salud)
	local OtrosGas = r(Otros)

	tempname GASBase
	local j = 1
	foreach k in Pension Educacion Salud OtrosGas {
		use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/`k'REC"', clear
		merge 1:1 (anio) using "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", nogen keepus(lambda)
		tabstat estimacion if anio == `aniovp', stat(sum) f(%20.0fc) save
		matrix `GASBase' = r(StatTotal)

		replace estimacion = estimacion*``k''/`GASBase'[1,1] if anio >= `aniovp' & anio <= `aniovp'

		local ++j
		if `c(version)' > 13.1 {
			saveold `"`c(sysdir_personal)'/users/$pais/$id/`k'REC.dta"', replace version(13)
		}
		else {
			save `"`c(sysdir_personal)'/users/$pais/$id/`k'REC.dta"', replace		
		}
	}

	use `"`c(sysdir_site)'../basesCIEP/SIM/2018/householdsElSalvador.dta"', clear
}




*************************/
*** PARTE II: INGRESOS ***
**************************
if "$pais" == "" {
	* Ingresos: Datos Abiertos *
	DatosAbiertos XNA0120_s, g //						ISR salarios
	DatosAbiertos XNA0120_pf, g //						ISR PF
	DatosAbiertos XNA0120_m, g //						ISR PM
	DatosAbiertos XKF0114, g //						Cuotas IMSS
	DatosAbiertos XAB1120, g //						IVA
	DatosAbiertos XNA0141, g //						ISAN
	DatosAbiertos XAB1130, g //						IEPS
	DatosAbiertos XNA0136, g //						Importaciones
	DatosAbiertos FMP_Derechos, g //					FMP_Derechos
	DatosAbiertos XAB2110, g //						Ingresos propios Pemex
	DatosAbiertos XOA0115, g //						Ingresos propios CFE
	DatosAbiertos XKF0179, g //						Ingresos propios IMSS
	DatosAbiertos XOA0120, g //						Ingresos propios ISSSTE

	noisily run "`c(sysdir_personal)'/4IngresosWeb.do" `aniovp' //		Parte II
	use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear

	Simulador Laboral [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(`aniovp')
	Simulador Consumo [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(`aniovp')
	Simulador OtrosC [fw=factor], base("ENIGH 2018") boot(1) reboot graphs anio(`aniovp')
}
else if "$pais" == "El Salvador" {
	noisily LIF, anio(`aniovp') by(divGA) ilif
	local Laboral = r(Impuestos_al_ingreso)
	local Consumo = r(Impuestos_al_consumo)
	local OtrosC = r(Otros_ingresos)
	
	use `"`c(sysdir_site)'../basesCIEP/SIM/2018/householdsElSalvador.dta"', clear

	tempname RECBase
	local j = 1
	foreach k in Laboral Consumo OtrosC {
		use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/`k'REC"', clear
		merge 1:1 (anio) using "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", nogen keepus(lambda)
		tabstat estimacion if anio == `aniovp', stat(sum) f(%20.0fc) save
		matrix `RECBase' = r(StatTotal)

		replace estimacion = estimacion*``k''/`RECBase'[1,1] if anio >= `aniovp' & anio <= `aniovp'

		local ++j
		if `c(version)' > 13.1 {
			saveold `"`c(sysdir_personal)'/users/$pais/$id/`k'REC.dta"', replace version(13)
		}
		else {
			save `"`c(sysdir_personal)'/users/$pais/$id/`k'REC.dta"', replace		
		}
	}
}




**********************/
*** PARTE IV: DEUDA ***
***********************
if "$pais" == "" {
	use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
}
else if "$pais" == "El Salvador" {
	use `"`c(sysdir_site)'../basesCIEP/SIM/2018/householdsElSalvador.dta"', clear
}
noisily run "`c(sysdir_personal)'/5CGWeb.do" `aniovp' //			Cuentas Generacionales
noisily run "`c(sysdir_personal)'/6FiscalGapWeb.do" `aniovp' //			Fiscal Gap




*********************/
**** Touchdown!!! ****
**********************
*noisily scalarlatex
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
