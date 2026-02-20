****
**** SIMULADOR FISCAL CIEP
**** Ricardo Cantú Calderón
**** ricardocantu@ciep.mx
**** 24 de septiembre de 2025
****
clear all
macro drop _all
capture log close _all
timer on 1



***
**# 0. SET UP
***

** 0.1 Directorios de trabajo (uno por computadora)
if "`c(username)'" == "ricardo" {						// Mac
	sysdir set SITE "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/"
}
else {
	sysdir set SITE "/SIM/OUT/7/"
}
cd "`c(sysdir_site)'/users/$id"


** Parámetros iniciales
scalar aniovp = 2026								// ANIO VALOR PRESENTE
scalar anioPE = 2026								// ANIO PAQUETE ECONÓMICO
scalar anioenigh = 2024								// ANIO ENIGH

global id = "{{idSession}}"							// IDENTIFICADOR DEL USUARIO
global paqueteEconomico "CGPE 2026"						// POLÍTICA FISCAL

** Opciones
global nographs "nographs"							// SUPRIMIR GRAFICAS
global output "output"								// ARCHIVO DE SALIDA (WEB)

if "$output" != "" {
	capture mkdir "`c(sysdir_site)'/users/$id"
	quietly log using `"`c(sysdir_site)'/users/$id/output.txt"', replace text name(output)
	quietly log off output
}



**/
**# 2. ECONOMÍA
***
global pib2025 = {{CRECPIB2025}}
global pib2026 = {{CRECPIB2026}}
global pib2027 = {{CRECPIB2027}}
global pib2028 = {{CRECPIB2028}}
global pib2029 = {{CRECPIB2029}}
global pib2030 = {{CRECPIB2030}}
global pib2031 = {{CRECPIB2031}}

global def2025 = {{CRECDEF2025}}
global def2026 = {{CRECDEF2026}}
global def2027 = {{CRECDEF2027}}
global def2028 = {{CRECDEF2028}}
global def2029 = {{CRECDEF2029}}
global def2030 = {{CRECDEF2030}}
global def2031 = {{CRECDEF2031}}

global inf2025 = 3.5								// CRECIMIENTO ANUAL INFLACIÓN
global inf2026 = 3.0								// <-- AGREGAR O QUITAR AÑOS
global inf2027 = 3.0
global inf2028 = 3.0
global inf2029 = 3.0
global inf2030 = 3.0
global inf2031 = 3.0



**/
**# 3. SISTEMA FISCAL
***

