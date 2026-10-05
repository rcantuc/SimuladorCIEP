*! nl-vintage.do  v0.1.0 (NL-0.5.0, F0) — corrida del motor sobre UNA ENIGH bienal con calibración contemporánea + EntidadNL
*
* QUÉ ES ESTO (DIAGNOSTICO_NL.md, anexo Participaciones históricas F0)
*   El lado "paga" de FederacionNL usa Part<X>nl de UNA corrida (ENIGH 2024, PE 2027).
*   Para estimar participaciones con cada ENIGH bienal, el motor debe correrse con
*   anioPE = aniovp = anioenigh = <vintage>, de modo que:
*     - Households.do/Expenditure.do armonizan la ENIGH <vintage> a SCN/LIF/PEF del
*       MISMO año (tarifa ISR, UDIS, UMA y cut-offs probit del vintage; cachés
*       master/<vintage>/ households, expenditures, consumption_categ_*);
*     - PerfilesSim.do reescala a LIF/PEF/SCN observados del vintage (perfiles<vintage>.dta);
*     - TasasEfectivas.ado, SIN los escalares *PIB de SIM.do §4.1, toma por default lo
*       OBSERVADO en LIF <vintage> (TasasEfectivas.ado §2); GastoPC, SIN los escalares
*       de SIM.do §5.1, toma el PEF <vintage> (GastoPC.ado, capture confirm scalar).
*   Es decir: SIM.do §0–§4.7, §5 (PEF + GastoPC) y §7, OMITIENDO deliberadamente los
*   bloques de parámetros del Paquete Económico (§4.1, §5.1) y los módulos que no
*   alimentan la incidencia (§6 SHRFSP, §8 FiscalGap/Sankey). Después corre
*   EntidadNL.do en la misma sesión (compuerta D.1 incluida).
*
* MOTOR INTACTO: este driver vive en la capa NL; no modifica ningún .ado ni SIM.do.
* AISLAMIENTO: $id = <usuario>-v<vintage>  ->  users/<usuario>-v<vintage>/ (ingresos,
*   gastos, aportaciones, bootstraps, nodos/statajson_entidad-nl.json). Los productos
*   de producción (users/<usuario>/) y perfiles<anioPE>.dta del Paquete no se tocan.
*   Las cachés master/<vintage>/ y master/perfiles<vintage>.dta se construyen si faltan
*   (mismo mecanismo del motor) y se reutilizan después.
*
* USO (batch desde la raíz del worktree):
*   do "01_modulos/nl-assets/nl-vintage.do" 2016      (2016 | 2018 | 2020 | 2022 | 2024)
* OJO: destruye los datos en memoria y los escalares/matrices de la sesión (clear all).

version 17
clear all
set more off
if "`1'" == "" {
	di as err "nl-vintage: indica el vintage ENIGH (2016 2018 2020 2022 2024)."
	exit 198
}
scalar nlv_anio = real("`1'")
if !inlist(scalar(nlv_anio), 2016, 2018, 2020, 2022, 2024) {
	di as err "nl-vintage: vintage `1' fuera de la serie 2016–2024 (la ENIGH 2014 queda fuera por el cambio de diseño 2016)."
	exit 198
}
macro drop _all
set scheme ciep
timer clear 1
timer on 1

*** 0 SET UP (espejo de SIM.do §0, con el vintage como año de política y de valor presente) ***
SIMroot
adopath ++ `"${SIMROOT}"'									// Expenditure.do hace cd a raw/ENIGH/: sin esto "." deja de ver los .ado del motor (ensure_asset)
local anio = scalar(nlv_anio)
capture confirm file "${SIMROOT}/set_token.do"
if _rc == 0 run "${SIMROOT}/set_token.do"

global id = "`c(username)'-v`anio'"
scalar aniovp = `anio'									// ANIO VALOR PRESENTE  = vintage
scalar anioPE = `anio'									// ANIO PAQUETE ECONÓMICO = vintage (calibración contemporánea)
scalar anioenigh = `anio'								// ANIO ENIGH = vintage
capture mkdir "${SIMROOT}/users/"
capture mkdir "${SIMROOT}/users/$id"
capture mkdir "${SIMROOT}/users/$id/nodos"
global nographs "nographs"
global bootstrap 1

* Log de procedencia propio (EntidadNL exige un log activo) *
capture log close nlvint
quietly log using "${SIMROOT}/users/$id/nodos/nl-vintage.log", replace text name(nlvint)
noisily di _newline in g _dup(20) "." "{bf:   nl-vintage: ENIGH " in y `anio' in g " — anioPE = aniovp = anioenigh = " in y `anio' in g "   }" _dup(20) "."
noisily di in g "  usuario de la corrida: " in y "$id" in g " · SIMROOT: " in y "${SIMROOT}"

