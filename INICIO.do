**************************
**** HOLA, HUMANO! :) ****
**************************
clear all
macro drop _all
capture log close _all

if "`c(os)'" == "Unix" {
	cd "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	*global export "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Textbook/images/"
	global id = "Sirius"
}
if "`c(os)'" == "MacOSX" {
	cd "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	sysdir set PERSONAL "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	*global export "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Textbook/images/"
	global id = "Venus"
}

adopath ++ PERSONAL
timer on 1



global pais = "El Salvador"
global pib2019 = 3.47		// Banco Central de Reserva
*********************
***               ***
*** 1. Parámetros ***
***               ***
/*********************
noisily run Households`=subinstr("${pais}"," ","",.)'.do 2018
foreach k in grupo_edad sexo decil escol {
	noisily run Sankey.do `k' 2018 //											<-- Cap. 2. Explicaci{c o'}n de la poblaci{c o'}n
}

** PIB **/
global pib2020 = -1.9		// Pre-criterios 2021 [-3.9,0.1]
global pib2021 = 2.5		// Pre-criterios 2021 [1.5,3.5]
*global pib2022 = 4.5
*global pib2023 = 6.5
*global pib2024 = 1.5
*global pib2025 = 3.5

// No disponibles para web //
global def2020 = 3.5		// Pre-criterios 2021
global def2021 = 3.2		// Pre-criterios 2021
global desemp2020 = 0		// Desempleo (para la lambda)
global desemp2021 = 0		// Desempleo (para la lambda)

noisily PIBDeflactor, //graphs //discount(3.0)									<-- Cap. 3. Par{c a'}metros MACRO.

** First Step **
use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households`=subinstr("${pais}"," ","",.)'.dta"', clear
tabstat factor, stat(sum) f(%20.0fc) save
matrix POBLACION = r(StatTotal)

if "$pais" == "" {
	** Ingreso b{c a'}sico **
	scalar singbas = 3.000*0
	scalar ingbasico18 = 1
	scalar ingbasico65 = 1

	** Pensi{c o'}n BIENESTAR **
	scalar spam = 0.583 // +3.922*.5

	tabstat factor if edad >= 68, stat(sum) f(%20.0fc) save
	matrix POBLACION68 = r(StatTotal)

	if ingbasico18 == 0 & ingbasico65 == 1 {
		tabstat factor if edad >= 18, stat(sum) f(%20.0fc) save
		matrix POBLACION1 = r(StatTotal)
		g IngBasico = singbas/100*scalar(pibY)/POBLACION1[1,1] if edad >= 18
	}
	else if ingbasico18 == 1 & ingbasico65 == 0 {
		tabstat factor if edad < 68, stat(sum) f(%20.0fc) save
		matrix POBLACION2 = r(StatTotal)
		g IngBasico = singbas/100*scalar(pibY)/POBLACION2[1,1] if edad < 68
	}
	else if ingbasico18 == 0 & ingbasico65 == 0 {
		tabstat factor if edad < 68 & edad >= 18, stat(sum) f(%20.0fc) save
		matrix POBLACION3 = r(StatTotal)
		g IngBasico = singbas/100*scalar(pibY)/POBLACION3[1,1] if edad >= 18 & edad < 68
	}
	else { 
		g IngBasico = singbas/100*scalar(pibY)/POBLACION[1,1]
	}
	label var IngBasico "Ingreso b{c a'}sico"
	Simulador IngBasico [fw=factor], base("ENIGH 2018") ///
		reboot //graphs //boot(20) //noisily

	replace PenBienestar = spam/100*scalar(pibY)/POBLACION68[1,1] if edad >= 68
	Simulador PenBienestar [fw=factor], base("ENIGH 2018") ///
		reboot //graphs //boot(20) //noisily
}

capture mkdir `"`c(sysdir_personal)'/users/$pais/"'
capture mkdir `"`c(sysdir_personal)'/users/$pais/$id/"'
if `c(version)' == 15.1 {
	saveold `"`c(sysdir_personal)'/users/$pais/$id/baseid.dta"', replace version(13)
}
else {
	save `"`c(sysdir_personal)'/users/$pais/$id/baseid.dta"', replace
}



**********************************/
***                             ***
*** 2. Sistema Fiscal: INGRESOS ***
***                             ***
***********************************
noisily LIF, by(divGA) lif //anio(2018) //graphs //update						<-- Parte 2.
local alingreso = r(Impuestos_al_ingreso)
local alconsumo = r(Impuestos_al_consumo)
local otrosing = r(Otros_ingresos)

