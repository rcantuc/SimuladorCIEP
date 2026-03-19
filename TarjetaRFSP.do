****
**** TARJETA INFORMATIVA: REQUERIMIENTOS FINANCIEROS DEL SECTOR PÚBLICO
**** CIEP - Centro de Investigación Económica y Presupuestaria
****
**** Descripción: Genera una tarjeta informativa mensual con los RFSP
**** y sus componentes, mostrando:
****   1. Monto acumulado al mes más reciente
****   2. Variación vs. mismo mes del año anterior
****   3. Variación vs. cierre (diciembre) del año anterior
****
**** Componentes:
****   - RFSP (total)
****   - Balance presupuestario
****   - Banca de desarrollo
****   - El resto (PIDIREGAS + IPAB + FONADIN + Deudores + Adecuaciones)
****


***
**# 0. SET UP
***
capture confirm scalar aniovp
if _rc != 0 {
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	scalar aniovp = real(substr(`"`=trim("`fecha'")'"',1,4))
}
local aniovp = scalar(aniovp)

** Verificar que exista la base de DatosAbiertos **
capture confirm file `"`c(sysdir_site)'/master/DatosAbiertos.dta"'
if _rc != 0 {
	noisily di in r "No se encontró la base de DatosAbiertos.dta. Ejecute primero: DatosAbiertos, update"
	exit
}

** Verificar que exista el deflactor **
capture confirm file `"`c(sysdir_site)'/master/Deflactor.dta"'
if _rc != 0 {
	noisily di in r "No se encontró la base de Deflactor.dta. Ejecute primero: PIBDeflactor, update"
	exit
}



***
**# 1. OBTENER DATOS MENSUALES DE RFSP Y COMPONENTES
***

** 1.1 RFSP Total (flujo, cifras con signo invertido = reverse) **
use if clave_de_concepto == "RF000000SPFCS" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
replace monto = -monto
keep anio mes monto
rename monto rfsp
tempfile rfsp
save `rfsp'

** 1.2 Balance presupuestario **
use if clave_de_concepto == "RF000001SPFCS" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
replace monto = -monto
keep anio mes monto
rename monto rfspBalance
tempfile balance
save `balance'

** 1.3 Banca de desarrollo **
use if clave_de_concepto == "RF000006SPFCS" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
replace monto = -monto
keep anio mes monto
rename monto rfspBanca
tempfile banca
save `banca'

** 1.4 PIDIREGAS **
use if clave_de_concepto == "RF000002SPFCS" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
replace monto = -monto
keep anio mes monto
rename monto rfspPIDIREGAS
tempfile pidiregas
save `pidiregas'

** 1.5 IPAB **
use if clave_de_concepto == "RF000003SPFCS" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
replace monto = -monto
keep anio mes monto
rename monto rfspIPAB
tempfile ipab
save `ipab'

** 1.6 FONADIN **
use if clave_de_concepto == "RF000004SPFCS" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
replace monto = -monto
keep anio mes monto
rename monto rfspFONADIN
tempfile fonadin
save `fonadin'

** 1.7 Programa de Deudores **
use if clave_de_concepto == "RF000005SPFCS" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
replace monto = -monto
keep anio mes monto
rename monto rfspDeudores
tempfile deudores
save `deudores'

** 1.8 Adecuaciones **
use if clave_de_concepto == "RF000007SPFCS" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
replace monto = -monto
keep anio mes monto
rename monto rfspAdecuaciones
tempfile adecuaciones
save `adecuaciones'



***
**# 2. MERGE DE COMPONENTES MENSUALES
***
use `rfsp', clear
merge 1:1 (anio mes) using `balance', nogen
merge 1:1 (anio mes) using `banca', nogen
merge 1:1 (anio mes) using `pidiregas', nogen
merge 1:1 (anio mes) using `ipab', nogen
merge 1:1 (anio mes) using `fonadin', nogen
merge 1:1 (anio mes) using `deudores', nogen
merge 1:1 (anio mes) using `adecuaciones', nogen