*** 1 DEMOGRAFÍA ***
noisily Poblacion, anioi(`=aniovp') aniofinal(2070) $nographs

*** 2 ECONOMÍA (mismos supuestos de proyección que SIM.do; solo afectan años > último observado) ***
global paqueteEconomico "Observado `anio' (calibración contemporánea)"
global pib2026 = 1.4127
global pib2027 = 1.9983
global pib2028 = 2.0000
global pib2029 = 2.0000
global pib2030 = 2.0000
global pib2031 = 2.0000
global pib2032 = 2.0000
global def2026 = 3.8
global def2027 = 4.0
global def2028 = 4.0
global def2029 = 4.0
global def2030 = 4.0
global def2031 = 4.0
global def2032 = 4.0
global inf2026 = 3.8
global inf2027 = 3.2
global inf2028 = 3.0
global inf2029 = 3.0
global inf2030 = 3.0
global inf2031 = 3.0
global inf2032 = 3.0
noisily PIBDeflactor, aniovp(`=aniovp') aniomax(2032) $nographs
noisily SCN, anio(`=aniovp') $nographs

*** 3 HOGARES: ARMONIZACIÓN MACRO-MICRO (cachés master/<vintage>/ y perfiles<vintage>.dta) ***
noisily di _newline in g "Actualizando: " in y "expenditures.dta (ENIGH `anio')"
noisily run "${SIMROOT}/01_modulos/Expenditure.do" `=anioPE'
noisily di _newline in g "Actualizando: " in y "households.dta (ENIGH `anio')"
noisily run `"${SIMROOT}/01_modulos/Households.do"' `=anioPE'
noisily di _newline in g "Actualizando: " in y "perfiles`anio'.dta"
noisily run "${SIMROOT}/01_modulos/PerfilesSim.do" `=anioPE'

*** 4 SISTEMA FISCAL: INGRESOS ***
set scheme ingresos
noisily LIF if divLIF != 10, anio(`=anioPE') by(divCIEP) $nographs ///
	title("Ingresos presupuestarios") desde(2016) min(0.75) rows(2)

* §4.1 de SIM.do OMITIDO A PROPÓSITO: sin escalares <X>PIB, TasasEfectivas.ado §2 toma
* lo observado en LIF `anio' y lo declara como parámetro (calibración contemporánea). *
foreach k in ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA ISAN IEPSNP IEPSP IMPORT {
	capture confirm scalar `k'PIB
	if _rc == 0 {
		di as err "nl-vintage: el escalar `k'PIB ya existe en la sesión; la calibración dejaría de ser contemporánea."
		exit 459
	}
}

* §4.2 (tarifa ISR/SE/DED) e §4.6 (IEPST) NO se declaran: Households.do y Expenditure.do
* definen las suyas por vintage y ISR_Mod/IVA_Mod no se corren. §4.3 PM y §4.5 IVAT sí:
* EntidadNL.do los lee (S3 del ISR PM; regímenes de la canasta del decil I). *
matrix PM = (30,			66.53)
matrix IVAT = (16 \     ///  1  Tasa general
	1  \     							///  2  Alimentos, 1: Tasa Cero, 2: Exento, 3: Gravado
	2  \     							///  3  Alquiler, idem
	1  \     							///  4  Canasta basica, idem
	2  \    							///  5  Educacion, idem
	3  \     							///  6  Consumo fuera del hogar, idem
	3  \     							///  7  Mascotas, idem
	1  \     							///  8  Medicinas, idem
	1  \     							///  9  Toallas sanitarias, idem
	3  \     							/// 10  Otros, idem
	2  \     							/// 11  Transporte local, idem
	3  \     							/// 12  Transporte foraneo, idem
	23.0)   							//  13  Evasion e informalidad IVA, input[0-100]

noisily TasasEfectivas, anio(`=anioPE') enigh

*** 5 SISTEMA FISCAL: EGRESOS (§5.1 de SIM.do OMITIDO: GastoPC toma el PEF `anio') ***
set scheme ciep
noisily PEF, anio(`=anioPE') by(divSIM) title(" ") desde(2016) min(0) rows(2)
scalar ingbasico18 = 1
scalar ingbasico65 = 1
noisily GastoPC educacion salud pensiones energia resto transferencias, aniope(`=anioPE') aniovp(`=aniovp')

*** 7 CICLO DE VIDA FISCAL (espejo exacto de SIM.do §7) ***
use `"${SIMROOT}/users/$id/ingresos.dta"', clear
merge 1:1 (folioviv foliohog numren) using "${SIMROOT}/users/$id/gastos.dta", nogen

egen AlTrabajo = rsum(ISRPF_Sim ISRAS_Sim CUOTAS_Sim)
egen AlCapital = rsum(ISRPM_Sim OTROSK_Sim)
egen AlConsumo = rsum(IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim)
capture drop ImpuestosAportaciones
egen ImpuestosAportaciones = rsum(ISRPM_Sim ISRAS_Sim ISRPF_Sim CUOTAS_Sim IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim)
replace Pensiones = Pensiones + Pensión_AM
capture drop Transferencias
egen Transferencias = rsum(Pensiones IngBasico Educacion Salud OtrasInversiones)
capture drop AportacionesNetas
g AportacionesNetas = ImpuestosAportaciones - Transferencias
label var AlTrabajo "Impuestos al trabajo"
label var AlCapital "Impuestos al capital"
label var AlConsumo "Impuestos al consumo"
label var ImpuestosAportaciones "Impuestos y contribuciones"
label var Pensiones "Pensiones contributivas"
label var IngBasico "Transferencias"
label var Educacion "Educación"
label var Salud "Salud"
label var OtrosGastos "Otros gastos"
label var Transferencias "Transferencias públicas"
label var AportacionesNetas "Ciclo de vida de las aportaciones netas"
foreach k of varlist AportacionesNetas {
	noisily Simulador `k' if `k' != 0 [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot title("") bootstrap($bootstrap)
}
save `"${SIMROOT}/users/$id/aportaciones.dta"', replace

*** 8 CAPA NL: TE micro, incidencia, banda ISR PM y participaciones (compuerta D.1 dentro) ***
do "${SIMROOT}/01_modulos/EntidadNL.do"

timer off 1
quietly timer list 1
noisily di _newline in g "nl-vintage ENIGH `anio': " in y "LISTO" in g " en " in y round(r(t1), 1) in g " s · JSON: " in y "${SIMROOT}/users/$id/nodos/statajson_entidad-nl.json"
quietly log close nlvint
