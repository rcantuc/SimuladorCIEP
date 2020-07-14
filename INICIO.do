********************
**** WAKE UP!!! ****
********************
clear all
macro drop _all
capture log close _all

if "`c(os)'" == "Unix" {
	cd "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	global export "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Textbook/images/"
}
if "`c(os)'" == "MacOSX" {
	cd "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	sysdir set PERSONAL "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	global export "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Textbook/images/"
}
adopath ++ PERSONAL

timer on 1
noisily di _newline(5) in g _dup(60) ":" 
noisily di in g _dup(20) ":" in y "  HOLA, HUMANO! 8)  " in g _dup(20) ":"
noisily di in g _dup(60) ":"




********************
*** 1 PARAMETROS ***
********************
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) // 								anio BASE

** PIB + Deflactor: Paquete Economico 2020 (pre-Covid) **
global pib2020 = 2.0 // 														Criterios 2020 [1.5,2.5]
global pib2021 = 2.6 // 														Criterios 2020 [2.6]

global def2020 = 4.5 // 														Criterios 2020 [4.5]
global def2021 = 3.6 // 														Criterios 2020 [3.6]

** PIB + Deflactor: Pre-Criterios 2021 (post-Covid) **
global pib2020 = -1.9 // 														Pre-criterios 2021 [-3.9,0.1]
global pib2021 = 2.5 // 														Pre-criterios 2021 [1.5,3.5]

global def2020 = 3.5 // 														Pre-criterios 2021 [3.5]
global def2021 = 3.2 // 														Pre-criterios 2021 [3.2]

*global lambda = 1



