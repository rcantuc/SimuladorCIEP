**************
*** SANKEY ***
**************
**
** 9. Especifico de Mexico (plantilla de capitulo §9; alimenta cap0; texto de CUAD-2 §9, 2026-11-07; sin cambio de codigo):
**   | Elemento                        | Que requiere genericamente                                  | Por que Mexico lo resuelve asi                                          |
**   | CSI por sector institucional    | Cuentas corrientes completas (I-III) por sector con B.5n,   | INEGI publica S.11-S.15 y S.2 (base 2018) sin la matriz de quien a     |
**   |                                 | B.6n, B.8n, B.9                                             | quien de D.4 ni D.7; los receptores se infieren por sector; las filas   |
**   |                                 |                                                             | de sector del eje 1 (B5nNoFin, B5nFin, B5nGob, B5nISFLSH, RowPrimNeto,  |
**   |                                 |                                                             | D442Hog) salen de SCNHogaresS14                                         |
**   | INBD como pivote                | Un agregado neto de ingreso, despues de la renta primaria   | BIE 724037 (escalar mxn IngDisp) = 27,459.038 = 81.561 % del PIB 2024,  |
**   |                                 | con el exterior y de las transferencias corrientes          | coincide al peso con PIN + ROW (SCN.ado cuenta C); la CSI da B.6n S.1   |
**   |                                 |                                                             | con otro vintage (CUAD-2 §6: hub = inbd)                                |
**   | Vintage BIE vs CSI              | Una sola fuente para anclas y PIB                            | Dos vintages del INEGI: PIB 33,667.023 vs B.1b 33,582.899; CCF 6,457.576|
**   |                                 |                                                             | vs 6,458.352; se declara como fila «Vintage BIE vs CSI» (l. 96)         |
**   | Remesas                         | Transferencias corrientes de hogares no residentes por edad | ROWTrans BIE 1,186.091 (D.752 CSI 1,188.474); Banxico como contraste   |
**
if "`1'" == "" {
	clear programs
	local 1 = "decil"
	local 2 = 2024
	local 3 = "SankeyNTA"
	scalar anioenigh = 2024
}
if "`2'" >= "2022" {
	local 2 = 2024
}
timer on 7
noisily di _newline(2) in g "{bf: Sankey}: " in y "`1' `2'"



