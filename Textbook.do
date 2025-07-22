****
**** SIMULADOR FISCAL CIEP (9 de mayo de 2025)
**** Descripción: Genera las gráficas y tablas del libro de texto CIEP
**** Autor: Ricardo Cantú Calderón
**** Email: ricardocantu@ciep.mx
****



***
**# 0. SET UP
***
clear all
macro drop _all
capture log close _all
timer on 1

** Directorios de trabajo (uno por computadora)
if "`c(username)'" == "ricardo" {						// iMac Ricardo
	sysdir set SITE "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/"
	global export "/Users/ricardo/CIEP Dropbox/TextbookCIEP/images"
}
else if "`c(username)'" == "servidorciep" {					// Servidor CIEP
	sysdir set SITE "/home/servidorciep/CIEP Dropbox/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/"
	global export "/home/servidorciep/CIEP Dropbox/TextbookCIEP/images"
}
else if "`c(username)'" == "gabriel" {
	sysdir set SITE "/home/servidorciep/CIEP Dropbox/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/"
	global export "/home/servidorciep/CIEP Dropbox/TextbookCIEP/images"
}
else if "`c(console)'" != "" {							// Servidor Web
	sysdir set SITE "/SIM/OUT/7/"
}
cd "`c(sysdir_site)'"

** Parámetros iniciales
scalar aniovp = 2025								// ANIO VALOR PRESENTE
scalar anioPE = 2025								// ANIO PAQUETE ECONÓMICO
scalar anioenigh = 2022								// ANIO ENIGH
global id = "ciepmx"								// ID USUARIO
global paqueteEconomico "CGPE 2025"						// POLÍTICA FISCAL

** Opciones
//global nographs "nographs"							// SUPRIMIR GRAFICAS
//global update "update"							// UPDATE BASES DE DATOS
global textbook "textbook"							// SCALAR TO LATEX



***
**# 1. CAPTÍULO 2
***
/** 1.1 Producto Interno Bruto (inputs opcionales)
global pib2025 = 1.5								// CRECIMIENTO ANUAL PIB
global pib2026 = 2.1								// <-- AGREGAR O QUITAR AÑOS
global pib2027 = 2.5
global pib2028 = 2.5
global pib2029 = 2.5
global pib2030 = 2.5

** 1.2 Deflactor (inputs opcionales)
global def2025 = 4.4								// CRECIMIENTO ANUAL PRECIOS IMPLÍCITOS
global def2026 = 4.0								// <-- AGREGAR O QUITAR AÑOS
global def2027 = 3.5
global def2028 = 3.5
global def2029 = 3.5
global def2030 = 3.5

** 1.3 Inflación (inputs opcionales)
global inf2025 = 3.5								// CRECIMIENTO ANUAL INFLACIÓN
global inf2026 = 3.0								// <-- AGREGAR O QUITAR AÑOS
global inf2027 = 3.0
global inf2028 = 3.0
global inf2029 = 3.0
global inf2030 = 3.0

noisily PIBDeflactor, aniovp(`=aniovp') geodef(1993) geopib(1993) aniomax(2030) $update $textbook

** 1.4 Sistema de Cuentas Nacionales (sin inputs)
noisily SCN, anio(`=aniovp') $update $textbook



**
**# 2. CAPTÍULO 3
***
noisily Poblacion, anioi(`=anioPE') aniofinal(`=`=anioPE'+25') $textbook

** 2.1 Encuesta Nacional de Ingresos y Gastos de los Hogares (Usos)
noisily run "`c(sysdir_site)'/Expenditure.do" `=anioenigh'

** 2.2 Encuesta Nacional de Ingresos y Gastos de los Hogares (Recursos)
noisily run `"`c(sysdir_site)'/Households.do"' `=anioenigh'





**/
**# 3. CAPÍTULO 12: Redistribución
***
use `"`c(sysdir_site)'/users/$id/ingresos.dta"', clear
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/gastos.dta", nogen
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/isr_mod.dta", ///
	nogen replace update keepus(ISRAS_Sim ISRPF_Sim ISRPM_Sim CUOTAS_Sim)
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/iva_mod.dta", ///
	nogen replace update keepus(IVA_Sim)
save `"`c(sysdir_site)'/users/$id/aportaciones.dta"', replace
capture drop ImpuestosAportaciones


** 6.1 (+) Impuestos y aportaciones
egen AlTrabajo = rsum(ISRPF_Sim ISRAS_Sim CUOTAS_Sim)
label var AlTrabajo "Impuestos al trabajo"

egen AlCapital = rsum(ISRPM_Sim OTROSK)
label var AlCapital "Impuestos al capital"

egen AlConsumo = rsum(IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim)
label var AlConsumo "Impuestos al consumo"

egen ImpuestosAportaciones = rsum(ISRPM_Sim ISRAS_Sim ISRPF_Sim CUOTAS_Sim IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim) // FMP_Sim OTROSK_Sim
label var ImpuestosAportaciones "Impuestos y contribuciones"


** 6.2 (-) Gastos
label var Pensión_AM "Pensión para adultos mayores"
label var Educación "Educación"

capture drop Transferencias
egen Transferencias = rsum(Pensiones Pensión_AM IngBasico Educación Salud) // Otras_inversiones
label var Transferencias "Transferencias públicas"


** 6.3 (=) Aportaciones netas **
capture drop AportacionesNetas
g AportacionesNetas = ImpuestosAportaciones - Transferencias
label var AportacionesNetas "Ciclo de vida de las aportaciones netas"


** 6.4 Perfiles **
foreach k of varlist AlTrabajo AlCapital AlConsumo ///
	Pensiones Pensión_AM IngBasico Educación Salud ///
	AportacionesNetas {
	rename `k' `=subinstr("`k'","_","",.)'
	noisily Simulador `=subinstr("`k'","_","",.)' [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)
}


** 6.4 (*) Cuentas generacionales
*noisily CuentasGeneracionales AportacionesNetas, anio(`=anioPE') discount(7)



if "$textbook" == "textbook" {
	noisily scalarlatex, log(aportaciones) alt(Apor)
}

