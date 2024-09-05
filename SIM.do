***********************************
***                             ***
**#    SIMULADOR FISCAL CIEP    ***
***        ver: SIM.md          ***
***                             ***
***********************************
run "`c(sysdir_personal)'profile.do"

**  0.1 Rutas al Github **
if "`c(username)'" == "ricardo" /// iMac Ricardo
	sysdir set PERSONAL "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
else if "`c(username)'" == "ciepmx" & "`c(console)'" == "" /// Servidor CIEP
	sysdir set PERSONAL "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
else if "`c(console)'" != "" /// Servidor Web
	sysdir set PERSONAL "/SIM/OUT/6/"
cd "`c(sysdir_personal)'"

**  0.2 Opciones globales  **
global id = "ciepmx"			// IDENTIFICADOR DEL USUARIO
//global nographs "nographs"		// SUPRIMIR GRAFICAS
global output "output"			// ARCHIVO DE SALIDA (WEB)
//global update "update"		// UPDATE BASES DE DATOS
//global export "`c(sysdir_personal)'../../+EquipoCIEP/Boletines/Consolidación fiscal/images" // IMÁGENES A EXPORTAR

** 0.3 Archivos output **
if "$output" != "" {
	quietly log using `"`c(sysdir_personal)'/users/$id/output.txt"', replace text name(output)
	quietly log off output
}



***************************
***                     ***
**#    1. MARCO MACRO   ***
***                     ***
/***************************

** 1.1 Proyecciones demográficas **
//forvalues anio = 1950(1)`=anioPE' {                         // <-- Año(s) de interés
	//foreach entidad of global entidadesL {                  // <-- Nacional o para todas las entidades
		//noisily Poblacion if entidad == "`entidad'", anioi(1990) aniofinal(2040) //$update
	//}
//}

** 1.2 Producto Interno Bruto y su deflactor **
//noisily PIBDeflactor, geodef(1993) geopib(1993) $update aniovp(`=aniovp')

** 1.3 Sistema de Cuentas Nacionales **
//noisily SCN, //$update

** 1.4 Ley de Ingresos de la Federación **
//noisily LIF, by(divCIEP) rows(2) anio(`=anioPE') $update desde(2008) min(1) title("Ingresos presupuestarios")

** 1.5 Presupuesto de Egresos de la Federación **
//noisily PEF, by(divSIM) rows(2) min(0) anio(`=anioPE') desde(2013) title("Gasto presupuestario") //$update
noisily SHRFSP, anio(`=anioPE') ultanio(2008) $update

** 1.7 Subnacionales **
//noisily run "Subnacional.do" //$update

** 1.8 Perfiles **
forvalues anio = `=anioPE'(2)`=anioPE' {
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
noisily TasasEfectivas, anio(`=anioPE')
noisily GastoPC, aniope(`=anioPE') aniovp(`=aniovp')



*****************************/
***                        ***
**#    3. CICLO DE VIDA    ***
***                        ***
/******************************
use `"`c(sysdir_personal)'/users/$id/ingresos.dta"', clear
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/users/$id/gastos.dta", nogen
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/users/$id/isr_mod.dta", nogen replace update keepus(ISRAS ISRPF ISRPM CUOTAS)
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/users/$id/iva_mod.dta", nogen replace update keepus(IVA)

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

** 3.5 (*) Sankey del sistema fiscal **
foreach k in decil grupoedad /*sexo rural escol*/ {
	noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `=anioPE'
}




********************************************/
***                                       ***
**#    4. PARTE IV: DEUDA + FISCAL GAP    ***
***                                       ***
*********************************************
noisily FiscalGap, anio(`=anioPE') end(2030) aniomin(2014) $nographs desde(2014) //discount(10) //update //anio(`=aniovp')



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