** 2.1 Generar "El resto" = PIDIREGAS + IPAB + FONADIN + Deudores + Adecuaciones **
egen rfspResto = rowtotal(rfspPIDIREGAS rfspIPAB rfspFONADIN rfspDeudores rfspAdecuaciones)

sort anio mes



***
**# 3. MERGE CON DEFLACTOR PARA CIFRAS REALES
***
merge 1:1 (anio mes) using `"`c(sysdir_site)'/master/Deflactor.dta"', nogen keep(matched)
sort anio mes



***
**# 4. IDENTIFICAR ÚLTIMO MES Y AÑO DISPONIBLE
***
local last_anio = anio[_N]
local last_mes = mes[_N]

** Etiquetas para los meses **
label define mes 1 "Enero" 2 "Febrero" 3 "Marzo" 4 "Abril" 5 "Mayo" 6 "Junio" ///
	7 "Julio" 8 "Agosto" 9 "Septiembre" 10 "Octubre" 11 "Noviembre" 12 "Diciembre"
label values mes mes
local mesname : label mes `last_mes'



***
**# 5. CALCULAR ACUMULADOS Y VARIACIONES
***

** 5.1 Acumulado año-a-la-fecha (year-to-date) para cada variable **
foreach var of varlist rfsp rfspBalance rfspBanca rfspResto {

	** Acumulado enero a mes actual, año actual **
	egen double acum_`var'_hoy = sum(`var') if anio == `last_anio' & mes <= `last_mes', by(anio)
	
	** Acumulado enero al mismo mes, año anterior **
	egen double acum_`var'_ant = sum(`var') if anio == `last_anio' - 1 & mes <= `last_mes', by(anio)
	
	** Solo mes actual, año actual **
	egen double mes_`var'_hoy = sum(`var') if anio == `last_anio' & mes == `last_mes', by(anio)
	
	** Solo mismo mes, año anterior **
	egen double mes_`var'_ant = sum(`var') if anio == `last_anio' - 1 & mes == `last_mes', by(anio)
}

** 5.2 Deflactores para expresar en términos reales **
** Deflactor acumulado al mes actual (promedio de INPC enero a mes_actual del año actual) **
egen double inpc_acum_hoy = mean(inpc) if anio == `last_anio' & mes <= `last_mes', by(anio)

** Deflactor acumulado al mismo mes del año anterior **
egen double inpc_acum_ant = mean(inpc) if anio == `last_anio' - 1 & mes <= `last_mes', by(anio)

** Deflactor del mes actual (INPC del mes actual del año actual) **
egen double inpc_mes_hoy = max(inpc) if anio == `last_anio' & mes == `last_mes', by(anio)

** Deflactor del mismo mes del año anterior **
egen double inpc_mes_ant = max(inpc) if anio == `last_anio' - 1 & mes == `last_mes', by(anio)



***
**# 6. EXTRAER VALORES PARA LA TARJETA
***

** 6.1 Obtener deflactores **
summarize inpc_acum_hoy if anio == `last_anio'
local deflactor_hoy = r(mean)

summarize inpc_acum_ant if anio == `last_anio' - 1
local deflactor_ant = r(mean)

summarize inpc_mes_hoy if anio == `last_anio'
local deflactor_mes_hoy = r(mean)

summarize inpc_mes_ant if anio == `last_anio' - 1
local deflactor_mes_ant = r(mean)

