**************************
**** HOLA, HUMANO! :) ****
**************************
clear all
macro drop _all
capture log close _all
cd "C:\Users\carlos\Dropbox (CIEP)\Github\simuladorCIEP\"
sysdir set PERSONAL "C:\Users\carlos\Dropbox (CIEP)\Github\simuladorCIEP\"
adopath ++ PERSONAL
timer on 1




global id = "Carlos"
*********************
***               ***
*** 1. Parámetros ***
***               ***
*********************
global pais = "El Salvador"
global pib2019 = 3.47

global pib2020 = -1.9		// Pre-criterios 2021 [-3.9,0.1]
global def2020 = 3.5		// Pre-criterios 2021

global pib2021 = 1.5		// Pre-criterios 2021 [1.5,3.5]
global def2021 = 3.2		// Pre-criterios 2021

global desemp2020 = 0		// Desempleo (para la lambda
global desemp2021 = 0		// Desempleo (para la lambda

** PIB **
noisily PIBDeflactor, graphs //discount(3.0)									<-- Cap. 1. Par{c a'}metros MACRO.
if "$pais" == "" {
	noisily SCN, //graphs //anio(2020) //update									<-- Cap. 2. Explicaci{c o'}n del PIB.
}

** Sankey ECONOMIA **															<-- Cap. 3. Explicaci{c o'}n de la poblaci{c o'}n
*noisily run Households`=subinstr("${pais}"," ","",.)'.do 2018
if "$pais" == "" {
	foreach k in sexo grupo_edad decil escol {
		noisily run Sankey.do `k' 2018
	}
}

** Sistema Fiscal: INGRESOS **/
noisily LIF, by(divGA) lif //anio(2018) //graphs //update						<-- Parte 2.
local alingreso = r(Impuestos_al_ingreso)
local alconsumo = r(Impuestos_al_consumo)
local otrosing = r(Otros_ingresos)

if "$pais" == "" {
	* INGRESOS *
	noisily TasasEfectivas, lif //anio(2018)									<-- Cap. 4.
	
	* Al ingreso *
	scalar sISR_AS  = ISR_ASBase*0		// ISR (asalariados)
	scalar sISR_PF  = ISR_PFBase*0		// ISR (personas f{c i'}sicas)
	scalar sCuotasT = CuotasBase*0		// Cuotas (IMSS)

	* Al consumo *
	scalar sIVA     = IVABase*0+15.493			// IVA: 12.493
	scalar sIEPS    = IEPSBase*0 			// IEPS (no petrolero + petrolero)
	scalar sImporta = ImportaBase*0 		// Importaciones
	scalar sISAN    = ISANBase*0 			// ISAN

	* Al capital *
	scalar sISR_PM  = ISR_PMBase		// ISR (personas morales)
	scalar sFMP     = FMPBase			// Fondo Mexicano del Petr{c o'}leo
	scalar sOYE     = OYEBase			// Organismos y empresas (IMSS + ISSSTE + Pemex + CFE)
	scalar sOtrosI  = OtrosIngBase		// Productos, derechos, aprovechamientos, contribuciones
}

** Sistema Fiscal: GASTOS **
noisily PEF, by(divGA) //anio(2018) //graphs //update			<-- Parte 3.
local OtrosGas = r(Otros)
local Pensiones = r(Pensiones)
local Educacion = r(Educaci_c_o__n)
local Salud = r(Salud)

if "$pais" == "" {
	* GASTOS *
	noisily GastoPC, //pef //anio(2018)											<-- Cap. 5.
	* Pensiones *
	scalar spam    = pamBase*0+4.072			// Pensi{c o'}n BIENESTAR: 4.072
	scalar spenims = penimsBase*0			// Pensi{c o'}n IMSS
	scalar speniss = penissBase*0			// Pensi{c o'}n ISSSTE
	scalar spenpem = penpemBase*0			// Pensi{c o'}n Pemex, CFE, Pensi{c o'}n LFC, ISSFAM, Otros

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
	scalar deudpubl = deudpublBase		// Deuda p{c u'}blica
}

* Extras *
scalar singbas = 0.000				// Ingreso b{c a'}sico	
scalar ingbasico18 = 1				// Ingreso b{c a'}sico a menores de 18 a{c n~}os
scalar ingbasico65 = 1				// Ingreso b{c a'}sico a mayores de 65 a{c n~}os

use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households`=subinstr("${pais}"," ","",.)'.dta"', clear
tabstat factor, stat(sum) f(%20.0fc) save
matrix POBLACION = r(StatTotal)

tabstat Ingreso Consumo Otros [fw=factor], stat(sum) f(%20.0fc) save
matrix INGRESOS = r(StatTotal)

tabstat Pension Educacion Salud OtrosGas [fw=factor], stat(sum) f(%20.0fc) save
matrix GASTOS = r(StatTotal)


********************************************
***                                      ***
*** 4. Parte 2: Ingresos presupuestarios ***
***                                      ***
********************************************
replace Ingreso = Ingreso*`alingreso'/INGRESOS[1,1] ///
	// *(sISR_AS+sISR_PF+sCuotasT+sISR_PM)/(ISR_ASBase+ISR_PFBase+CuotasBase+ISR_PMBase)
