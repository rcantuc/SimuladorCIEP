*! vintage-aportaciones.do  v1.0 (v8.14, DoD 1) — users/<usuario>-v<t>/aportaciones.dta: la base de un vintage ENIGH para la banda
*
* QUÉ ES. La banda de vintages de los Sankeys de entidad (SankeySF.do, P4) lee, para t en 2016 2018 2020 2022 2024,
*   users/$id-v<t>/aportaciones.dta: el aportaciones.dta de una corrida del motor con la ENIGH <t> y calibración
*   CONTEMPORÁNEA (anioPE = aniovp = anioenigh = t). Hasta v8.13 esas cinco bases se produjeron con el driver de la
*   capa NL (nl-vintage.do, 2026-10-08) y se clonaban a mano desde SimuladorCIEP-NL (FLAG #26); esta es la receta
*   ejecutable, dentro del repo, con el motor actual. La corre test-maquina-virgen.sh --download --vintages.
*
* QUÉ HACE (espejo de SIM.do §0–§5 y §7 con el vintage como año de política y de valor presente):
*   §1 Poblacion; §2 PIBDeflactor + SCN (mismos supuestos de proyección que SIM.do: solo tocan años > último observado);
*   §3 Expenditure.do, Households.do, PerfilesSim.do con la ENIGH <t> (cachés master/<t>/ y master/perfiles<t>.dta se
*   construyen si faltan y se reutilizan); §4 LIF y TasasEfectivas SIN los escalares <X>PIB de SIM.do §4.1 (TasasEfectivas
*   toma lo observado en LIF <t> y lo declara); §5 PEF y GastoPC SIN los escalares de SIM.do §5.1 (GastoPC toma el PEF <t>;
*   sin cache: no se corre Precache); §7 el ciclo de vida exacto de SIM.do (AlTrabajo, AlCapital, AlConsumo,
*   ImpuestosAportaciones, Transferencias, AportacionesNetas; Simulador ... if != 0, bootstrap(1)) → aportaciones.dta.
*   LÍMITE HEREDADO (igual que las bases del 8-oct, reporte F1): sin los escalares de SIM.do §5.1, GastoPC deja Salud y
*   Pensiones en cero en gastos.dta, así que la banda del lado gasto solo cubre Educación, Transferencias e Inversión.
*   Medido (2026-10-30, StataNow 19.5 SE, 1 procesador): 28–32 min por vintage sin cachés master/<t>/, 16 min con ellas.
*   OMITE a propósito: §3.2b NTA.do (solo 2024), §4.2–4.6 (matrices de la web: Households.do y Expenditure.do definen las
*   suyas por vintage), §4.7 TasasEfectivasEntidad, §5.1b Precache, §6 SHRFSP y §8 (FiscalGap, Sankeys).
*   MOTOR INTACTO: no toca SIM.do ni ningún .ado. AISLAMIENTO: $id = <usuario>-v<t>; users/<usuario>/ no se toca.
*
* USO (lo arma test-maquina-virgen.sh; a mano, en batch, con la raíz en el SITE de Stata como hace Web.Stata.do):
*   sysdir set SITE "<raíz con master/ y raw/ (o con red para ensure_asset)>/"
*   do "<raíz>/05_scripts/vintage-aportaciones.do" 2016        (2016 | 2018 | 2020 | 2022 | 2024)
* Al terminar imprime VINTAGE_OK <t> tras confirmar las variables que lee la banda. OJO: destruye los datos en memoria.

version 17
if "`1'" == "" {
	di as err "vintage-aportaciones: indica el vintage ENIGH (2016 2018 2020 2022 2024)."
	exit 198
}
if !inlist(real("`1'"), 2016, 2018, 2020, 2022, 2024) {
	di as err "vintage-aportaciones: vintage `1' fuera de la serie 2016–2024 (la ENIGH 2014 queda fuera por el cambio de diseño 2016)."
	exit 198
}
* La raíz viaja en el SITE de Stata (como en Web.Stata.do): macro drop _all borra también los locales
* (el argumento `1' y cualquier copia de SIMROOT), y clear all borra escalares y Mata; c(sysdir_site) sobrevive.
if substr("`c(sysdir_site)'", 1, 1) != "/" | !inlist(substr("`c(sysdir_site)'", 1, 5), "/User", "/SIM/", "/home", "/Volu", "/opt/", "/srv/", "/var/") {
	di as err "vintage-aportaciones: pon la raíz en el SITE antes de llamarme: sysdir set SITE \"<raíz>/\" (lo hace test-maquina-virgen.sh)."
	exit 198
}
clear all
scalar vint_anio = real("`1'")		// sobrevive a macro drop _all (clear all ya pasó)
macro drop _all					// como SIM.do
global SIMROOT = substr("`c(sysdir_site)'", 1, length("`c(sysdir_site)'") - 1)	// sin diagonal final
local anio = scalar(vint_anio)
adopath ++ "${SIMROOT}"				// Expenditure.do hace cd a raw/ENIGH/: sin esto "." deja de ver los .ado del motor (ensure_asset)
set scheme ciep
timer clear 1
timer on 1

*** 0 SET UP (espejo de SIM.do §0 con el vintage como año de política y de valor presente) ***
capture run "${SIMROOT}/set_token.do"	// opcional: solo hace falta si las bases de master/ no existen y hay que consultar el BIE
global id = "`c(username)'-v`anio'"
scalar aniovp = `anio'									// ANIO VALOR PRESENTE  = vintage
scalar anioPE = `anio'									// ANIO PAQUETE ECONÓMICO = vintage (calibración contemporánea)
scalar anioenigh = `anio'								// ANIO ENIGH = vintage
global bootstrap "1"									// una pasada, sin réplicas (la banda lee sumas ponderadas, no EE)
global seed "1111"
set seed $seed
global nographs "nographs"
global algebra "algebra"
capture mkdir "${SIMROOT}/users/"
capture mkdir "${SIMROOT}/users/$id"
noisily di _newline in g _dup(20) "." "{bf:   vintage-aportaciones: ENIGH " in y `anio' in g " — anioPE = aniovp = anioenigh = " in y `anio' in g "   }" _dup(20) "."
noisily di in g "  usuario de la corrida: " in y "$id" in g " · SIMROOT: " in y "${SIMROOT}"

*** 1 DEMOGRAFÍA ***
noisily Poblacion, anioi(`=aniovp') aniofinal(2070) $nographs

*** 2 ECONOMÍA (mismos supuestos de proyección que SIM.do §2; solo afectan años > último observado) ***
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

*** 4 SISTEMA FISCAL: INGRESOS (SIM.do §4 sin §4.1: calibración contemporánea) ***
set scheme ingresos
noisily LIF if divLIF != 10, anio(`=anioPE') by(divCIEP) $nographs ///
	title("Ingresos presupuestarios") desde(2016) min(0.75) rows(2)
* §4.1 de SIM.do OMITIDO A PROPÓSITO: sin escalares <X>PIB, TasasEfectivas.ado §2 toma lo observado en LIF `anio'. *
foreach k in ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA ISAN IEPSNP IEPSP IMPORT {
	capture confirm scalar `k'PIB
	if _rc == 0 {
		di as err "vintage-aportaciones: el escalar `k'PIB ya existe en la sesión; la calibración dejaría de ser contemporánea."
		exit 459
	}
}
noisily TasasEfectivas, anio(`=anioPE') enigh

*** 5 SISTEMA FISCAL: EGRESOS (SIM.do §5 sin §5.1 ni Precache: GastoPC toma el PEF `anio') ***
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
	noisily Simulador `k' if `k' != 0 [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot title("") bootstrap(1)
}
save `"${SIMROOT}/users/$id/aportaciones.dta"', replace

*** Compuerta: lo que la banda lee (SankeySF.do _SFsellos: llave, factor, edad, ingreso, cortes y las 9 familias) ***
foreach v in folioviv foliohog numren factor edad ingbrutotot grupoedad sexo rural escol ///
	AlTrabajo AlConsumo AlCapital ImpuestosAportaciones Educacion Salud Pensiones IngBasico OtrasInversiones {
	confirm variable `v'
}
timer off 1
quietly timer list 1
noisily di _newline in g "vintage-aportaciones ENIGH `anio': " in y "VINTAGE_OK `anio'" in g " en " in y round(r(t1), 1) in g " s · " in y "${SIMROOT}/users/$id/aportaciones.dta" in g " (" in y _N in g " personas)"