****************
** 0 Economia **
SCN, anio(`2') nographs



****************
** 1 Ingresos **
LIF, anio(`2') nographs min(0) by(divCIEP)
local CuotasIMSS = scalar(Cuotas_IMSS)
local IMSSpropio = r(IMSS) //-`CuotasIMSS'
local ISSSTEpropio = r(ISSSTE)
local CFEpropio = r(CFE)
local Pemexpropio = r(Pemex)
local FMP = r(FMP_Derechos)
local Mejoras = r(Contrib_de_mejora)
local Derechos = r(Derechos)
local Productos = r(Productos)
local Aprovechamientos = r(Aprovechamientos)
local OtrosTributarios = r(Otros_tributarios)
local OtrasEmpresas = r(Otras_empresas)



**********************************/
** Eje 1: Generación del ingreso **
use `"${SIMROOT}/master/`2'/households.dta"', clear
* v8.15b: los parametros firmados viajan en la base (char cuad_params), por si Sankey.do corre sin la sesion de SIM.do *
local cuad : char _dta[cuad_params]
foreach p in oye_en_hub suborrow cuotas_d614 consumo_ancla {
	if "${`p'}" == "" & regexm("`cuad'", "`p'=([^ ]+)") global `p' = regexs(1)
}
if "$consumo_ancla" == "" global consumo_ancla "p3_s14"

noisily tabstat Yl Yk ing_estim_alqu [fw=factor], stat(sum) format(%20.0fc) by(`1')

replace Yk = Yk - ing_estim_alqu
collapse (sum) ing_Ing_Laboral=Yl ing_Ing_Capital=Yk ing_Alquiler_propio=ing_estim_alqu [fw=factor], by(`1')

noisily tabstat ing_Ing_Laboral ing_Ing_Capital ing_Alquiler_propio, stat(sum) format(%20.0fc) by(`1')

* to *
tempvar to
reshape long ing_, i(`1') j(`to') string
rename ing_ profile
encode `to', g(to)

* from *
rename `1' from

* Sector Publico: solo con oye_en_hub = on (v8.14.0). Con off (firmado, CUAD-0 decision 10) OyE no es ingreso de personas ni entra al hub:
* en el Sankey fiscal (SankeySF.do) ya entra como «Empresas publicas → CGPE» y en los NTA como «Empresas publicas → Gobierno». *
if "$oye_en_hub" == "on" {
	set obs `=_N+1'
	replace from = -2 in -1
	replace profile = `IMSSpropio' + `ISSSTEpropio' + `CFEpropio' + `Pemexpropio' + `FMP' + `OtrasEmpresas' in -1
	label define `1' -2 "OyE_públicas", add
	replace to = 2 in -1
}

* ROW: remesas (ROWTrans BIE); las remuneraciones del exterior solo con suborrow = on (con off ya viven dentro de D.1 S.14 = Ing laboral) *
set obs `=_N+1'
replace from = -1 in -1
replace to = 101 in -1
replace profile = scalar(ROWTrans) in -1
label define `1' -1 "El mundo", add
label define to 101 "Remesas", add
if "$suborrow" == "on" {
	set obs `=_N+1'
	replace from = -1 in -1
	replace to = 3 in -1
	replace profile = scalar(ROWRem) in -1
}

* v8.15b (CUAD-0 firma, decision 13): filas de sector sin edad (CSI 2024, via SCN.ado) → «Otros sectores» → Ing nacional. Con ellas el hub vuelve
* a ser el PIB (BIE): PIB = YL + YA + D.442 + B.5n S.11+S.12 + B.5n S.13 + B.5n S.15 + CCF + renta primaria neta pagada al exterior + vintage
* BIE−CSI (Households.do §9.1 lo exige a 1e-9). El vintage = (PIB BIE − B.1b CSI) + (P.51c CSI − CapFij BIE). *
label define to 103 "Otros sectores", add
local vint = scalar(PIB) - scalar(PIBCSI) + scalar(CapFijCSI) - scalar(CapFij)
local d442 = cond("$cuotas_d614" == "neto", scalar(D442Hog), 0)
foreach fila in "-3 Sociedades_S11_S12 `=scalar(B5nNoFin) + scalar(B5nFin)'" "-4 S13_impuestos_netos_y_renta_de_la_propiedad_neta `=scalar(B5nGob)'" "-5 ISFLSH_S15 `=scalar(B5nISFLSH)'" ///
	"-1 El_mundo `=scalar(RowPrimNeto)'" "-6 Vintage_BIE_vs_CSI `vint'" "-7 Fondos_de_pensión_D442 `d442'" {
	gettoken code fila : fila
	gettoken lab val : fila
	local val = trim("`val'")
	if `val' == 0 continue
	set obs `=_N+1'
	replace from = `code' in -1
	replace to = 103 in -1
	replace profile = `val' in -1
	if `code' != -1 label define `1' `code' "`lab'", add
}

* Compras Netas *
if scalar(ComprasN) < 0 {
	set obs `=_N+1'
	replace from = -1 if from == .
	replace to = 102 in -1
	replace profile = -scalar(ComprasN) in -1
	label define to 102 "Turistas extranjeros", add
}

* Eje */
tempfile eje1
save `eje1'



********************
** Eje 4: Consumo **
use `"${SIMROOT}/master/`2'/households.dta"', clear
collapse (sum) gas_pc* gasto_anual* gasto_anualAhorro=Ahorro [fw=factor], by(`1')
egen gasto_Alimentos = rsum(gas_pc_Agua gas_pc_Alim gas_pc_BebN)
egen gasto_Vestido = rsum(gas_pc_Vest gas_pc_Calz)
egen gasto__Salud = rsum(gas_pc_Salu)
egen gasto___Educación = rsum(gas_pc_Educ gas_pc_Recr)
egen gasto___Vivienda = rsum(gas_pc_Alqu gas_pc_Hoga gas_pc_Comu gas_pc_Elec)
egen gasto___Transporte = rsum(gas_pc_Vehi gas_pc_STra gas_pc_FTra)
egen gasto____Otros_gastos = rsum(gas_pc_Taba gas_pc_BebA gas_pc_Dive gas_pc_Rest)
*egen gasto_____Consumo_gobierno = rsum(gasto_anualGobierno)
egen gasto_____Depreciación = rsum(gasto_anualDepreciacion)
*egen gasto____Ahorro = rsum(gasto_anualAhorro)
drop gasto_anual*

levelsof `1', local(`1')
foreach k of local `1' {
	local oldlabel : label (`1') `k'
	label define `1' `k' "_`oldlabel'", modify
}

* from */
tempvar from
reshape long gasto_, i(`1') j(`from') string
rename gasto_ profile
encode `from', g(from)

* to *
rename `1' to

* Sector Publico *
set obs `=_N+3'
replace to = -1 if from == .
label define `1' -1 "Bienes_públicos", add

replace profile = scalar(SerEGob) in -1
replace from = 4 in -1

replace profile = scalar(SaluGob) in -2
replace from = 3 in -2

replace profile = scalar(ConGob) - scalar(SerEGob) - scalar(SaluGob) in -3
replace from = 7 in -3

* Ahorro *
set obs `=_N+1'
drop if from == 98
replace from = 98 in -1
replace to = -2 in -1 
replace profile = scalar(AhorroN) in -1
label define `1' -2 "_Futuro", add
label define from 98 "Ahorro", add

* ROW: renta primaria neta pagada al exterior (D.4 neta pagada − D.1 recibida; v8.15b: la D.1 del exterior ya esta dentro de Ing laboral) *
set obs `=_N+1'
replace to = -3 if from == .
label define `1' -3 "__El mundo", add
replace from = 99 in -1
replace profile = -scalar(ROWProp) - scalar(ROWRem) in -1
label define from 99 "_Renta primaria al exterior", add

* 8.16b (CUAD-1 firma, consumo_ancla = p3_s14): Σ gas_pc_* ya no es ConHog BIE (hogares + ISFLSH en territorio) sino P.3 S.14 − compras netas; lo que
* ConHog contiene y no es consumo de las personas sale como dos filas de sector del lado de los usos: P.3 de las ISFLSH (CSI_118 f.166) y el vintage
* BIE−CSI del consumo de residentes (ConHog + compras netas − P.3 S.14 − P.3 S.15). Asi los usos siguen sumando lo mismo que las fuentes. *
if "$consumo_ancla" == "p3_s14" {
	capture confirm scalar ConISFLSH
	if _rc == 0 {
		local vcons = scalar(ConHog) + scalar(ComprasN) - scalar(ConHogS14) - scalar(ConISFLSH)
		set obs `=_N+2'
		replace to = -4 if from == .
		label define `1' -4 "__Otros sectores", add
		replace from = 97 in -2
		replace profile = scalar(ConISFLSH) in -2
		label define from 97 "_Consumo ISFLSH S15", add
		replace from = 96 in -1
		replace profile = `vcons' in -1
		label define from 96 "_Vintage consumo BIE vs CSI", add
	}
	else noisily di as err "  FLAG Sankey (consumo_ancla = p3_s14): SCN sin ConISFLSH; los usos no llevan las filas de ISFLSH y vintage del consumo."
}


/* Depreciacion *
replace to = -4 if from == 9
label define `1' -4 "__Depreciacion", add

* Eje */
tempfile eje4
save `eje4'



********************
** Eje 2: Total 1 **
use `eje1', clear
collapse (sum) profile, by(to)
rename to from

g to = 999
label define PIB 999 "Ing nacional"
label values to PIB

tempfile eje2
save `eje2'



********************
** Eje 3: Total 2 **
use `eje4', clear
collapse (sum) profile, by(from)
rename from to

g from = 999
label define PIB 999 "Ing nacional"
label values from PIB

tempfile eje3
save `eje3'



************
** Sankey **
noisily SankeySumSim, anio(`2') name(`1') folder(`3') a(`eje1') b(`eje2') c(`eje3') d(`eje4') 

timer off 7
timer list 7
noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t7)/r(nt7)',.1) in g " segs."

