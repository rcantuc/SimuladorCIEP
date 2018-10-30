**************************
**** HOLA, HUMANO! :) ****
**************************
clear all
timer on 1
set scheme simulador
set more off




****************************************
*** 1. Parametros Macroecon${o}micos ***
****************************************
global anioVP = 2018

global pib2018 = 2.5					// pib${anioVP}: debe estar definido (PIBDeflactor.ado)
global pib2019 = 3.0					// pib${anioVP}: debe estar definido (PIBDeflactor.ado)

global def2018 = 4.8					// def${anioVP}: debe estar definido (PIBDeflactor.ado)
global def2019 = 3.3					// def${anioVP}: debe estar definido (PIBDeflactor.ado)

global depreMXN = 0					// Debe estar defnido como porcentaje de depreciaci${o}n (SHRFSP.ado)




*******************/
*** 2. Statu Quo ***
/********************
capture log using "`c(sysdir_personal)'/users/log `c(current_date)'"
noisily di _newline(5) in g _dup(50) "+" in y "$simuladorCIEP: `c(current_date)' `c(current_time)'" in g _dup(50) "+"

noisily Eficiencia, anio($anioVP) graphs reboot noisily update //remake
noisily SHRFSP, graphs //update
TransfNetasGraphs

capture log close




**********************/
*** 3. Simulaciones ***
***********************
sysdir set PERSONAL `"/SIM/OUT/4/4.8 (Sim4 web)"'
local id "PE2018H"
capture mkdir "`c(sysdir_personal)'/users/`id'/"
capture log using "`c(sysdir_personal)'/users/`id'/log `c(current_date)'", replace
noisily di _newline(5) in g _dup(50) "+" in y "$simuladorCIEP: `c(current_date)' `c(current_time)'" in g _dup(50) "+"


** Ingresos **
* Al ingreso *
scalar sISR__as = 2.901					// ISR (asalariados)
scalar sISR__PF = 0.402					// ISR (personas f${i}sicas)
scalar sCuotasT = 1.345					// Cuotas (IMSS)

* Al consumo *
scalar sIVA     = 3.813					// IVA
scalar sIEPS    = (0.709 + 1.125)	// IEPS (no petrolero + petrolero)
scalar sISAN    = 0.046					// ISAN
scalar sImporta = 0.206					// Importaciones

* Al capital *
scalar sISR__PM = 3.508					// ISR (personas morales)
scalar sFMP_Der = 1.986					// Fondo Mexicano del Petr${o}leo
scalar sOYE     = (0.119 + 0.228 + 1.841 + 1.656)	// Organismos y empresas (IMSS + ISSSTE + Pemex + CFE)


** Gastos **
* Educaci${o}n *
scalar sbasica = 1.993					// Educaci${o}n b${a}sica
scalar smedias = 0.410					// Educaci${o}n media superior
scalar ssuperi = 0.521					// Educaci${o}n superior
scalar sposgra = 0.033					// Posgrado

* Pensiones *
scalar spam    = 0.172					// Pensi${o}n para adultos mayores
scalar spenims = 1.678					// Pensi${o}n IMSS
scalar speniss = 0.901					// Pensi${o}n ISSSTE
scalar spenpem = 0.278					// Pensi${o}n Pemex
scalar spencfe = 0.168					// Pensi${o}n CFE
scalar spenlfc = 0.426					// Pensi${o}n LFC, ISSFAM, Otros

* Salud *
scalar sssa    = 0.212					// SSalud
scalar ssegpop = 0.706					// Seguro Popular
scalar simss   = 1.205					// IMSS (salud)
scalar sissste = 0.239					// ISSSTE (salud)
scalar sprospe = 0.052					// IMSS-Prospera
scalar spemex  = 0.097					// Pemex (salud) (.095)

* Ingreso basico *
scalar singbas = 0.000					// Ingreso b${a}sico	
scalar pamgeneral = 0

* Reduccion del gasto *
scalar redgast = 0.000					// Reducci${o}n del gasto



********************
** 3.1 Resultados **
run "`c(sysdir_personal)'/Modulos.do" `id' $anioVP
noisily Eficiencia, id(`id') anio($anioVP) reboot graphs //update //noisily
noisily SHRFSP, id(`id') graphs
TransfNetasGraphs, id(`id')




*********************/
*** 4. Touch Down! ***
**********************
timer off 1
timer list 1
noisily di _newline in g _dup(55) "+" in y round(`=r(t1)/r(nt1)',.1) in g " segs." _dup(55) "+" _newline(5)
capture log close
exit, clear STATA
