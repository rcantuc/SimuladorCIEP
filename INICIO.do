**************************
**** HOLA, HUMANO! :) ****
**************************
clear all
macro drop _all
capture log close _all
if "`c(os)'" == "Unix" {
	cd "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
}
if "`c(os)'" == "MacOSX" {
	cd "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	sysdir set PERSONAL "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
}
adopath ++ PERSONAL
timer on 1
noisily di _newline(40) in g _dup(60) "~"





*************************
*** 1 Par{c a'}metros ***
*************************
global export "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Textbook/images/"
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) 	// anio BASE


** PIB + Deflactor: Paquete Economico 2020 (pre-Covid) **
global pib2020 = 2.0		// Criterios 2020 [1.5,2.5]
global pib2021 = 2.6		// Criterios 2020 [2.6]

global def2020 = 4.5		// Criterios 2020 [4.5]
global def2021 = 3.6		// Criterios 2020 [3.6]


** PIB + Deflactor: Pre-Criterios 2021 (post-Covid) **
global pib2020 = -1.9		// Pre-criterios 2021 [-3.9,0.1]
global pib2021 = 2.5		// Pre-criterios 2021 [1.5,3.5]

global def2020 = 3.5		// Pre-criterios 2021 [3.5]
global def2021 = 3.2		// Pre-criterios 2021 [3.2]


** Economía BASE (laborales, capital, consumo, depreciacion) **					<-- Cap. 2. Sistema: Cuentas Nacionales
noisily PIBDeflactor, graphs //discount(3.0)									
noisily SCN, anio(`anio') graphs


** Poblacion BASE: ENIGH 2018 **												<-- Cap. 3. Agentes econ{c o'}micos
*if "go" == "no" & "`c(os)'" == "Unix" {
	noisily run Households.do 2018
	foreach k in grupo_edad sexo decil escol {
		noisily run Sankey.do `k' 2018
	}
*}





exit











** INGRESOS **
*noisily TasasEfectivas, lif													//<-- Cap. 4.




** INGRESO BASICO **
scalar IngBas = 0
scalar IngBasLP = 0							// 1: largo plazo; 0: corto plazo

scalar ingbasico18 = 1						// Incluye menores de 18 anios
scalar ingbasico65 = 1						// Incluye mayores de 65 anios


** PENSION BIENESTAR **
scalar Bienestar = 0
scalar BienestarLP = 0						// 1: largo plazo; 0: corto plazo


* Al ingreso *
local ISR_AS  = 3.496 // *0			//ISR_ASBase	// ISR (asalariados)
local ISR_PF  = 0.204 // *0			//ISR_PFBase	// ISR (personas f{c i'}sicas)
local CuotasT = 1.520 // *0			//CuotasBase	// Cuotas (IMSS)

* Al consumo *
local IVA     = 4.094 // +3.496+0.204+1.520+0.288+IngBas	//IVABase+ISR_ASBase+ISR_PFBase+CuotasBase+ImportaBase+IngBas	// IVA 
local IEPS    = 2.096			//IEPSBase 		// IEPS (no petrolero + petrolero)
local Importa = 0.288 //*0			//ImportaBase	// Importaciones
local ISAN    = 0.044		 	//ISANBase 		// ISAN

* Al capital *
local ISR_PM  = 3.829			//ISR_PMBase	// ISR (personas morales)
local FMP     = 1.677			//FMPBase		// Fondo Mexicano del Petr{c o'}leo
local OYE     = 4.328			//OYEBase		// Organismos y empresas (IMSS + ISSSTE + Pemex + CFE)
local OtrosI  = 0.867			//OtrosIngBase	// Productos, derechos, aprovechamientos, contribuciones

* Scalars *
scalar IngresosLP = 0															// 1: largo plazo; 0: corto plazo
scalar IngresosGW = 1 // (`ISR_AS'+`ISR_PF'+`CuotasT'+`ISR_PM')/((`alingreso')/scalar(pibY)*100)

scalar ConsumoLP = 0															// 1: largo plazo; 0: corto plazo
scalar ConsumoGW = 1 // (`IVA'+`IEPS'+`Importa'+`ISAN' ///
	// + IngBas*(1-6.270/100)*9.9/100 ///
	// + ((3.496+0.204+1.520+3.829) - (`ISR_AS'+`ISR_PF'+`CuotasT'+`ISR_PM'))*(1-6.270/100)*9.9/100 ///
	// )/(`alconsumo'/scalar(pibY)*100)