** 6.2 Calcular montos y variaciones reales para cada componente **
foreach var in rfsp rfspBalance rfspBanca rfspResto {

	** Monto acumulado hoy (nominal) **
	summarize acum_`var'_hoy if anio == `last_anio'
	local `var'_hoy_nom = r(mean)

	** Monto acumulado mismo mes año anterior (nominal) **
	summarize acum_`var'_ant if anio == `last_anio' - 1
	local `var'_ant_nom = r(mean)

	** Monto solo mes actual (nominal) **
	summarize mes_`var'_hoy if anio == `last_anio'
	local `var'_mes_hoy_nom = r(mean)

	** Monto solo mismo mes año anterior (nominal) **
	summarize mes_`var'_ant if anio == `last_anio' - 1
	local `var'_mes_ant_nom = r(mean)

	** Variación real ACUMULADA vs mismo periodo año anterior (%) **
	local `var'_hoy_real = ``var'_hoy_nom'
	local `var'_ant_real = ``var'_ant_nom' * (`deflactor_hoy' / `deflactor_ant')
	local `var'_var_interanual = (``var'_hoy_real' / ``var'_ant_real' - 1) * 100

	** Variación real MES vs mismo mes año anterior (%) **
	local `var'_mes_hoy_real = ``var'_mes_hoy_nom'
	local `var'_mes_ant_real = ``var'_mes_ant_nom' * (`deflactor_mes_hoy' / `deflactor_mes_ant')
	local `var'_var_mes = (``var'_mes_hoy_real' / ``var'_mes_ant_real' - 1) * 100
}



***
**# 7. DESPLIEGUE DE LA TARJETA INFORMATIVA
***
** (Formato para copiar y pegar en infografía)
**
** Estructura por fila:
**   [Var % acum. vs acum. año ant.]   Concepto / $ Monto   [Var % mes vs mismo mes año ant.]
**

local mesmin = lower("`mesname'")
local anio_ant = `last_anio' - 1

** 7.1 Formatear montos en bdp (billones) o mdp (millones de pesos) **
foreach var in rfsp rfspBalance rfspBanca rfspResto {
	local monto_abs = abs(``var'_hoy_nom')
	if `monto_abs' >= 1000000000000 {
		local `var'_monto_str = string(``var'_hoy_nom'/1000000000000, "%10.2fc") + " bdp"
	}
	else {
		local `var'_monto_str = string(``var'_hoy_nom'/1000000, "%12.1fc") + " mdp"
	}

	** Formatear variaciones con signo + / - **
	if ``var'_var_interanual' >= 0 {
		local `var'_interanual_str = "+ " + string(``var'_var_interanual', "%4.1fc") + " %"
	}
	else {
		local `var'_interanual_str = "- " + string(abs(``var'_var_interanual'), "%4.1fc") + " %"
	}

	if ``var'_var_mes' >= 0 {
		local `var'_mes_str = "+ " + string(``var'_var_mes', "%4.1fc") + " %"
	}
	else {
		local `var'_mes_str = "- " + string(abs(``var'_var_mes'), "%4.1fc") + " %"
	}
}


** 7.2 Desplegar tarjeta **
noisily di _newline(3)
noisily di in g _dup(80) "="
noisily di in g "{bf:  TARJETA INFORMATIVA: RFSP}"
noisily di in y "{bf:  Información a `mesname' `last_anio'}"
noisily di in g _dup(80) "="
noisily di ""
noisily di in g "  {bf:Crecimiento real respecto de:}"
noisily di ""
noisily di in g _col(5) "{bf:Acum. ene-`mesmin' `anio_ant'}" _col(30) "{bf:Concepto / Monto}" _col(58) "{bf:`mesname' `anio_ant'}"
noisily di in g _dup(80) "-"

** RFSP Total **
noisily di in g _col(30) "{bf:RFSP}"
noisily di in y _col(5) "{bf:`rfsp_interanual_str'}" _col(30) "{bf:$ `rfsp_monto_str'}" _col(58) "{bf:`rfsp_mes_str'}"
noisily di in g _dup(80) "-"

** Balance presupuestario **
noisily di in g _col(30) "Balance presupuestario"
noisily di in y _col(5) "`rfspBalance_interanual_str'" _col(30) "$ `rfspBalance_monto_str'" _col(58) "`rfspBalance_mes_str'"
noisily di in g _dup(80) "-"

** Banca de desarrollo **
noisily di in g _col(30) "Banca de desarrollo"
noisily di in y _col(5) "`rfspBanca_interanual_str'" _col(30) "$ `rfspBanca_monto_str'" _col(58) "`rfspBanca_mes_str'"
noisily di in g _dup(80) "-"

