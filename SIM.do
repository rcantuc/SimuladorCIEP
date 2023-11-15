***********************************
***                             ***
**#    SIMULADOR FISCAL CIEP    ***
***                             ***
***********************************
noisily run "`c(sysdir_personal)'/sysprofile.do"
noisily run "`c(sysdir_personal)'/profile.do"



** Opciones **
//global export "`c(sysdir_site)'../Ricardo Cantú/CESOP/documentoCIEP/images"	// DIRECTORIO DE IMÁGENES
global nographs "nographs"                                                    // SUPRIMIR GRAFICAS
//global textbook "textbook"                                                    // GRÁFICOS FORMATO LaTeX
//global output "output"                                                        // OUTPUTS (WEB)
//global update "update"                                                        // OUTPUTS (WEB)





***********************************
***                             ***
***    DIRECTORIO DE TRABAJO    ***
***                             ***
***********************************
* iMac Ricardo *
if "`c(username)'" == "ricardo" ///
	sysdir set PERSONAL "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"

* Servidor CIEP *
if "`c(username)'" == "ciepmx" & "`c(console)'" == "" ///
	sysdir set PERSONAL "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
adopath ++PERSONAL





******************************************************************
***                                                            ***
**#    1. MARCO MACRO: POBLACION + ECONOMÍA + SISTEMA FISCAL   ***
***                                                            ***
******************************************************************
noisily run "`c(sysdir_personal)'/parametros.do"


*******************
** 1.1 Población **
** Inputs: anio(s) de interés, entidad federativa
** Outputs: población por edad, sexo y entidad federativa
forvalues anio = `=anioPE'(1)`=anioPE' {                                        // <-- Año(s) de interés
*	foreach entidad of global entidadesL {                                  // <-- Nacional o por entidad
*		noisily Poblacion if entidad == "`entidad'", anio(`anio') //$update
*	}
}


******************
** 1.2 Economía **
noisily PIBDeflactor, geodef(2003) geopib(2003) $update
//noisily SCN, //update
//noisily Inflacion, //update


************************
** 1.3 Sistema fiscal **
noisily LIF, by(divPE) rows(1) min(0) //anio(`anio') //update desde(2018)
noisily PEF, by(divCIEP) rows(2) min(0) //anio(`anio') //update desde(2018)
noisily SHRFSP, ultanio(2008) //anio(2023) //update


***********************
** 1.4 Subnacionales **
//noisily run "`c(sysdir_personal)'/Subnacional.do" //update





**************************/
***                     ***
**#    3. HOUSEHOLDS    ***
***                     ***
***************************

** 3.1 Households information **
capture confirm file "`c(sysdir_personal)'/SIM/`=anioenigh'/households.dta"
if _rc != 0 {
	noisily run `"`c(sysdir_personal)'/Households.do"' `=anioPE'

	** 3.2 Sankey **
	foreach k in grupoedad sexo decil rural escol {
		run "`c(sysdir_personal)'/Sankey.do" `k' `=anioenigh'
	}
}


** 3.2 Perfiles del $paqueteEconomico **
if "$update" == "update" {
	noisily run `"`c(sysdir_personal)'/PerfilesSim.do"' `=anioPE' 
}





***********************/
***                  ***
**#    4. MÓDULOS    ***
***                  ***
************************
if "`cambioisr'" == "1" {
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


** 4.1 Integración de módulos (Households + LIF + PEF) ***
** Creación de scalars **
noisily TasasEfectivas, anio(`=anioPE') nog
noisily GastoPC, aniope(`=anioPE')




*****************************/
***                        ***
**#    5. CICLO DE VIDA    ***
***                        ***
******************************
capture use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
if _rc != 0 {
	use "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta", clear
}
keep ISRAS ISRPF CUOTAS ISRPM IVA IEPSNP IEPSP ISAN IMPORT OTROSK FMP ///
	Pension Educación Salud IngBasico Pensión_AM Otros_gastos Otras_inversiones Part_y_otras_Apor Energía ///
	folio* edad sexo factor decil escol formal ingbrutotot


** (+) Impuestos y aportaciones **
capture drop ImpuestosAportaciones
egen ImpuestosAportaciones = rsum(ISRAS ISRPF CUOTAS ISRPM IVA IEPSNP IEPSP ISAN IMPORT) //OTROSK
label var ImpuestosAportaciones "impuestos y aportaciones"

** (-) Impuestos y aportaciones **
capture drop Transferencias
egen Transferencias = rsum(Pension Educación Salud IngBasico Pensión_AM) //Inversión
label var Transferencias "transferencias públicas"

** (=) Aportaciones netas **
capture drop AportacionesNetas
g AportacionesNetas = ImpuestosAportaciones - Transferencias
label var AportacionesNetas "aportaciones netas"
noisily Simulador AportacionesNetas [fw=factor], base("ENIGH `=anioenigh'") reboot anio(`=anioPE') $nographs //boot(20)
//noisily Gini AportacionesNetas, hogar(folioviv foliohog) factor(factor)
save "`c(sysdir_personal)'/users/$id/households.dta", replace


** (*) CUENTA GENERACIONAL **
*noisily CuentasGeneracionales AportacionesNetas, anio(`=anioPE') discount(7)


** (*) Sankey **
foreach k in /*grupoedad*/ decil /*sexo rural escol*/ {
	noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `=aniovp'
}





********************************************/
***                                       ***
**#    6. PARTE IV: DEUDA + FISCAL GAP    ***
***                                       ***
*********************************************
noisily FiscalGap, anio(`=anioPE') end(2030) aniomin(2015) $nographs desde(2015) discount(7) //update   //anio(`=aniovp')





***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
*noisily scalarlatex, logname(tasasEfectivas)
*run "`c(sysdir_personal)'/output.do"
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