scalar OtrosILP = 0																// 1: largo plazo; 0: corto plazo
scalar OtrosIGW = 1 // (`FMP'+`OYE'+`OtrosI')/(`otrosing'/scalar(pibY)*100)



** IMPUESTO UNICO **
noisily di _newline in g "  Impuesto {c U'}nico" ///
	in y %10.3fc (`IVA')/(65.686-14.387-1.806)*100 /// ConHogPIB-AlimPIB-BebNPIB
	in g " % Consumo no basico (inclusivo)"
noisily di in g "  Impuesto {c U'}nico" ///
	in y %10.3fc (`IVA')/(65.686)*100 ///
	in g " % Consumo de los hogares (inclusivo)"
noisily di _newline in g "  Impuesto {c U'}nico" ///
	in y %10.3fc (`IVA')/(65.686-14.387-1.806-(`IVA'))*100 /// ConHogPIB-AlimPIB-BebNPIB
	in g " % Consumo no basico (exclusivo)"
noisily di in g "  Impuesto {c U'}nico" ///
	in y %10.3fc (`IVA')/(65.686-(`IVA'))*100 ///
	in g " % Consumo de los hogares (exclusivo)"



** GASTOS PRESUPUESTARIOS **
*noisily GastoPC, //pef //anio(2018)										<-- Cap. 5.

* Pensiones *
scalar penims = 1.985 // *0		//penimsBase 	// Pensi{c o'}n IMSS
scalar peniss = 0.998 // *0		//penissBase 	// Pensi{c o'}n ISSSTE
scalar penpem = 0.938 // *0		//penpemBase 	// Pensi{c o'}n Pemex, CFE, Pensi{c o'}n LFC, ISSFAM, Otros

* Educacion *
scalar basica = 2.018			//basicaBase	// Educaci{c o'}n b{c a'}sica
scalar medsup = 0.464			//mediasBase	// Educaci{c o'}n media superior
scalar superi = 0.524			//superiBase	// Educaci{c o'}n superior
scalar posgra = 0.030			//posgraBase	// Posgrado

* Salud *
scalar ssa    = 0.198			//ssaBase		// SSalud
scalar segpop = 0.715			//segpopBase	// Seguro Popular
scalar imss   = 1.298			//imssBase		// IMSS (salud)
scalar issste = 0.257			//isssteBase	// ISSSTE (salud)
scalar prospe = 0.054			//prospeBase	// IMSS-Prospera
scalar pemex  = 0.080			//pemexBase		// Pemex (salud)

* Otros gastos *
scalar servpers = 1.773 		//servpersBase	// Servicios personales
scalar matesumi = 1.094 		//matesumiBase	// Materiales y suministros
scalar gastgene = 0.930 		//gastgeneBase	// Gastos generales
scalar substran = 1.021 // *0 	//substranBase	// Subsidios y transferencias
scalar bienmueb = 0.133 		//bienmuebBase	// Bienes muebles e inmuebles
scalar obrapubl = 1.460 		//obrapublBase	// Obras p{c u'}blicas
scalar invefina = 0.419 		//invefinaBase	// Inversi{c o'}n financiera
scalar partapor = 4.843			//partaporBase	// Participaciones y aportaciones
scalar costodeu = 3.043			//costodeuBase	// Costo de la deuda

* GASTOS *
*noisily GastoPCSIM, //anio(2018)

* Scalars *
scalar PensionesLP = 0															// 1: largo plazo; 0: corto plazo
scalar PensionesGW = (penims+peniss+penpem)/(1.985+0.998+0.938)

scalar EducacionLP = 0															// 1: largo plazo; 0: corto plazo
scalar EducacionGW = (basica+medsup+superi+posgra)/(2.018+0.464+0.524+0.030)

scalar SaludLP = 0																// 1: largo plazo; 0: corto plazo
scalar SaludGW = (scalar(ssa)+scalar(segpop)+scalar(imss)+scalar(issste)+scalar(prospe)+scalar(pemex))/(0.198+0.715+1.298+0.257+0.054+0.080)

scalar OtrosGasLP = 0															// 1: largo plazo; 0: corto plazo
scalar OtrosGasGW = (servpers+matesumi+gastgene+substran+bienmueb+obrapubl+invefina+partapor)/(2.038+1.094+0.930+1.021+0.133+1.460+0.491+4.843)



	
	
************************
*** 2 Poblaci{c o'}n ***
************************

** A. POBLACION SIM **
use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households.dta"', clear

** (+) Ingreso BASICO **
if ingbasico18 == 0 & ingbasico65 == 1 {
	tabstat factor if edad >= 18, stat(sum) f(%20.0fc) save
	matrix POBLACION1 = r(StatTotal)
	g IngBasico = IngBas/100*scalar(pibY)/POBLACION1[1,1] if edad >= 18
}
else if ingbasico18 == 1 & ingbasico65 == 0 {
	tabstat factor if edad < 68, stat(sum) f(%20.0fc) save
	matrix POBLACION2 = r(StatTotal)
	g IngBasico = IngBas/100*scalar(pibY)/POBLACION2[1,1] if edad < 68
}
else if ingbasico18 == 0 & ingbasico65 == 0 {
	tabstat factor if edad < 68 & edad >= 18, stat(sum) f(%20.0fc) save
	matrix POBLACION3 = r(StatTotal)
	g IngBasico = IngBas/100*scalar(pibY)/POBLACION3[1,1] if edad >= 18 & edad < 68
}
else { 
	tabstat factor, stat(sum) f(%20.0fc) save
	matrix POBLACION = r(StatTotal)
	g IngBasico = IngBas/100*scalar(pibY)/POBLACION[1,1]
}
label var IngBasico "Ingreso b{c a'}sico"
Simulador IngBasico [fw=factor], base("ENIGH 2018") ///
	boot(1) reboot //graphs

** (+) Pension BIENESTAR **
tabstat factor if edad >= 68, stat(sum) f(%20.0fc) save
matrix POBLACION68 = r(StatTotal)

capture g PenBienestar = scalar(Bienestar)/100*scalar(pibY)/POBLACION68[1,1] if edad >= 68
if _rc != 0 {
	replace PenBienestar = scalar(Bienestar)/100*scalar(pibY)/POBLACION68[1,1] if edad >= 68
}
replace PenBienestar = 0 if PenBienestar == .
label var PenBienestar "Pensi{c o'}n Bienestar"
Simulador PenBienestar [fw=factor], base("ENIGH 2018") ///
	boot(1) reboot //graphs

tabstat IngBasico PenBienestar [fw=factor], stat(sum) f(%20.0fc)
save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace





*********************************/
*** 3 Sistema Fiscal: INGRESOS ***
**********************************
LIF if anio == `anio', anio(`anio') by(divGA) lif //graphs //update					<-- Parte 2.
local ingresostot = r(Ingresos_sin_deuda)
local alingreso = r(Impuestos_al_ingreso)
local alconsumo = r(Impuestos_al_consumo)
local otrosing = r(Ingresos_de_capital)


** A. POBLACION SIM **
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
tabstat Ingreso Consumo Otros ISR__PM [fw=factor], stat(sum) f(%20.0fc) save
matrix INGRESOS = r(StatTotal)

replace Ingreso = Ingreso*(`alingreso')/INGRESOS[1,1]*scalar(IngresosGW)
replace Consumo = Consumo*`alconsumo'/INGRESOS[1,2]*scalar(ConsumoGW)
replace Otros = Otros*(`otrosing')/INGRESOS[1,3]*scalar(OtrosIGW)
replace ISR__PM = ISR__PM*(`ISR_PM'/100*scalar(pibY))/INGRESOS[1,4]

tabstat Ingreso Consumo Otros ISR__PM [fw=factor], stat(sum) f(%20.0fc) save
matrix INGRESOSSIM = r(StatTotal)
save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace


** B. ESTIMACIONES LP SIM **

* (+) Al ingreso *
use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/IngresoREC"', clear
tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
tempname INGRESOS
matrix `INGRESOS' = r(StatTotal)

if scalar(IngresosLP) == 1 {
	replace estimacion = estimacion*INGRESOSSIM[1,1]/`INGRESOS'[1,1]
}
else {
	replace estimacion = estimacion*`alingreso'/`INGRESOS'[1,1] if anio != `anio'
	replace estimacion = estimacion*INGRESOSSIM[1,1]/`INGRESOS'[1,1] if anio == `anio'
}
save `"`c(sysdir_personal)'/users/$pais/$id/IngresoREC.dta"', replace


* (+) Al consumo *
use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/ConsumoREC"', clear 
tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
tempname CONSUMO
matrix `CONSUMO' = r(StatTotal)

if scalar(ConsumoLP) == 1 {
	replace estimacion = estimacion*INGRESOSSIM[1,2]/`CONSUMO'[1,1]
}
else {
	replace estimacion = estimacion*`alconsumo'/`CONSUMO'[1,1] if anio != `anio'
	replace estimacion = estimacion*INGRESOSSIM[1,2]/`CONSUMO'[1,1] if anio == `anio'
}
save `"`c(sysdir_personal)'/users/$pais/$id/ConsumoREC.dta"', replace


* (+) Al capital *
use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/OtrosREC"', clear
tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
tempname OTROS
matrix `OTROS' = r(StatTotal)

if scalar(OtrosILP) == 1 {
	replace estimacion = estimacion*INGRESOSSIM[1,3]/`OTROS'[1,1]
}
else {
	replace estimacion = estimacion*`otrosing'/`OTROS'[1,1] if anio != `anio'
	replace estimacion = estimacion*INGRESOSSIM[1,3]/`OTROS'[1,1] if anio == `anio'
}
save `"`c(sysdir_personal)'/users/$pais/$id/OtrosREC.dta"', replace





*******************************/
*** 4 Sistema Fiscal: GASTOS ***
********************************
PEF if anio == `anio', anio(`anio') by(divGA) pef //graphs //update					<-- Parte 3.
local gastostot = r(Resumido_total)
local OtrosGas = r(Otros)
local Pensiones = r(Pensiones)
local Educacion = r(Educaci_c_o__n)
local Salud = r(Salud)
local CostoDeuda = r(Costo_de_la_deuda)
local Amort = r(Amortizaci_c_o__n)
local cuotasissste = r(Cuotas_ISSSTE)


** A. POBLACION SIM **
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear

tabstat Pension Educacion Salud OtrosGas [fw=factor], stat(sum) f(%20.0fc) save
matrix GASTOS = r(StatTotal)

replace Pension = Pension*`Pensiones'/GASTOS[1,1]*PensionesGW
replace Educacion = Educacion*`Educacion'/GASTOS[1,2]*EducacionGW
replace Salud = Salud*`Salud'/GASTOS[1,3]*SaludGW
replace OtrosGas = OtrosGas*`OtrosGas'/GASTOS[1,4]*OtrosGasGW

tabstat ing_subor if scian == "93" [fw=factor], stat(sum) f(%20.0fc) save
tempname salarios
matrix `salarios' = r(StatTotal)

g Salarios = ing_subor*scalar(servpers)/100*scalar(pibY)/`salarios'[1,1] if scian == "93"
replace Salarios = 0 if Salarios == .

tabstat Educacion Pension Salud OtrosGas [fw=factor], stat(sum) f(%20.0fc) save
matrix GASTOSSIM = r(StatTotal)
save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace


** B. ESTIMACIONES LP SIM **

* (-) Pensiones *
use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/PensionREC"', clear
tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
tempname PensionREC
matrix `PensionREC' = r(StatTotal)

if scalar(PensionesLP) == 1 {
	replace estimacion = estimacion*GASTOSSIM[1,2]/`PensionREC'[1,1]
}
else {
	replace estimacion = estimacion*`Pensiones'/`PensionREC'[1,1] if anio != `anio'
	replace estimacion = estimacion*GASTOSSIM[1,2]/`PensionREC'[1,1] if anio == `anio'
}
save `"`c(sysdir_personal)'/users/$pais/$id/PensionREC.dta"', replace


* (-) Educacion *
use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/EducacionREC"', clear
tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
tempname EducacionREC
matrix `EducacionREC' = r(StatTotal)

if scalar(EducacionLP) == 1 {
	replace estimacion = estimacion*GASTOSSIM[1,1]/`EducacionREC'[1,1]
}
else {
	replace estimacion = estimacion*`Educacion'/`EducacionREC'[1,1] if anio != `anio'
	replace estimacion = estimacion*GASTOSSIM[1,1]/`EducacionREC'[1,1] if anio == `anio'
}
save `"`c(sysdir_personal)'/users/$pais/$id/EducacionREC.dta"', replace


* (-) Salud *
use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/SaludREC"', clear
tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
tempname SaludREC
matrix `SaludREC' = r(StatTotal)

if scalar(SaludLP) == 1 {
	replace estimacion = estimacion*GASTOSSIM[1,3]/`SaludREC'[1,1]
}
else {
	replace estimacion = estimacion*`Salud'/`SaludREC'[1,1] if anio != `anio'
	replace estimacion = estimacion*GASTOSSIM[1,3]/`SaludREC'[1,1] if anio == `anio'
}
save `"`c(sysdir_personal)'/users/$pais/$id/SaludREC.dta"', replace