** El resto (PIDIREGAS + IPAB + FONADIN + Deudores + Adecuaciones) **
noisily di in g _col(30) "Resto (PIDIREGAS, IPAB, FONADIN, Deudores, Adecuaciones)"
noisily di in y _col(5) "`rfspResto_interanual_str'" _col(30) "$ `rfspResto_monto_str'" _col(58) "`rfspResto_mes_str'"

noisily di in g _dup(80) "="

** 7.3 Nota al pie **
noisily di ""
noisily di in g "{bf:Nota:} Un valor negativo indica super{c a'}vit."
noisily di ""
noisily di in g "{bf:Fuentes:} SHCP/Datos Abiertos de Finanzas P{c u'}blicas, CIEP (`last_anio')."



***
**# 8. OBTENER DATOS MENSUALES DE COSTO FINANCIERO
***

** 8.1 Costo financiero total **
use if clave_de_concepto == "XAC21" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
keep anio mes monto
rename monto costoTotal
tempfile costoTotal
save `costoTotal'

** 8.2 Costo financiero Gobierno Federal **
use if clave_de_concepto == "XBC21" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
keep anio mes monto
rename monto costoGobFed
tempfile costoGobFed
save `costoGobFed'

** 8.3 Costo financiero Pemex **
use if clave_de_concepto == "XOA0160" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
keep anio mes monto
rename monto costoPemex
tempfile costoPemex
save `costoPemex'

** 8.4 Costo financiero CFE **
use if clave_de_concepto == "XOA0162" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
keep anio mes monto
rename monto costoCFE
tempfile costoCFE
save `costoCFE'



***
**# 9. MERGE DE COMPONENTES DE COSTO FINANCIERO
***
use `costoTotal', clear
merge 1:1 (anio mes) using `costoGobFed', nogen
merge 1:1 (anio mes) using `costoPemex', nogen
merge 1:1 (anio mes) using `costoCFE', nogen

sort anio mes

** Merge con deflactor **
merge 1:1 (anio mes) using `"`c(sysdir_site)'/master/Deflactor.dta"', nogen keep(matched)
sort anio mes



***
**# 10. CALCULAR ACUMULADOS Y VARIACIONES DE COSTO FINANCIERO
***

** Identificar último mes/año disponible **
local cf_last_anio = anio[_N]
local cf_last_mes = mes[_N]

label define mes2 1 "Enero" 2 "Febrero" 3 "Marzo" 4 "Abril" 5 "Mayo" 6 "Junio" ///
	7 "Julio" 8 "Agosto" 9 "Septiembre" 10 "Octubre" 11 "Noviembre" 12 "Diciembre"
capture label values mes mes2
local cf_mesname : label mes2 `cf_last_mes'

** 10.1 Acumulados year-to-date **
foreach var of varlist costoTotal costoGobFed costoPemex costoCFE {

	** Acumulado enero a mes actual, año actual **
	egen double acum_`var'_hoy = sum(`var') if anio == `cf_last_anio' & mes <= `cf_last_mes', by(anio)

	** Acumulado enero al mismo mes, año anterior **
	egen double acum_`var'_ant = sum(`var') if anio == `cf_last_anio' - 1 & mes <= `cf_last_mes', by(anio)
}

** 10.2 Deflactores (promedio ene a mes actual) **
egen double cf_inpc_acum_hoy = mean(inpc) if anio == `cf_last_anio' & mes <= `cf_last_mes', by(anio)
egen double cf_inpc_acum_ant = mean(inpc) if anio == `cf_last_anio' - 1 & mes <= `cf_last_mes', by(anio)



***
**# 11. EXTRAER VALORES DE COSTO FINANCIERO
***

** 11.1 Obtener deflactores **
summarize cf_inpc_acum_hoy if anio == `cf_last_anio'
local cf_deflactor_hoy = r(mean)

summarize cf_inpc_acum_ant if anio == `cf_last_anio' - 1
local cf_deflactor_ant = r(mean)