noisily Simulador Ingreso [fw=factor], base("ENIGH 2018") ///
	reboot graphs //boot(20) //noisily
	
replace Consumo = Consumo*`alconsumo'/INGRESOS[1,2] ///
	// *(sIVA+sIEPS+sImporta+sISAN)/(IVABase+IEPSBase+ImportaBase+ISANBase) ///
	// +ConsumoImp/100*singbas/100*scalar(pibY)*(1-.0618)/POBLACION[1,1]
noisily Simulador Consumo [fw=factor], base("ENIGH 2018") ///
	reboot graphs //boot(20) //noisily

replace Otros = Otros*`otrosing'/INGRESOS[1,3] ///
	// *(sFMP+sOYE+sOtrosI)/(FMPBase+OYEBase+OtrosIngBase)
noisily Simulador Otros [fw=factor], base("ENIGH 2018") ///
	reboot graphs //boot(20) //noisily


*****************************************
***                                    ***
*** 5. Parte 3: Gastos presupuestarios ***
***                                    ***
******************************************
replace Pension = Pension*`Pensiones'/GASTOS[1,1] ///
	// *(spam+spenims+speniss+spenpem)/(pamBase+penimsBase+penissBase+penpemBase)
noisily Simulador Pension [fw=factor], base("ENIGH 2018") ///
	reboot //graphs //boot(20) //noisily

replace Educacion = Educacion*`Educacion'/GASTOS[1,2] ///
	// *(sbasica+smedias+ssuperi+sposgra)/(basicaBase+mediasBase+superiBase+posgraBase)
noisily Simulador Educacion [fw=factor], base("ENIGH 2018") ///
	reboot graphs //boot(20) //noisily

replace Salud = Salud*`Salud'/GASTOS[1,3] ///
	// *(sssa+ssegpop+simss+sissste+sprospe+spemex)/(ssaBase+segpopBase+imssBase+isssteBase+prospeBase+pemexBase)
noisily Simulador Salud [fw=factor], base("ENIGH 2018") ///
	reboot graphs //boot(20) //noisily

replace OtrosGas = OtrosGas*`OtrosGas'/GASTOS[1,4] ///
	// *(servpers+matesumi+gastgene+substran+bienmueb+obrapubl+invefina+partapor+deudpubl)/(servpersBase+matesumiBase+gastgeneBase+substranBase+bienmuebBase+obrapublBase+invefinaBase+partaporBase+deudpublBase)
noisily Simulador OtrosGas [fw=factor], base("ENIGH 2018") ///
	reboot graphs //boot(20) //noisily

if ingbasico18 == 0 & ingbasico65 == 1 {
	tabstat factor if edad >= 18, stat(sum) f(%20.0fc) save
	matrix POBLACION = r(StatTotal)
	g IngBasico = singbas/100*scalar(pibY)/POBLACION[1,1] if edad >= 18
}
else if ingbasico18 == 1 & ingbasico65 == 0 {
	tabstat factor if edad < 65, stat(sum) f(%20.0fc) save
	matrix POBLACION = r(StatTotal)
	g IngBasico = singbas/100*scalar(pibY)/POBLACION[1,1] if edad < 65
}
else if ingbasico18 == 0 & ingbasico65 == 0 {
	tabstat factor if edad < 65 & edad >= 18, stat(sum) f(%20.0fc) save
	matrix POBLACION = r(StatTotal)
	g IngBasico = singbas/100*scalar(pibY)/POBLACION[1,1] if edad >= 18 & edad < 65
}
g IngBasico = singbas/100*scalar(pibY)/POBLACION[1,1]
label var IngBasico "Ingreso b{c a'}sico"
Simulador IngBasico if IngBasico != 0 [fw=factor], base("ENIGH 2018") ///
	reboot //graphs //boot(20) //noisily


*****************************************
***                                    ***
*** 6. Parte 4: Balance presupuestario ***
***                                    ***
******************************************
g TransfNetas = Ingreso + Consumo - Pension - Educacion - Salud - IngBasico
label var TransfNetas "Transferencias Netas"
noisily Simulador TransfNetas if TransfNetas != 0 [fw=factor], base("ENIGH 2018") ///
	reboot graphs //boot(20) //noisily

* Cuentas Generacionales *
noisily CuentasGeneracionales TransfNetas //, anio(2018) //boot(20)			// <-- OPTIONAL!!!

* Sankey SISTEMA FISCAL *
if "$pais" == "" {
	foreach k in sexo grupo_edad decil escol {
		noisily run Sankey.do `k' 2018											<-- TO DO!
	}
}

* Fiscal Gap: Transferencias Intertemporales */
noisily FiscalGap, graphs end(2040) //anio(2018) //update //boot(20)



*********************/
*** 4. Touchdown! ***
*********************
*noisily scalarlatex
timer off 1
timer list 1
noisily di _newline in g _dup(55) "+" in y round(`=r(t1)/r(nt1)',.1) in g " segs." _dup(55) "+"