** 3.1 Ley de Ingresos de la Federación
noisily LIF if divLIF != 10, anio(`=anioPE') by(divSIM) $update 		///
	title("Ingresos presupuestarios") 					/// Cambiar título
	desde(2021) 							/// Año de inicio PROMEDIO
	min(0) 									/// Mínimo 0% del PIB (no negativo)
	rows(1)									//  Número de filas en la leyenda
rename divSIM divCODE
decode divCODE, g(divSIM) 
collapse (sum) recaudacion, by(anio divSIM) fast
save `"`c(sysdir_site)'/users/$id/LIF.dta"', replace	


** 3.1.1 Parámetros: Ingresos **
scalar ISRASPIB       = "{{INGRESOS0}}"				// ISR (asalariados)
scalar ISRPFPIB       = "{{INGRESOS1}}"				// ISR (personas f{c i'}sicas)
scalar CUOTASPIB      = "{{INGRESOS2}}"				// Cuotas (IMSS)

scalar ISRPMPIB       = "{{INGRESOS4}}"				// ISR (personas morales)
scalar OTROSKPIB      = "{{INGRESOS5}}"				// Productos, derechos, aprovech.

scalar FMPPIB         = "{{INGRESOS15}}"			// Fondo Mexicano del Petróleo
scalar PEMEXPIB       = "{{INGRESOS16}}"			// Organismos y empresas (Pemex)
scalar CFEPIB         = "{{INGRESOS17}}"			// Organismos y empresas (CFE)
scalar IMSSPIB        = "{{INGRESOS13}}"			// Organismos y empresas (IMSS)
scalar ISSSTEPIB      = "{{INGRESOS14}}"			// Organismos y empresas (ISSSTE)

scalar IVAPIB         = "{{INGRESOS7}}"				// IVA
scalar ISANPIB        = "{{INGRESOS8}}"				// ISAN
scalar IEPSNPPIB      = "{{INGRESOS9}}"				// IEPS (no petrolero)
scalar IEPSPPIB       = "{{INGRESOS10}}"			// IEPS (petrolero)
scalar IMPORTPIB      = "{{INGRESOS11}}"			// Importaciones


** 3.1.2 Parámetros: ISR **
* Anexo 8 de la Resolución Miscelánea Fiscal para 2024 *
* Tarifa para el cálculo del impuesto correspondiente al ejericio 2024 a que se refieren los artículos 97 y 152 de la Ley del ISR
* Tabla del subsidio para el empleo aplicable a la tarifa del numeral 5 del rubro B (página 773) *
*             INFERIOR		SUPERIOR	CF		TASA
matrix ISR =  (0.01,		8952.49,	0.0,		{{ISRTASA0}}	\    /// 1
	8952.49    +.01,	75984.55,	171.88,		{{ISRTASA1}}	\    /// 2
	75984.55   +.01,	133536.07,	4461.94,	{{ISRTASA2}}	\    /// 3
	133536.07  +.01,	155229.80,	10723.55,	{{ISRTASA3}}	\    /// 4
	155229.80  +.01,	185852.57,	14194.54,	{{ISRTASA4}}	\    /// 5
	185852.57  +.01,	374837.88,	19682.13,	{{ISRTASA5}}	\    /// 6
	374837.88  +.01,	590795.99,	60049.40,	{{ISRTASA6}}	\    /// 7
	590795.99  +.01,	1127926.84,	110842.74,	{{ISRTASA7}}	\    /// 8
	1127926.84 +.01,	1503902.46,	271981.99,	{{ISRTASA8}}	\    /// 9
	1503902.46 +.01,	4511707.37,	392294.17,	{{ISRTASA9}}	\    /// 10
	4511707.37 +.01,	1E+12,		1414947.85,	{{ISRTASA10}})	     //  11

*             INFERIOR		SUPERIOR	SUBSIDIO
matrix	SE =  (0.01,		1768.96*12,	{{SE0}}			\    /// 1
	1768.96*12 +.01,	2653.38*12,	{{SE1}}		\    /// 2
	2653.38*12 +.01,	3472.84*12,	{{SE2}}		\    /// 3
	3472.84*12 +.01,	3537.87*12,	{{SE3}}		\    /// 4
	3537.87*12 +.01,	4446.15*12,	{{SE4}}		\    /// 5
	4446.15*12 +.01,	4717.18*12,	{{SE5}}		\    /// 6
	4717.18*12 +.01,	5335.42*12,	{{SE6}}		\    /// 7
	5335.42*12 +.01,	6224.67*12,	{{SE7}}		\    /// 8
	6224.67*12 +.01,	7113.90*12,	{{SE8}}		\    /// 9
	7113.90*12 +.01,	7382.33*12,	{{SE9}}		\    /// 10
	7382.33*12 +.01,  	1E+12*12,	{{SE10}})	 /// 11

* Artículo 151, último párrafo (LISR) *
*            Ex. SS.MM.	Ex. 	% ing. gravable		% Informalidad PF	% Informalidad Salarios
matrix	DED	= 	({{DED0}},	{{DED1}}, 	{{DED2}}, 		{{DED3}})

* Artículo 9, primer párrafo (LISR) * 
*           Tasa ISR PM.	% Informalidad PM
matrix PM	= ({{ISRMORA0}},	{{ISRMORA1}})


** 3.1.3 Parámetros: IMSS e ISSSTE **
* Informe al Ejecutivo Federal y al Congreso de la Unión la situación financiera y los riesgos del IMSS 2021-2022 *
* Anexo A, Cuadro A.4 *
matrix CSS_IMSS = ///
///	PATRONES		TRABAJADORES			GOBIERNO FEDERAL
	({{CSSIMSS0}},		{{CSSIMSS1}},			{{CSSIMSS2}}	\   /// Enfermedad y maternidad, asegurados (Tgmasg*)
	{{CSSIMSS3}},		{{CSSIMSS4}},			{{CSSIMSS5}}	\   /// Enfermedad y maternidad, pensionados (Tgmpen*)
	{{CSSIMSS6}},		{{CSSIMSS7}},			{{CSSIMSS8}}	\   /// Invalidez y vida (Tinvyvida*)
	{{CSSIMSS9}},		{{CSSIMSS10}},			{{CSSIMSS11}}	\   /// Riesgos de trabajo (Triesgo*)
	{{CSSIMSS12}},		{{CSSIMSS13}},			{{CSSIMSS14}}	\   /// Guarderias y prestaciones sociales (Tguard*)
	{{CSSIMSS15}},		{{CSSIMSS16}},			{{CSSIMSS17}}	\   /// Retiro, cesantia en edad avanzada y vejez (Tcestyvej*)
	{{CSSIMSS18}},		{{CSSIMSS19}},			{{CSSIMSS20}})	    //  Cuota social -- hasta 25 UMA -- (TcuotaSocIMSS*)

* Informe Financiero Actuarial ISSSTE 2021 *
matrix CSS_ISSSTE = ///
///	PATRONES		TRABAJADORES			GOBIERNO FEDERAL
	({{CSSISSSTE0}},	{{CSSISSSTE1}},			{{CSSISSSTE2}}	\   /// Seguro de salud, trabajadores en activo y familiares
	{{CSSISSSTE3}},		{{CSSISSSTE4}},			{{CSSISSSTE5}}	\   /// Seguro de salud, pensionados y familiares
	{{CSSISSSTE6}},		{{CSSISSSTE7}},			{{CSSISSSTE8}}	\   /// Riesgo de trabajo
	{{CSSISSSTE9}},		{{CSSISSSTE10}},		{{CSSISSSTE11}}	\   /// Invalidez y vida
	{{CSSISSSTE12}},	{{CSSISSSTE13}},		{{CSSISSSTE14}}	\   /// Servicios sociales y culturales
	{{CSSISSSTE15}},	{{CSSISSSTE16}},		{{CSSISSSTE17}}	\   /// Retiro, cesantia en edad avanzada y vejez
	{{CSSISSSTE18}},	{{CSSISSSTE19}},		{{CSSISSSTE20}}	\   /// Vivienda
	{{CSSISSSTE21}},	{{CSSISSSTE22}},		{{CSSISSSTE23}})	//  Cuota social

** 3.1.4 Parámetros: IVA **
matrix IVAT = ({{IVAT0}} \						///  1  Tasa general 
	{{IVAT1}}   \							///  2  Alimentos, input[1]: Tasa Cero, [2]: Exento, [3]: Gravado
	{{IVAT2}}  \							///  3  Alquiler, idem
	{{IVAT3}}  \							///  4  Canasta basica, idem
	{{IVAT4}}  \							///  5  Educacion, idem
	{{IVAT5}}  \							///  6  Consumo fuera del hogar, idem
	{{IVAT6}}  \							///  7  Mascotas, idem
	{{IVAT7}}  \							///  8  Medicinas, idem
	{{IVAT8}}  \							///  9  Toallas sanitarias, idem
	{{IVAT9}}  \							/// 10  Otros, idem
	{{IVAT10}}  \							/// 11  Transporte local, idem
	{{IVAT11}}  \							/// 12  Transporte foraneo, idem
	{{IVAT12}})							//  13  Evasion e informalidad IVA, input[0-100]

** 3.1.5 Parámetros: IEPS **
* Fuente: Ley del IEPS, Artículo 2.
*		Ad valorem	Específico
matrix IEPST = (26.5	,	0 		\			/// Cerveza y alcohol 14
		30.0	,	0 		\			/// Alcohol 14+ a 20
		53.0	,	0 		\			/// Alcohol 20+
		160.0	,	0.6166		\			/// Tabaco y cigarros
		30.0	,	0 		\			/// Juegos y sorteos
		3.0	,	0 		\			/// Telecomunicaciones
		25.0	,	0 		\			/// Bebidas energéticas
		0	,	1.5737		\			/// Bebidas saborizadas
		8.0	,	0 		\			/// Alto contenido calórico
		0	,	10.7037		\			/// Gas licuado de petróleo (propano y butano)
		0	,	21.1956		\			/// Combustibles (petróleo)
		0	,	19.8607		\			/// Combustibles (diésel)
		0	,	43.4269		\			/// Combustibles (carbón)
		0	,	21.1956		\			/// Combustibles (combustible para calentar)
		0	,	6.1752		\			/// Gasolina: magna
		0	,	5.2146		\			/// Gasolina: premium
		0	,	6.7865		)			// Gasolina: diésel

** 3.1.6 Submódulo ISR (web) **/
if "1" == "{{moduloCambio}}" {
	noisily run "`c(sysdir_site)'/ISR_Mod.do"
	scalar ISRAS = ISR_AS_Mod/100*scalar(pibY)
	scalar ISRASPIB  = "`=round(ISR_AS_Mod, 0.001)'"			// NUEVA ESTIMACIÓN ISR ASALARIADOS
	scalar ISRPF = ISR_PF_Mod/100*scalar(pibY)
	scalar ISRPFPIB  = "`=round(ISR_PF_Mod, 0.001)'"			// NUEVA ESTIMACIÓN ISR P. FÍSICAS
	scalar ISRPM = ISR_PM_Mod/100*scalar(pibY)
	scalar ISRPMPIB  = "`=round(ISR_PM_Mod, 0.001)'"			// NUEVA ESTIMACIÓN ISR P. MORALES
	scalar CUOTAS = CUOTAS_Mod/100*scalar(pibY)
	scalar CUOTASPIB = "`=round(CUOTAS_Mod, 0.001)'"			// NUEVA ESTIMACIÓN CUOTAS IMSS
}
** 3.1.7 Submódulo IVA (web) **
if "1" == "{{moduloCambioIva}}" {
	noisily run "`c(sysdir_site)'/IVA_Mod.do"
	scalar IVA = IVA_Mod/100*scalar(pibY)
	scalar IVAPIB = "`=round(IVA_Mod, 0.001)'"				// NUEVA ESTIMACIÓN IVA
}

** 3.1.8 Tasas Efectivas **/
noisily TasasEfectivas, anio(`=anioPE') enigh




**/
** 3.2 Presupuesto de Egresos de la Federación **
**

** 3.2.1 Parámetros: Gasto **
scalar iniciaA     = {{iniciaA}} 				//    Inicial
scalar basica      = {{basica}} 				//    Educación b{c a'}sica
scalar medsup      = {{medsup}} 				//    Educación media superior
scalar superi      = {{superi}} 				//    Educación superior
scalar posgra      = {{posgra}} 				//    Posgrado
scalar eduadu      = {{eduadu}} 				//    Educación para adultos
scalar otrose      = {{otrose}} 				//    Otros gastos educativos
scalar invere      = {{invere}} 				//    Inversión en educación
scalar cultur      = {{cultur}} 				//    Cultura, deportes y recreación
scalar invest      = {{invest}} 				//    Ciencia y tecnología

** 2.3 Parámetros: Salud **
scalar ssa         = {{ssa}}					//    SSalud
scalar imssbien    = {{imssbien}}				//    IMSS-Bienestar
scalar imss        = {{imss}}					//    IMSS (salud)
scalar issste      = {{issste}}					//    ISSSTE (salud)
scalar pemex       = {{pemex}}					//    Pemex (salud)
scalar issfam      = {{issfam}}					//    ISSFAM (salud)
scalar invers      = {{invers}}					//    Inversión en salud

** 2.4 Parámetros: Pensiones **
scalar pam         = {{bienestar}}				//    Pensión Bienestar
scalar penimss     = {{penims}}					//    Pensión IMSS
scalar penisss     = {{peniss}}					//    Pensión ISSSTE
scalar penpeme     = {{penpeme}}				//    Pensión Pemex
scalar penotro     = {{penotr}}					//    Pensión CFE, LFC, ISSFAM, Ferronales

** 2.5 Parámetros: Energía **
scalar gascfe      = {{gascfe}}					//    Gasto en CFE 
scalar gaspemex    = {{gaspemex}}				//    Gasto en Pemex 
scalar gassener    = {{gassener}}				//    Gasto en SENER 
scalar gasinverf   = {{gasinverf}}				//    Gasto en inversión (energía)
scalar gascosdeue  = {{gascosdeue}}				//    Gasto en costo de la deuda (energía)

** 2.6 Parámetros: Otros gastos **
scalar gasinfra    = {{gasinfra}}				//    Gasto en Inversión 
scalar gasotros    = {{gasotros}}				//    Otros gastos 
scalar gasfeder    = {{gasfeder}}				//    Participaciones y Otras aportaciones 
scalar gascosto    = {{gascosto}}				//    Gasto en Costo de la deuda

** 2.7 Parámetros: Transferencas **
scalar IngBas      = {{IngBas}}					//    Ingreso b{c a'}sico
scalar ingbasico18 = {{ingbasico18}}				//    1: Incluye menores de 18 anios, 0: no
scalar ingbasico65 = {{ingbasico65}}				//    1: Incluye mayores de 65 anios, 0: no
scalar gasmadres   = {{gasmadres}}				//    Apoyo a madres trabajadoras
scalar gascuidados = {{gascuidados}}				//    Gasto en cuidados


** 3.2.2 Gasto per cápita **/
noisily GastoPC educacion salud pensiones energia resto transferencias, aniope(`=anioPE') aniovp(`=aniovp')



**/
** 3.3 Saldo Histórico de Requerimientos Financieros del Sector Público **
**

* SHRFSP: Total, Interno, Externo (como % del PIB)
*                	2025  2026  2027  2028  2029  2030  2031
matrix shrfsp = 	(52.3, 52.3, 52.3, 52.3, 52.3, 52.3, 52.3)
matrix shrfspInterno = 	(40.2, 41.3, 42.1, 42.5, 42.8, 43.2, 43.5)
matrix shrfspExterno = 	(12.1, 11.0, 10.2, 9.8, 9.5, 9.1, 8.8)
* SHRFSP:      Total, PIDIREGAS, IPAB, FONADIN, Deudores, Banca, Adecuaciones, Balance (como % del PIB)
matrix rfsp =  (4.3, 0.15, 0.15, 0.00, 0.00, 0.00, 0.40, 3.6 \ 		/// 2025
		4.1, 0.10, 0.10, 0.00, 0.00, 0.00, 0.30, 3.6 \ 		/// 2026
		3.5, 0.10, 0.10, 0.00,-0.10, 0.00, 0.40, 3.0 \ 		/// 2027
		3.0, 0.10, 0.10, 0.00, 0.00, 0.00, 0.30, 2.5 \ 		/// 2028
		3.0, 0.10, 0.10, 0.00, 0.00, 0.00, 0.30, 2.5 \ 		/// 2029
		3.0, 0.10, 0.10,-0.10, 0.00, 0.00, 0.40, 2.5 \ 		/// 2030
		3.0, 0.10, 0.10, 0.00, 0.00, 0.00, 0.30, 2.5) 		// 2031
* SHRFSP: Tipo de cambio (MXN/USD)
*                      2025, 2026, 2027, 2028, 2029, 2030, 2031
matrix tipoDeCambio = (19.6, 18.9, 18.2, 18.2, 18.2, 18.3, 18.3)
* Balance primario (como % del PIB)
*                     2025, 2026, 2027, 2028, 2029, 2030, 2031
matrix balprimario = (-0.2, -0.5, -0.8, -0.8, -0.8, -0.8, -0.6)
* Costo de la deuda (como % del PIB)
*                   2025, 2026, 2027, 2028, 2029, 2030, 2031
matrix costodeuda = (3.8,  4.1,  3.8,  3.4,  3.3,  3.3,  3.1)
* Ingresos (como % del PIB)
*                     2025, 2026, 2027, 2028, 2029, 2030, 2031
matrix ingresos = (21.9,  22.5,  22.4,  22.4,  22.4,  22.4,  22.4)
* Gastos (como % del PIB)
*                     2025, 2026, 2027, 2028, 2029, 2030, 2031
matrix egresos = (25.5,  26.1,  25.4,  24.9,  24.9,  24.9,  24.9)

forvalues k = 2025(1)2031 {
	local j = `k' - 2025 + 1
	global shrfsp`k' = shrfsp[1,`j']
	global shrfspInterno`k' = shrfspInterno[1,`j']
	global shrfspExterno`k' = shrfspExterno[1,`j']
	global rfsp`k' = rfsp[`j',1]
	global rfspPIDIREGAS`k' = rfsp[`j',2]
	global rfspIPAB`k' = rfsp[`j',3]
	global rfspFONADIN`k' = rfsp[`j',4]
	global rfspDeudores`k' = rfsp[`j',5]
	global rfspBanca`k' = rfsp[`j',6]
	global rfspAdecuaciones`k' = rfsp[`j',7]
	global rfspBalance`k' = rfsp[`j',8]
	global tipoDeCambio`k' = tipoDeCambio[1,`j']
	global balprimario`k' = balprimario[1,`j']
	global costodeuda`k' = costodeuda[1,`j']
	global ingresos`k' = ingresos[1,`j']
	global egresos`k' = egresos[1,`j']
}