** 11.2 Calcular montos y variaciones reales (solo interanual: acum vs acum) **
foreach var in costoTotal costoGobFed costoPemex costoCFE {

	** Monto acumulado hoy (nominal) **
	summarize acum_`var'_hoy if anio == `cf_last_anio'
	local `var'_hoy_nom = r(mean)

	** Monto acumulado mismo mes año anterior (nominal) **
	summarize acum_`var'_ant if anio == `cf_last_anio' - 1
	local `var'_ant_nom = r(mean)

	** Montos reales **
	local `var'_hoy_real = ``var'_hoy_nom'
	local `var'_ant_real = ``var'_ant_nom' * (`cf_deflactor_hoy' / `cf_deflactor_ant')

	** Variación real acumulada vs mismo periodo año anterior (%) **
	local `var'_var_interanual = (``var'_hoy_real' / ``var'_ant_real' - 1) * 100
}



***
**# 12. DESPLIEGUE TARJETA COSTO FINANCIERO
***

local cf_mesmin = lower("`cf_mesname'")
local cf_anio_ant = `cf_last_anio' - 1

** 12.1 Formatear montos y variaciones **
foreach var in costoTotal costoGobFed costoPemex costoCFE {
	** Monto año actual **
	local monto_abs = abs(``var'_hoy_nom')
	if `monto_abs' >= 1000000000000 {
		local `var'_monto_str = string(``var'_hoy_nom'/1000000000000, "%10.2fc") + " bdp"
	}
	else {
		local `var'_monto_str = string(``var'_hoy_nom'/1000000, "%12.1fc") + " mdp"
	}

	** Monto año anterior **
	local monto_ant_abs = abs(``var'_ant_nom')
	if `monto_ant_abs' >= 1000000000000 {
		local `var'_monto_ant_str = string(``var'_ant_nom'/1000000000000, "%10.2fc") + " bdp"
	}
	else {
		local `var'_monto_ant_str = string(``var'_ant_nom'/1000000, "%12.1fc") + " mdp"
	}

	if ``var'_var_interanual' >= 0 {
		local `var'_interanual_str = "+ " + string(``var'_var_interanual', "%4.1fc") + " %"
	}
	else {
		local `var'_interanual_str = "- " + string(abs(``var'_var_interanual'), "%4.1fc") + " %"
	}

}


** 12.2 Desplegar tarjeta (formato infografía tipo "Ingresos por Energía") **
** Colores: amarillo (in y) = datos dinámicos, verde (in g) = etiquetas fijas **
noisily di _newline(5)
noisily di in g _dup(80) "="
noisily di in g "{bf:  TARJETA INFORMATIVA: COSTO FINANCIERO DE LA DEUDA}"
noisily di in y "{bf:  Informaci{c o'}n a `cf_mesname' `cf_last_anio'}"
noisily di in g _dup(80) "="
noisily di ""
noisily di in g "  {bf:Costo financiero}"
noisily di ""
noisily di in y "  {bf:`costoTotal_interanual_str'}"
noisily di ""
noisily di in g _dup(40) "." _col(45) _dup(15) "."
noisily di ""
noisily di _col(45) in g "Gob. Federal" _col(65) in y "{bf:`costoGobFed_interanual_str'}"
noisily di ""
noisily di in g _dup(40) " " _col(45) _dup(15) "- "
noisily di ""
noisily di _col(45) in g "Pemex" _col(65) in y "{bf:`costoPemex_interanual_str'}"
noisily di ""
noisily di in g _dup(40) " " _col(45) _dup(15) "- "
noisily di ""
noisily di _col(45) in g "CFE" _col(65) in y "{bf:`costoCFE_interanual_str'}"
noisily di ""
noisily di in g "  {it:Crecimiento real respecto al acumulado en `cf_anio_ant'.}"
noisily di ""
noisily di in g _dup(80) "."
noisily di ""
noisily di in y _col(10) "$ `costoTotal_monto_ant_str'" _col(45) in y "$ `costoTotal_monto_str'"
noisily di in g _col(10) "(acum. ene-`cf_mesmin' `cf_anio_ant')" _col(45) in g "(acum. ene-`cf_mesmin' `cf_last_anio')"
noisily di ""
noisily di in g _dup(80) "="
noisily di ""