*******************************
*** 2 POBLACION: ENIGH 2018 ***													Cap. 3. Agentes economicos
/*******************************
Poblacion, anio(`anio') graphs //`update'
noisily run Households.do 2018
foreach k in grupo_edad sexo decil escol {
	noisily run Sankey.do `k' 2018
}




***************************/
*** 3 ECONOMIA Y CUENTAS ***													Cap. 2. Sistema: Cuentas Nacionales
****************************
noisily PIBDeflactor, graphs //update //discount(3.0)
tempfile PIB
save `PIB'




******************
*** 4 INGRESOS ***
******************
* Transferencias monetarias *
scalar IngBas = 0+2 //														Ingreso b{c a'}sico
scalar ingbasico18 = 1			// Incluye menores de 18 anios
scalar ingbasico65 = 1			// Incluye mayores de 65 anios

* Al ingreso *
scalar ISR_AS  = 3.496*0 // 												ISR (asalariados)
scalar ISR_PF  = 0.204*0 // 												ISR (personas f{c i'}sicas)
scalar CuotasT = 1.520*0 // 												Cuotas (IMSS)

* Al consumo *
scalar IVA     = 4.094+IngBas*(1-.06270)*0.172+3.496+0.204+1.520+IngBas //	IVA 
scalar ISAN    = 0.044 //														ISAN
scalar IEPS    = 2.096 // 														IEPS (no petrolero + petrolero)
scalar Importa = 0.288 //														Importaciones

* Al capital *
scalar ISR_PM  = 3.829 //														ISR (personas morales)
scalar FMP     = 1.677 // 														Fondo Mexicano del Petr{c o'}leo
scalar OYE     = 4.328 //														Organismos y empresas (IMSS + ISSSTE + Pemex + CFE)
scalar OtrosI  = 0.867 //														Productos, derechos, aprovechamientos, contribuciones

noisily TasasEfectivas //														Cap. 4. Ingresos




****************
*** 5 GASTOS ***
****************
* Pensiones *
scalar penims = 1.985*0	//													Pensi{c o'}n IMSS
scalar peniss = 0.998*0	//													Pensi{c o'}n ISSSTE
scalar penotr = 0.938*0 //													Pensi{c o'}n Pemex, CFE, Pensi{c o'}n LFC, ISSFAM, Otros
scalar Bienestar = 0.583+1.985+0.998+0.938 //								Pensi{c o'}n Bienestar

* Educacion *
scalar basica = 2.018 //														Educaci{c o'}n b{c a'}sica
scalar medsup = 0.464 //														Educaci{c o'}n media superior
scalar superi = 0.547 //														Educaci{c o'}n superior
scalar posgra = 0.033 //														Posgrado

* Salud *
scalar ssa    = 0.211+0.715+1.298+0.257+0.054+0.051+0.038 //														SSalud
scalar segpop = 0.715*0 //														Seguro Popular
scalar imss   = 1.298*0 //														IMSS (salud)
scalar issste = 0.257*0 //														ISSSTE (salud)
scalar prospe = 0.054*0 //														IMSS-Prospera
scalar pemex  = 0.051*0 //														Pemex (salud)
scalar issfam = 0.038*0 //														ISSFAM

* Otros gastos *
scalar servpers = 1.773 //														Servicios personales
scalar matesumi = 1.094 //														Materiales y suministros
scalar gastgene = 0.930 //														Gastos generales
scalar substran = 1.021*0 //														Subsidios y transferencias
scalar bienmueb = 0.133 // 														Bienes muebles e inmuebles
scalar obrapubl = 1.460*2 //														Obras p{c u'}blicas
scalar invefina = 0.419 // 														Inversi{c o'}n financiera
scalar partapor = 4.844 // 														Participaciones y aportaciones
scalar costodeu = 3.043 //														Costo de la deuda

noisily GastoPC //																Cap. 5




********************
*** 6 Incidencia ***
********************
use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households.dta"', clear

* Ingresos *
tabstat Laboral Consumo Otros ISR__PM ing_cap_fmp [fw=factor], stat(sum) f(%20.0fc) save
matrix INGRESOS = r(StatTotal)

replace Laboral = Laboral*((scalar(ISR_AS)+scalar(ISR_PF)+scalar(CuotasT))/100*scalar(PIB))/INGRESOS[1,1]
replace Consumo = Consumo*((scalar(IVA)+scalar(ISAN)+scalar(IEPS)+scalar(Importa))/100*scalar(PIB))/INGRESOS[1,2]
replace Otros = Otros*((scalar(ISR_PM)+scalar(FMP)+scalar(OYE)+scalar(OtrosI))/100*scalar(PIB))/INGRESOS[1,3]
replace ISR__PM = ISR__PM*((scalar(ISR_PM))/100*scalar(PIB))/INGRESOS[1,4]
replace ing_cap_fmp = ing_cap_fmp*((scalar(FMP))/100*scalar(PIB))/INGRESOS[1,5]

tabstat Laboral Consumo Otros [fw=factor], stat(sum) f(%20.0fc) save
matrix INGRESOSSIM = r(StatTotal)

* Gastos *
tabstat Pension Educacion Salud OtrosGas [fw=factor], stat(sum) f(%20.0fc) save
matrix GASTOS = r(StatTotal)

replace Pension = Pension*((scalar(penims)+scalar(peniss)+scalar(penotr))/100*scalar(PIB))/GASTOS[1,1]
replace Educacion = Educacion*((scalar(basica)+scalar(medsup)+scalar(superi)+scalar(posgra))/100*scalar(PIB))/GASTOS[1,2]

replace Salud = Salud*((scalar(ssa)+scalar(segpop)+scalar(imss)+scalar(issste)+scalar(prospe)+scalar(pemex)+scalar(issfam))/100*scalar(PIB))/GASTOS[1,3]

replace OtrosGas = OtrosGas*((scalar(servpers)+scalar(matesumi)+scalar(gastgene)+scalar(substran)+ ////
	scalar(bienmueb)+scalar(obrapubl)+scalar(invefina)+scalar(partapor))/100*scalar(PIB))/GASTOS[1,4]

tabstat Pension Educacion Salud OtrosGas [fw=factor], stat(sum) f(%20.0fc) save
matrix GASTOSSIM = r(StatTotal)

* Ingreso basico *
tabstat IngBasico [fw=factor], stat(sum) f(%20.0fc) save
matrix INGBAS = r(StatTotal)

if ingbasico18 == 0 & ingbasico65 == 1 {
	tabstat factor if edad >= 18, stat(sum) f(%20.0fc) save
	matrix POBLACION = r(StatTotal)
	replace IngBasico = (scalar(IngBas)/100*scalar(PIB))/POBLACION[1,1] if edad >= 18
}
else if ingbasico18 == 1 & ingbasico65 == 0 {
	tabstat factor if edad < 68, stat(sum) f(%20.0fc) save
	matrix POBLACION = r(StatTotal)
	replace IngBasico = (scalar(IngBas)/100*scalar(PIB))/POBLACION[1,1] if edad < 68
}
else if ingbasico18 == 0 & ingbasico65 == 0 {
	tabstat factor if edad < 68 & edad >= 18, stat(sum) f(%20.0fc) save
	matrix POBLACION = r(StatTotal)
	replace IngBasico = (scalar(IngBas)/100*scalar(PIB))/POBLACION[1,1] if edad >= 18 & edad < 68
}
else { 
	tabstat factor, stat(sum) f(%20.0fc) save
	matrix POBLACION = r(StatTotal)
	replace IngBasico = (scalar(IngBas)/100*scalar(PIB))/POBLACION[1,1] 
}

* Pension Bienestar *
tabstat factor if edad >= 68, stat(sum) f(%20.0fc) save
matrix POBLACION68 = r(StatTotal)

replace PenBienestar = scalar(Bienestar)/100*scalar(PIB)/POBLACION68[1,1] if edad >= 68

* Servicios profesionales *
tabstat ing_subor if scian == "93" [fw=factor], stat(sum) f(%20.0fc) save
tempname salarios
matrix `salarios' = r(StatTotal)