** 3.3.2 SHRFSP **/
scalar tasaEfectiva = {{DEUDA0}}
//noisily SHRFSP, anio(`=anioPE') ultanio(2008) $update $textbook $nographs



**/
**# 6. CICLO DE VIDA
***
use `"`c(sysdir_site)'/users/$id/ingresos.dta"', clear
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/gastos.dta", nogen
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/isr_mod.dta", ///
	nogen replace update keepus(ISRAS_Sim ISRPF_Sim ISRPM_Sim CUOTAS_Sim)
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/iva_mod.dta", ///
	nogen replace update keepus(IVA_Sim)
save `"`c(sysdir_site)'/users/$id/aportaciones.dta"', replace


** 7.1 (+) Impuestos y aportaciones
egen AlTrabajo = rsum(ISRPF_Sim ISRAS_Sim CUOTAS_Sim)
egen AlCapital = rsum(ISRPM_Sim OTROSK)
egen AlConsumo = rsum(IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim)

capture drop ImpuestosAportaciones
egen ImpuestosAportaciones = rsum(ISRPM_Sim ISRAS_Sim ISRPF_Sim CUOTAS_Sim IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim) // FMP_Sim OTROSK_Sim

** 7.2 (-) Gastos
replace Pensiones = Pensiones + Pensión_AM
capture drop Transferencias
egen Transferencias = rsum(Pensiones IngBasico Educacion Salud OtrasInversiones)

** 7.3 (=) Aportaciones netas **
capture drop AportacionesNetas
g AportacionesNetas = ImpuestosAportaciones - Transferencias
label var AportacionesNetas "Ciclo de vida de las aportaciones netas"
//noisily Perfiles AportacionesNetas [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
noisily Simulador AportacionesNetas [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)
save `"`c(sysdir_site)'/users/$id/aportaciones.dta"', replace



**/
**# 7. DEUDA + FISCAL GAP + REDISTRIBUCIÓN
***

** 7.1 Brecha fiscal
noisily FiscalGap, anio(`=anioPE') end(2030) aniomin(2015) $nographs desde(2021) discount(10) //update


** 7.2 Sankey del sistema fiscal
foreach k in decil grupoedad sexo rural escol {
	noisily run "`c(sysdir_site)'/SankeySF.do" `k' `=anioPE'
}



***/
**** Touchdown!!!
****
if "$output" == "output" ///
	run "`c(sysdir_site)'/output.do"
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