***
**# 13. OBTENER DATOS MENSUALES DE SALDO HISTÓRICO (SHRFSP)
***

** 13.1 SHRFSP Total **
use if clave_de_concepto == "SHRF5000" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
keep anio mes monto
rename monto shrfspTotal
tempfile shrfspTotal
save `shrfspTotal'

** 13.2 Gobierno Federal - Deuda Interna **
use if clave_de_concepto == "XED80" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
keep anio mes monto
rename monto shrfspGFInt
tempfile shrfspGFInt
save `shrfspGFInt'

** 13.3 Gobierno Federal - Deuda Externa **
use if clave_de_concepto == "XEB4010" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
keep anio mes monto
rename monto shrfspGFExt
tempfile shrfspGFExt
save `shrfspGFExt'

** 13.4 Organismos y Empresas - Deuda Interna **
use if clave_de_concepto == "XED110" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
keep anio mes monto
rename monto shrfspOyEInt
tempfile shrfspOyEInt
save `shrfspOyEInt'

** 13.5 Organismos y Empresas - Deuda Externa **
use if clave_de_concepto == "XEB4020" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
keep anio mes monto
rename monto shrfspOyEExt
tempfile shrfspOyEExt
save `shrfspOyEExt'

** 13.6 Banca de Desarrollo - Deuda Interna **
use if clave_de_concepto == "XED140" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
keep anio mes monto
rename monto shrfspBancaInt
tempfile shrfspBancaInt
save `shrfspBancaInt'

** 13.7 Banca de Desarrollo - Deuda Externa **
use if clave_de_concepto == "XEB4030" using `"`c(sysdir_site)'/master/DatosAbiertos.dta"', clear
keep anio mes monto
rename monto shrfspBancaExt
tempfile shrfspBancaExt
save `shrfspBancaExt'



***
**# 14. MERGE DE COMPONENTES DE SHRFSP
***
use `shrfspTotal', clear
merge 1:1 (anio mes) using `shrfspGFInt', nogen
merge 1:1 (anio mes) using `shrfspGFExt', nogen
merge 1:1 (anio mes) using `shrfspOyEInt', nogen
merge 1:1 (anio mes) using `shrfspOyEExt', nogen
merge 1:1 (anio mes) using `shrfspBancaInt', nogen
merge 1:1 (anio mes) using `shrfspBancaExt', nogen

sort anio mes

** Generar componentes combinados (interno + externo) **
gen double shrfspGobFed = shrfspGFInt + shrfspGFExt
gen double shrfspOyE = shrfspOyEInt + shrfspOyEExt
gen double shrfspBanca = shrfspBancaInt + shrfspBancaExt

** Merge con deflactor **
merge 1:1 (anio mes) using `"`c(sysdir_site)'/master/Deflactor.dta"', nogen keep(matched)
sort anio mes



***
**# 15. CALCULAR VARIACIONES DE SHRFSP (dato tipo saldo: valor puntual, no acumulado)
***

** Identificar último mes/año disponible **
local sh_last_anio = anio[_N]
local sh_last_mes = mes[_N]

capture label drop mes3
label define mes3 1 "Enero" 2 "Febrero" 3 "Marzo" 4 "Abril" 5 "Mayo" 6 "Junio" ///
	7 "Julio" 8 "Agosto" 9 "Septiembre" 10 "Octubre" 11 "Noviembre" 12 "Diciembre"
label values mes mes3
local sh_mesname : label mes3 `sh_last_mes'

** Deflactores del mes puntual (para saldos, usar INPC del mes, no promedio) **
summarize inpc if anio == `sh_last_anio' & mes == `sh_last_mes'
local sh_inpc_hoy = r(mean)

summarize inpc if anio == `sh_last_anio' - 1 & mes == `sh_last_mes'
local sh_inpc_ant = r(mean)



***
**# 16. EXTRAER VALORES Y VARIACIONES DE SHRFSP
***

