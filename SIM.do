***********************************
***                             ***
**#    SIMULADOR FISCAL CIEP    ***
***        ver: SIM.md          ***
***                             ***
***********************************
clear all
macro drop _all
capture log close _all
timer on 1

*************************
** 0.1 Rutas al Github **
if "`c(username)'" == "ricardo" {						// iMac Ricardo
	sysdir set PERSONAL "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
	*global export "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/CIEP_Deuda/0. Paquete Económico/2025"
	*global export "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/Paquete Económico 2025/4. Documento CIEP/images"
	*global export "/Users/ricardo/CIEP Dropbox/TextbookCIEP/images"
}
else if "`c(username)'" == "servidorciep" {					// Servidor CIEP
	sysdir set PERSONAL "/home/servidorciep/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
	*global export "/home/servidorciep/CIEP Dropbox/Ricardo Cantú/Paquete Económico 2025/4. Documento CIEP/images"
}
else if "`c(console)'" != "" {							// Servidor Web
	sysdir set PERSONAL "/SIM/OUT/6/"
}
cd "`c(sysdir_personal)'"

****************************
** 0.2 Opciones globales  **
//global nographs "nographs"							// SUPRIMIR GRAFICAS
//global output "output"							// ARCHIVO DE SALIDA (WEB)
global update "update"							// UPDATE BASES DE DATOS

******************************
** 0.3 Parámetros iniciales **
noisily run "`c(sysdir_personal)'/profile.do"
global id = "ciepmx"								// IDENTIFICADOR DEL USUARIO



***************************
***                     ***
**# 1. SISTEMA FISCAL   ***
***                     ***
***************************

** 1.1 Proyecciones demográficas **
//forvalues anio = 1950(1)`=anioPE' {						// <-- Año(s) de interés
	//foreach entidad of global entidadesL {				// <-- Nacional o entidad
		//noisily Poblacion if entidad == "`entidad'", anioi(2024) aniofinal(2030) //$update
		//noisily Poblacion if entidad == "`entidad'", anioi(2024) aniofinal(2034)
	//}
//}

** 1.2 Producto Interno Bruto y su deflactor **
//noisily PIBDeflactor if anio <= 2030, geodef(1993) geopib(1993) aniovp(`=aniovp') $update

** 1.3 Sistema de Cuentas Nacionales **
//noisily SCN, //$update

** 1.4 Ley de Ingresos de la Federación **
//noisily LIF, by(divPE) rows(1) anio(`=anioPE-1') desde(2013) min(0) title("Ingresos presupuestarios") $update

** 1.5 Presupuesto de Egresos de la Federación **
//noisily PEF, by(divSIM) rows(2) min(0) anio(`=anioPE') desde(2024) title("Gasto presupuestario") $update

** 1.6 Saldo Histórico de Requerimientos Financieros del Sector Público **
set scheme ciepdeuda
noisily SHRFSP, anio(`=anioPE-1') ultanio(2012) $update
ex
** 1.7 Subnacionales **
//noisily run "Subnacional.do" //$update

/** 1.8 Perfiles **
forvalues anio = `=anioPE-12'(1)`=anioPE-1' {
	noisily di in y "PerfilesSim `anio'"
	capture confirm file "`c(sysdir_personal)'/SIM/perfiles`anio'.dta"
	if _rc != 0 | "$update" == "update" ///
		noisily run "`c(sysdir_personal)'/PerfilesSim.do" `anio'
}



*********************************/
***                            ***
**#    2. MÓDULOS SIMULADOR    ***
***                            ***
**********************************
if "`cambioisrpf'" == "1" {
	noisily run "`c(sysdir_personal)'/ISR_Mod.do"
	scalar ISRAS  = ISR_AS_Mod
	scalar ISRPF  = ISR_PF_Mod
	scalar ISRPM  = ISR_PM_Mod
	scalar CUOTAS = CUOTAS_Mod
}
if "`cambioiva'" == "1" {
	noisily run "`c(sysdir_personal)'/IVA_Mod.do"
	scalar IVA = IVA_Mod
}

** Integración de módulos ***
*noisily TasasEfectivas, anio(`=anioPE')
*noisily GastoPC, aniope(`=anioPE') aniovp(`=aniovp')

ex

*****************************/
***                        ***
**#    3. CICLO DE VIDA    ***
***                        ***
******************************
use `"`c(sysdir_personal)'/users/$id/ingresos.dta"', clear
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/users/$id/gastos.dta", nogen
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/users/$id/isr_mod.dta", ///
	nogen replace update keepus(ISRAS ISRPF ISRPM CUOTAS)
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/users/$id/iva_mod.dta", ///
	nogen replace update keepus(IVA)

** 3.1 (+) Impuestos y aportaciones **
capture drop ImpuestosAportaciones
egen ImpuestosAportaciones = rsum(ISRPM OTROSK FMP ISRAS ISRPF CUOTAS IVA IEPSNP IEPSP ISAN IMPORT)
label var ImpuestosAportaciones "Impuestos, cuotas y otras contribuciones"
*noisily Perfiles ImpuestosAportaciones [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)

** 3.2 (-) Impuestos y aportaciones **
capture drop Transferencias
egen Transferencias = rsum(Pensiones Pensión_AM Otras_inversiones IngBasico Educación Salud)
label var Transferencias "Transferencias públicas"
*noisily Perfiles Transferencias [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)

** 3.3 (=) Aportaciones netas **
capture drop AportacionesNetas
g AportacionesNetas = ImpuestosAportaciones - Transferencias
label var AportacionesNetas "Aportaciones netas"
noisily Perfiles AportacionesNetas [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)

** 3.4 (*) Cuentas generacionales **
//noisily CuentasGeneracionales AportacionesNetas, anio(`=anioPE') discount(7)



********************************************/
***                                       ***
**#    4. PARTE IV: DEUDA + FISCAL GAP    ***
***                                       ***
*********************************************
noisily FiscalGap, anio(`=anioPE') end(2030) aniomin(2013) $nographs desde(2013) discount(10) //update

** 4.1 (*) Sankey del sistema fiscal **
foreach k in decil grupoedad /*sexo rural escol*/ {
	noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `=anioPE'
}



***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
if "$output" == "output" {
	run "`c(sysdir_personal)'/output.do"
}
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