g Salarios = ing_subor*scalar(servpers)/100*scalar(pibY)/`salarios'[1,1] if scian == "93"
replace Salarios = 0 if Salarios == .

tabstat IngBasico PenBienestar [fw=factor], stat(sum) f(%20.0fc) save
matrix TRANSFSIM = r(StatTotal)

* Transferencias Netas *
g TransfNetas = Laboral + Consumo + ISR__PM - Pension - Educacion - Salud - IngBasico - PenBienestar
label var TransfNetas "Transferencias Netas"
noisily Simulador TransfNetas if TransfNetas != 0 [fw=factor], base("ENIGH 2018") ///
	boot(1) graphs reboot

keep folio* factor* Laboral Consumo ISR__PM ing_cap_fmp ///
	Pension Educacion Salud IngBasico PenBienestar Salarios OtrosGas TransfNetas ///
	sexo grupo_edad decil escol edad
save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace




******************************
** 8 Cuentas Generacionales **
******************************
noisily CuentasGeneracionales TransfNetas, //boot(250)								// <-- OPTIONAL!!! Toma mucho tiempo.




**************************
** 7 Estimaciones de LP **
**************************
tempname RECBase
local j = 1
foreach k in Laboral Consumo Otros {
	use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/`k'REC"', clear
	merge 1:1 (anio) using `PIB', nogen keepus(lambda)
	tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
	matrix `RECBase' = r(StatTotal)

	replace estimacion = estimacion*INGRESOSSIM[1,`j']/`RECBase'[1,1]*lambda //if anio >= `anio'

	local ++j
	save `"`c(sysdir_personal)'/users/$pais/$id/`k'REC.dta"', replace
}

tempname GASBase
local j = 1
foreach k in Pension Educacion Salud OtrosGas {
	use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/`k'REC"', clear
	merge 1:1 (anio) using `PIB', nogen keepus(lambda)
	tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
	matrix `GASBase' = r(StatTotal)

	replace estimacion = estimacion*GASTOSSIM[1,`j']/`GASBase'[1,1]*lambda //if anio > `anio'

	local ++j
	save `"`c(sysdir_personal)'/users/$pais/$id/`k'REC.dta"', replace
}

tempname TRABase
local j = 1
foreach k in IngBasico PenBienestar {
	use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/`k'REC"', clear
	merge 1:1 (anio) using `PIB', nogen keepus(lambda)
	tabstat estimacion if anio == `anio', stat(sum) f(%20.0fc) save
	matrix `TRABase' = r(StatTotal)

	replace estimacion = estimacion*TRANSFSIM[1,`j']/`TRABase'[1,1]*lambda //if anio > `anio'

	local ++j
	save `"`c(sysdir_personal)'/users/$pais/$id/`k'REC.dta"', replace
}




**************
** 9 SANKEY **
**************
foreach k in sexo grupo_edad decil escol {
	noisily run SankeySF.do `k' `anio'
}




*******************
** 10 FISCAL GAP **
*******************
noisily FiscalGap, graphs end(2050) //boot(250) //update




************************/
**** Touchdown!!! :) ****
*************************
*noisily scalarlatex
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