foreach var in shrfspTotal shrfspGobFed shrfspOyE shrfspBanca {

	** Valor mes actual (nominal) **
	summarize `var' if anio == `sh_last_anio' & mes == `sh_last_mes'
	local `var'_hoy_nom = r(mean)

	** Valor mismo mes año anterior (nominal) **
	summarize `var' if anio == `sh_last_anio' - 1 & mes == `sh_last_mes'
	local `var'_ant_nom = r(mean)

	** Montos reales (deflactado a precios del mes actual) **
	local `var'_hoy_real = ``var'_hoy_nom'
	local `var'_ant_real = ``var'_ant_nom' * (`sh_inpc_hoy' / `sh_inpc_ant')

	** Variación real interanual (%) **
	local `var'_var_interanual = (``var'_hoy_real' / ``var'_ant_real' - 1) * 100
}



***
**# 17. DESPLIEGUE TARJETA SHRFSP
***

local sh_mesmin = lower("`sh_mesname'")
local sh_anio_ant = `sh_last_anio' - 1

** 17.1 Formatear montos y variaciones **
foreach var in shrfspTotal shrfspGobFed shrfspOyE shrfspBanca {
	** Monto año actual **
	local monto_abs = abs(``var'_hoy_nom')
	if `monto_abs' >= 1000000000000 {
		local `var'_monto_str = string(``var'_hoy_nom'/1000000000000, "%10.2fc") + " bdp"
	}
	else {
		local `var'_monto_str = string(``var'_hoy_nom'/1000000, "%12.1fc") + " mdp"
	}

	** Monto año anterior (nominal) **
	local monto_ant_abs = abs(``var'_ant_nom')
	if `monto_ant_abs' >= 1000000000000 {
		local `var'_monto_ant_str = string(``var'_ant_nom'/1000000000000, "%10.2fc") + " bdp"
	}
	else {
		local `var'_monto_ant_str = string(``var'_ant_nom'/1000000, "%12.1fc") + " mdp"
	}

	if ``var'_var_interanual' >= 0 {
		local `var'_interanual_str = "+ " + string(``var'_var_interanual', "%4.1fc") + " %"
	}
	else {
		local `var'_interanual_str = "- " + string(abs(``var'_var_interanual'), "%4.1fc") + " %"
	}
}

** 17.2 Desplegar tarjeta **
** Colores: amarillo (in y) = datos dinámicos, verde (in g) = etiquetas fijas **
noisily di _newline(5)
noisily di in g _dup(80) "="
noisily di in g "{bf:  TARJETA INFORMATIVA: SALDO HIST{c O'}RICO DE LOS RFSP}"
noisily di in y "{bf:  Informaci{c o'}n a `sh_mesname' `sh_last_anio'}"
noisily di in g _dup(80) "="
noisily di ""
noisily di in g "  {bf:SHRFSP}"
noisily di ""
noisily di in y "  {bf:`shrfspTotal_interanual_str'}"
noisily di ""
noisily di in g _dup(40) "." _col(45) _dup(15) "."
noisily di ""
noisily di _col(45) in g "Gob. Federal" _col(65) in y "{bf:`shrfspGobFed_interanual_str'}"
noisily di ""
noisily di in g _dup(40) " " _col(45) _dup(15) "- "
noisily di ""
noisily di _col(45) in g "Org. y Empresas" _col(65) in y "{bf:`shrfspOyE_interanual_str'}"
noisily di ""
noisily di in g _dup(40) " " _col(45) _dup(15) "- "
noisily di ""
noisily di _col(45) in g "Banca de Des." _col(65) in y "{bf:`shrfspBanca_interanual_str'}"
noisily di ""
noisily di in g "  {it:Crecimiento real respecto al saldo de `sh_mesname' `sh_anio_ant'.}"
noisily di ""
noisily di in g _dup(80) "."
noisily di ""
noisily di in y _col(10) "$ `shrfspTotal_monto_ant_str'" _col(45) in y "$ `shrfspTotal_monto_str'"
noisily di in g _col(10) "(`sh_mesname' `sh_anio_ant')" _col(45) in g "(`sh_mesname' `sh_last_anio')"
noisily di ""
noisily di in g _dup(80) "="
noisily di ""