* (-) Otros gastos *
use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/OtrosGasREC"', clear
tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
tempname OtrosGasREC
matrix `OtrosGasREC' = r(StatTotal)

if scalar(OtrosGasLP) == 1 {
	replace estimacion = estimacion*GASTOSSIM[1,4]/`OtrosGasREC'[1,1]
}
else {
	replace estimacion = estimacion*`OtrosGas'/`OtrosGasREC'[1,1] if anio != `anio'
	replace estimacion = estimacion*GASTOSSIM[1,4]/`OtrosGasREC'[1,1] if anio == `anio'
}
save `"`c(sysdir_personal)'/users/$pais/$id/OtrosGasREC.dta"', replace





*****************************************/
***                                    ***
*** 6. Parte 4: Balance presupuestario ***
***                                    ***
******************************************
noisily di _newline(2) in g "{bf: POL{c I'}TICA FISCAL " in y "`anio'" "}"
noisily di in g "  (+) Ingresos: " ///
	_col(30) in y %20.0fc (INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3]) in g " USD" ///
	_col(60) in y %8.1fc (INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3])/scalar(pibY)*100 in g "% PIB"
noisily di in g "  (-) Gastos: " ///
	_col(30) in y %20.0fc (GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort'+scalar(IngBas)/100*scalar(pibY)+scalar(Bienestar)/100*scalar(pibY)) in g " USD" ///
	_col(60) in y %8.1fc (GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort')/scalar(pibY)*100 + scalar(IngBas) + scalar(Bienestar) in g "% PIB"
noisily di _dup(72) in g "-"
noisily di in g "  (=) Balance "in y "econ{c o'}mico" in g ": " ///
	_col(30) in y %20.0fc (INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3] ///
	-(GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort'+scalar(IngBas)/100*scalar(pibY)+scalar(Bienestar)/100*scalar(pibY))) in g " USD" ///
	_col(60) in y %8.1fc (INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3] ///
	-(GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort'))/scalar(pibY)*100 - scalar(IngBas) - scalar(Bienestar) in g "% PIB"
noisily di in g "  (*) Balance " in y "primario" in g ": " ///
	_col(30) in y %20.0fc (((INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3])) ///
	-((GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort'+scalar(IngBas)/100*scalar(pibY)+scalar(Bienestar)/100*scalar(pibY))) ///
	+`CostoDeuda') in g " USD" ///
	_col(60) in y %8.1fc (((INGRESOSSIM[1,1]+INGRESOSSIM[1,2]+INGRESOSSIM[1,3])) ///
	-((GASTOSSIM[1,1]+GASTOSSIM[1,2]+GASTOSSIM[1,3]+GASTOSSIM[1,4]+`CostoDeuda'+`Amort')) ///
	+`CostoDeuda')/scalar(pibY)*100 - scalar(IngBas) - scalar(Bienestar) in g "% PIB"


** C. POBLACION SIMULADA **
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear

g TransfNetas = Ingreso + Consumo + ISR__PM - Pension - Educacion - Salud -  IngBasico - PenBienestar
label var TransfNetas "Transferencias Netas"
Simulador TransfNetas if TransfNetas != 0 [fw=factor], base("ENIGH 2018") ///
	boot(1) reboot graphs

save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace


/** D. CUENTAS GENERACIONALES **
noisily CuentasGeneracionales TransfNetas, //boot(250)								// <-- OPTIONAL!!! Toma mucho tiempo.


** E. SANKEY **/
foreach k in sexo grupo_edad decil escol {
	noisily run SankeySF.do `k' `anio'
}


** F. FISCAL GAP **/
noisily FiscalGap, graphs end(2050) //boot(250) //update





********************/
*** 4. Touchdown! ***
*********************
*noisily scalarlatex
timer off 1
timer list 1
noisily di _newline in g _dup(55) "+" in y round(`=r(t1)/r(nt1)',.1) in g " segs." _dup(55) "+"