if "$pais" == "" {
	* INGRESOS *
	noisily TasasEfectivas, lif //anio(2018)									<-- Cap. 4.
	
	* Al ingreso *
	scalar sISR_AS  = ISR_ASBase // *0		// ISR (asalariados)
	scalar sISR_PF  = ISR_PFBase // *0		// ISR (personas f{c i'}sicas)
	scalar sCuotasT = CuotasBase // *0		// Cuotas (IMSS)

	* Al consumo *
	scalar sIVA     = IVABase // +ISR_ASBase+ISR_PFBase+CuotasBase+ImportaBase+singbas		// IVA 
	scalar sIEPS    = IEPSBase 			// IEPS (no petrolero + petrolero)
	scalar sImporta = ImportaBase // *0 	// Importaciones
	scalar sISAN    = ISANBase 			// ISAN

	* Al capital *
	scalar sISR_PM  = ISR_PMBase		// ISR (personas morales)
	scalar sFMP     = FMPBase			// Fondo Mexicano del Petr{c o'}leo
	scalar sOYE     = OYEBase			// Organismos y empresas (IMSS + ISSSTE + Pemex + CFE)
	scalar sOtrosI  = OtrosIngBase		// Productos, derechos, aprovechamientos, contribuciones

	noisily di _newline in g "  Impuesto {c U'}nico" ///
		in y %10.3fc (IVABase+ISR_ASBase+ISR_PFBase+CuotasBase+ImportaBase+singbas)/(ConHogPIB-AlimPIB-BebNPIB)*100 ///
		in g " % Consumo no basico (inclusivo)"
	noisily di in g "  Impuesto {c U'}nico" ///
		in y %10.3fc (IVABase+ISR_ASBase+ISR_PFBase+CuotasBase+ImportaBase+singbas)/(ConHogPIB)*100 ///
		in g " % Consumo de los hogares (inclusivo)"
	noisily di _newline in g "  Impuesto {c U'}nico" ///
		in y %10.3fc (IVABase+ISR_ASBase+ISR_PFBase+CuotasBase+ImportaBase+singbas)/(ConHogPIB-AlimPIB-BebNPIB-(IVABase+ISR_ASBase+ISR_PFBase+CuotasBase+IEPSBase+ImportaBase+ISANBase+singbas))*100 ///
		in g " % Consumo no basico (exclusivo)"
	noisily di in g "  Impuesto {c U'}nico" ///
		in y %10.3fc (IVABase+ISR_ASBase+ISR_PFBase+CuotasBase+ImportaBase+singbas)/(ConHogPIB-(IVABase+ISR_ASBase+ISR_PFBase+CuotasBase+IEPSBase+ImportaBase+ISANBase+singbas))*100 ///
		in g " % Consumo de los hogares (exclusivo)"
}

use `"`c(sysdir_personal)'/users/$pais/$id/baseid.dta"', clear
tabstat factor, stat(sum) f(%20.0fc) save
matrix POBLACION = r(StatTotal)

tabstat Ingreso Consumo Otros [fw=factor], stat(sum) f(%20.0fc) save
matrix INGRESOS = r(StatTotal)

capture g Ingreso0 = Ingreso
replace Ingreso = Ingreso*`alingreso'/INGRESOS[1,1] ///
	// *(sISR_AS+sISR_PF+sCuotasT+sISR_PM)/(ISR_ASBase+ISR_PFBase+CuotasBase+ISR_PMBase)
Simulador Ingreso [fw=factor], base("ENIGH 2018") ///
	reboot //graphs //boot(20) //noisily

replace Consumo = Consumo*`alconsumo'/INGRESOS[1,2] ///
	// *(sIVA+sIEPS+sImporta+sISAN)/(IVABase+IEPSBase+ImportaBase+ISANBase) ///
	// + IngBasico*(1-AhorroNPIB/100)*ImpConsumo/100 ///
	// + (Ingreso0 - Ingreso)*(1-AhorroNPIB/100)*ImpConsumo/100 ///
	// + PenBienestar*(1-AhorroNPIB/100)*ImpConsumo/100
Simulador Consumo [fw=factor], base("ENIGH 2018") ///
	reboot //graphs //boot(20) //noisily

replace Otros = Otros*`otrosing'/INGRESOS[1,3] ///
	// *(sFMP+sOYE+sOtrosI)/(FMPBase+OYEBase+OtrosIngBase)
Simulador Otros [fw=factor], base("ENIGH 2018") ///
	reboot //graphs //boot(20) //noisily

if `c(version)' == 15.1 {
	saveold `"`c(sysdir_personal)'/users/$pais/$id/baseid.dta"', replace version(13)
}
else {
	save `"`c(sysdir_personal)'/users/$pais/$id/baseid.dta"', replace
}



*****************************/
***                        ***
*** Sistema Fiscal: GASTOS ***
***                        ***
******************************
noisily PEF, by(divGA) //anio(2018) //graphs //update							<-- Parte 3.
local OtrosGas = r(Otros)
local Pensiones = r(Pensiones)
local Educacion = r(Educaci_c_o__n)
local Salud = r(Salud)

