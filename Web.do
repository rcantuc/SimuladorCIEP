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

**  0.1 Rutas de archivos  **
if "`c(username)'" == "ricardo" ///                                 // iMac Ricardo
	sysdir set PERSONAL "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
else if "`c(username)'" == "ciepmx" & "`c(console)'" == "" ///      // Servidor CIEP
	sysdir set PERSONAL "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
else if "`c(console)'" != "" ///      // Web
	sysdir set PERSONAL "/SIM/OUT/6/"
cd "`c(sysdir_personal)'"

run "`c(sysdir_personal)'profile.do"
scalar anioPE = 2024
scalar aniovp = 2024
scalar anioenigh = 2022
global paqueteEconomico "Pre-CGPE 2025"

**  0.2 Opciones globales  **
global id = "ciepmx"                                                // IDENTIFICADOR DEL USUARIO
//global nographs "nographs"                                        // SUPRIMIR GRAFICAS
global output "output"                                            // ARCHIVO DE SALIDA (WEB)
//global update "update"                                            // UPDATE BASES DE DATOS


** 0.3 Archivos output **
if "$output" != "" {
	quietly log using `"`c(sysdir_personal)'/users/$id/output.txt"', replace text name(output)
	quietly log off output
}



***************************
***                     ***
**#    1. MARCO MACRO   ***
***                     ***
***************************

** 1.1 Proyecciones demográficas **
//forvalues anio = 1950(1)`=anioPE' {                         // <-- Año(s) de interés
	//foreach entidad of global entidadesL {                  // <-- Nacional o para todas las entidades
		//noisily Poblacion if entidad == "`entidad'", //anioi(2008) aniofinal(2050) $update
	//}
//}

//noisily PIBDeflactor, geodef(2005) geopib(2005) $update aniovp(`=aniovp')

** 1.3 Sistema de Cuentas Nacionales **
//noisily SCN, //$update

** 1.4 Ley de Ingresos de la Federación **
//noisily LIF, by(divCIEP) rows(2) anio(`=anioPE') $update desde(2019) min(1) title("Ingresos presupuestarios")

** 1.5 Presupuesto de Egresos de la Federación **
//noisily PEF, by(divSIM) rows(2) min(0) anio(`=anioPE') desde(2019) title("Gasto presupuestario") $update

** 1.6 Saldo Histórico de los Requerimientos Financieros del Sector Público **
//noisily SHRFSP, anio(`=anioPE') $update

** 1.7 Subnacionales **
//noisily run "Subnacional.do" //$update

** 1.8 Perfiles **
forvalues anio = `=anioPE'(2)`=anioPE' {
	capture confirm file "`c(sysdir_personal)'/SIM/perfiles`anio'.dta"
	if _rc != 0 ///
		noisily run "`c(sysdir_personal)'/PerfilesSim.do" `anio'
}



*********************************/
***                            ***
**#    2. MÓDULOS SIMULADOR    ***
***                            ***
**********************************
noisily TasasEfectivas, anio(`=anioPE')
noisily GastoPC, aniope(`=anioPE') aniovp(`=aniovp')



*****************************/
***                        ***
**#    3. CICLO DE VIDA    ***
***                        ***
******************************
use `"`c(sysdir_personal)'/users/$id/ingresos.dta"', clear
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/users/$id/gastos.dta", nogen
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/users/$id/isr_mod.dta", nogen replace update keepus(ISRAS ISRPF ISRPM CUOTAS)
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/users/$id/iva_mod.dta", nogen replace update keepus(IVA)


**************************************
** 3.1 (+) Impuestos y aportaciones **
capture drop ImpuestosAportaciones
egen ImpuestosAportaciones = rsum(ISRPM OTROSK FMP ISRAS ISRPF CUOTAS IVA IEPSNP IEPSP ISAN IMPORT)
label var ImpuestosAportaciones "impuestos y aportaciones"


**************************************
** 3.2 (-) Impuestos y aportaciones **
capture drop Transferencias
egen Transferencias = rsum(Educación Pensiones Salud IngBasico Pensión_AM Otras_inversiones)
label var Transferencias "transferencias públicas"


********************************
** 3.3 (=) Aportaciones netas **
capture drop AportacionesNetas
g AportacionesNetas = ImpuestosAportaciones - Transferencias
label var AportacionesNetas "Aportaciones netas"
noisily Perfiles AportacionesNetas [fw=factor], aniovp(2024) aniope(`=anioPE') $nographs //boot(10)


************************************
** 3.4 (*) Cuentas generacionales **
//noisily CuentasGeneracionales AportacionesNetas, anio(`=anioPE') discount(7)


***************************************
** 3.5 (*) Sankey del sistema fiscal **
foreach k in decil grupoedad /*sexo rural escol*/ {
	noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `=anioPE'
}



********************************************/
***                                       ***
**#    4. PARTE IV: DEUDA + FISCAL GAP    ***
***                                       ***
*********************************************
noisily FiscalGap, anio(`=anioPE') end(2030) aniomin(2014) $nographs desde(2018) //discount(10) //update //anio(`=aniovp')



***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
if "$output" == "output" {
	run "output.do"
}
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