if "$pais" == "" {
	* GASTOS *
	noisily GastoPC, //pef //anio(2018)											<-- Cap. 5.

	* Pensiones *
	scalar spenims = penimsBase			// Pensi{c o'}n IMSS
	scalar speniss = penissBase			// Pensi{c o'}n ISSSTE
	scalar spenpem = penpemBase			// Pensi{c o'}n Pemex, CFE, Pensi{c o'}n LFC, ISSFAM, Otros

	* Educacion *
	scalar sbasica = basicaBase			// Educaci{c o'}n b{c a'}sica
	scalar smedias = mediasBase			// Educaci{c o'}n media superior
	scalar ssuperi = superiBase			// Educaci{c o'}n superior
	scalar sposgra = posgraBase			// Posgrado

	* Salud *
	scalar sssa    = ssaBase			// SSalud
	scalar ssegpop = segpopBase			// Seguro Popular
	scalar simss   = imssBase			// IMSS (salud)
	scalar sissste = isssteBase			// ISSSTE (salud)
	scalar sprospe = prospeBase			// IMSS-Prospera
	scalar spemex  = pemexBase			// Pemex (salud)

	* Otros gastos *
	scalar servpers = servpersBase		// Servicios personales
	scalar matesumi = matesumiBase		// Materiales y suministros
	scalar gastgene = gastgeneBase		// Gastos generales
	scalar substran = substranBase		// Subsidios y transferencias
	scalar bienmueb = bienmuebBase		// Bienes muebles e inmuebles
	scalar obrapubl = obrapublBase		// Obras p{c u'}blicas
	scalar invefina = invefinaBase		// Inversi{c o'}n financiera
	scalar partapor = partaporBase		// Participaciones y aportaciones
}

use `"`c(sysdir_personal)'/users/$pais/$id/baseid.dta"', clear
tabstat factor, stat(sum) f(%20.0fc) save
matrix POBLACION = r(StatTotal)

tabstat Pension Educacion Salud OtrosGas [fw=factor], stat(sum) f(%20.0fc) save
matrix GASTOS = r(StatTotal)

replace Pension = (Pension*`Pensiones'/GASTOS[1,1]) ///
	// *(spenims+speniss+spenpem)/(penimsBase+penissBase+penpemBase)
Simulador Pension [fw=factor], base("ENIGH 2018") ///
	reboot //graphs //boot(20) //noisily

replace Educacion = Educacion*`Educacion'/GASTOS[1,2] ///
	// *(sbasica+smedias+ssuperi+sposgra)/(basicaBase+mediasBase+superiBase+posgraBase)
Simulador Educacion [fw=factor], base("ENIGH 2018") ///
	reboot //graphs //boot(20) //noisily

replace Salud = Salud*`Salud'/GASTOS[1,3] ///
	// *(sssa+ssegpop+simss+sissste+sprospe+spemex)/(ssaBase+segpopBase+imssBase+isssteBase+prospeBase+pemexBase)
Simulador Salud [fw=factor], base("ENIGH 2018") ///
	reboot //graphs //boot(20) //noisily

replace OtrosGas = OtrosGas*`OtrosGas'/GASTOS[1,4] ///
	// *(servpers+matesumi+gastgene+substran+bienmueb+obrapubl+invefina+partapor)/(servpersBase+matesumiBase+gastgeneBase+substranBase+bienmuebBase+obrapublBase+invefinaBase+partaporBase)
Simulador OtrosGas [fw=factor], base("ENIGH 2018") ///
	reboot //graphs //boot(20) //noisily

if `c(version)' == 15.1 {
	saveold `"`c(sysdir_personal)'/users/$pais/$id/baseid.dta"', replace version(13)
}
else {
	save `"`c(sysdir_personal)'/users/$pais/$id/baseid.dta"', replace
}


*****************************************/
***                                    ***
*** 6. Parte 4: Balance presupuestario ***
***                                    ***
******************************************
use `"`c(sysdir_personal)'/users/$pais/$id/baseid.dta"', clear
g TransfNetas = Ingreso + Consumo - Pension - Educacion - Salud
if "$pais" == "" {
	replace TransfNetas = TransfNetas - IngBasico - PenBienestar
}
label var TransfNetas "Transferencias Netas"
Simulador TransfNetas if TransfNetas != 0 [fw=factor], base("ENIGH 2018") ///
	reboot graphs //boot(20) //noisily

* Cuentas Generacionales *
noisily CuentasGeneracionales TransfNetas //, anio(2018) //boot(20)				// <-- OPTIONAL!!!

* Sankey SISTEMA FISCAL *
if "$pais" == "" {
	foreach k in sexo grupo_edad decil escol {
		noisily run SankeySF.do `k' 2018
	}
}

* Fiscal Gap: Transferencias Intertemporales */
noisily FiscalGap, graphs end(2050) //anio(2018) //update //boot(20)



********************/
*** 4. Touchdown! ***
*********************
*noisily scalarlatex
timer off 1
timer list 1
noisily di _newline in g _dup(55) "+" in y round(`=r(t1)/r(nt1)',.1) in g " segs." _dup(55) "+"
