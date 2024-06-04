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


** 0.1 Rutas de archivos  **
if "`c(username)'" == "ricardo" ///                             // iMac Ricardo
	sysdir set PERSONAL "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
else if "`c(username)'" == "ciepmx" & "`c(console)'" == "" ///       // Servidor CIEP
	sysdir set PERSONAL "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
else ///														   // Web
	sysdir set PERSONAL "/SIM/OUT/6/"
cd `"`c(sysdir_personal)'"'
capture mkdir `"`c(sysdir_personal)'/users/"'
capture mkdir `"`c(sysdir_personal)'/users/$id/"'


**  0.2 Opciones globales  **
** Comentar o descomentar, según el caso. **
global id = "{{idSession}}"                                                   // IDENTIFICADOR DEL USUARIO
global nographs "nographs"                                                    // SUPRIMIR GRAFICAS
global output "output"                                                        // OUTPUTS (WEB)



***************************
***                     ***
**#    1. MARCO MACRO   ***
***                     ***
***************************
global paqueteEconomico "PE 2024"
scalar anioPE = 2024
scalar aniovp = 2024
scalar anioenigh = 2022


**  1.1 Archivo output.txt (web)  **
if "$output" != "" {
	quietly log using `"`c(sysdir_personal)'/users/$id/output.txt"', replace text name(output)
	quietly log off output
}


** 1.2 Economía **
** 1.2.1 Parámetros: Crecimiento anual del Producto Interno Bruto **
global pib2024 = {{CRECPIB2024}} // 2.6189
global pib2025 = {{CRECPIB2025}} // 2.5097
global pib2026 = {{CRECPIB2026}} // 2.4779
global pib2027 = {{CRECPIB2027}} // 2.5
global pib2028 = {{CRECPIB2028}} // 2.5
global pib2029 = {{CRECPIB2029}} // 2.5002

** 1.2.2 Parámetros: Crecimiento anual del índice de precios implícitos **
global def2024 = {{CRECDEF2024}} // 4.8
global def2025 = {{CRECDEF2025}} // 3.5
global def2026 = {{CRECDEF2026}} // 3.5
global def2027 = {{CRECDEF2027}} // 3.5
global def2028 = {{CRECDEF2028}} // 3.5
global def2029 = {{CRECDEF2029}} // 3.5

** 1.2.3 Parámetros: Crecimiento anual del índice nacional de precios al consumidor **
global inf2024 = 3.8
global inf2025 = 3.3
global inf2026 = 3.0
global inf2027 = 3.0
global inf2028 = 3.0
global inf2029 = 3.0

scalar tasaEfectiva = {{DEUDA0}} // 6.7358

** 1.3 Perfiles **
capture confirm file "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta"
if _rc != 0 ///
	noisily run `"`c(sysdir_personal)'/PerfilesSim.do"' `=anioPE'



*********************************/
***                            ***
**#    2. MÓDULOS SIMULADOR    ***
***                            ***
**********************************

** 2.1 Parámetros: Ingresos **
scalar ISRAS       =   {{INGRESOS0}} // *(1+ r(EISRAS)*(${pib2023}-${pib2023_0})/100)) 		// ISR (asalariados)
scalar ISRPF       =   {{INGRESOS1}} // *(1+ r(EISRPF)*(${pib2023}-${pib2023_0})/100)) 		// ISR (personas f{c i'}sicas)
scalar CUOTAS      =   {{INGRESOS2}} // *(1+ r(ECUOTAS)*(${pib2023}-${pib2023_0})/100)) 	// Cuotas (IMSS)

scalar FMP         =   {{INGRESOS15}} // *(1+ r(EFMP)*(${pib2023}-${pib2023_0})/100)) 		// Fondo Mexicano del Petróleo
scalar PEMEX       =   {{INGRESOS16}} // *(1+ r(EPEMEX)*(${pib2023}-${pib2023_0})/100)) 		// Organismos y empresas (Pemex)
scalar CFE         =   {{INGRESOS17}} // *(1+ r(ECFE)*(${pib2023}-${pib2023_0})/100)) 		// Organismos y empresas (CFE)
scalar IMSS        =   {{INGRESOS13}} // *(1+ r(EIMSS)*(${pib2023}-${pib2023_0})/100)) 		// Organismos y empresas (IMSS)
scalar ISSSTE      =   {{INGRESOS14}} // *(1+ r(EISSSTE)*(${pib2023}-${pib2023_0})/100)) 	// Organismos y empresas (ISSSTE)

scalar ISRPM       =   {{INGRESOS4}} // *(1+ r(EISRPM)*(${pib2023}-${pib2023_0})/100)) 		// ISR (personas morales)
scalar OTROSK      =   {{INGRESOS5}} // *(1+ r(EOTROSK)*(${pib2023}-${pib2023_0})/100)) 	// Productos, derechos, aprovech.

scalar IVA         =   {{INGRESOS7}} // *(1+ r(EIVA)*(${pib2023}-${pib2023_0})/100)) 		// IVA
scalar ISAN        =   {{INGRESOS8}} // *(1+ r(EISAN)*(${pib2023}-${pib2023_0})/100)) 		// ISAN
scalar IEPSNP      =   {{INGRESOS9}} // *(1+ r(EIEPSNP)*(${pib2023}-${pib2023_0})/100))		// IEPS (no petrolero)
scalar IEPSP       =   {{INGRESOS10}} // IEPS (petrolero): 0.662
scalar IMPORT      =   {{INGRESOS11}} // *(1+ r(EIMPORT)*(${pib2023}-${pib2023_0})/100))		// Importaciones


** 2.2 Parámetros: Educación **
scalar iniciaA     =   {{iniciaA}} //    Inicial
scalar basica      =   {{basica}} //    Educación b{c a'}sica
scalar medsup      =   {{medsup}} //    Educación media superior
scalar superi      =   {{superi}} //    Educación superior
scalar posgra      =   {{posgra}} //    Posgrado
scalar eduadu      =   {{eduadu}} //    Educación para adultos
scalar otrose      =   {{otrose}} //    Otros gastos educativos
scalar invere      =   {{invere}} //    Inversión en educación
scalar cultur      =   {{cultur}} //    Cultura, deportes y recreación
scalar invest      =   {{invest}} //    Ciencia y tecnología


** 2.3 Parámetros: Salud **
scalar ssa         =   {{ssa}}       //    SSalud
scalar imssbien    =   {{imssbien}}  //    IMSS-Bienestar
scalar imss        =   {{imss}}      //    IMSS (salud)
scalar issste      =   {{issste}}    //    ISSSTE (salud)
scalar pemex       =   {{pemex}}     //    Pemex (salud)
scalar issfam      =   {{issfam}}         //    ISSFAM (salud)
scalar invers      =   {{invers}}           //    Inversión en salud


** 2.4 Parámetros: Pensiones **
scalar pam         = {{bienestar}} //    Pensión Bienestar
scalar penimss     = {{penims}}    //    Pensión IMSS
scalar penisss     = {{peniss}}    //    Pensión ISSSTE
scalar penpeme     = {{penpeme}}       //    Pensión Pemex
scalar penotro     = {{penotr}}    //    Pensión CFE, LFC, ISSFAM, Ferronales


** 2.5 Parámetros: Energía **
scalar gascfe      =   {{gascfe}}   //    Gasto en CFE 
scalar gaspemex    =   {{gaspemex}} //    Gasto en Pemex 
scalar gassener    =   {{gassener}} //    Gasto en SENER 
scalar gasinverf   =   {{gasinverf}} //    Gasto en inversión (energía)
scalar gascosdeue  =   {{gascosdeue}} //    Gasto en costo de la deuda (energía)


** 2.6 Parámetros: Otros gastos **
scalar gasinfra    =   {{gasinfra}} //    Gasto en Inversión 
scalar gasotros    =   {{gasotros}} //    Otros gastos 
scalar gasfeder    =   {{gasfeder}} //    Participaciones y Otras aportaciones 
scalar gascosto    =   {{gascosto}} //    Gasto en Costo de la deuda


** 2.7 Parámetros: Transferencas **
scalar IngBas      =       {{IngBas}} //    Ingreso b{c a'}sico
scalar ingbasico18 =       {{ingbasico18}} //    1: Incluye menores de 18 anios, 0: no
scalar ingbasico65 =       {{ingbasico65}} //    1: Incluye mayores de 65 anios, 0: no
scalar gasmadres   =     {{gasmadres}} //    Apoyo a madres trabajadoras
scalar gascuidados =    {{gascuidados}} //    Gasto en cuidados


** 2.8 Parámetros: ISR **
** Inputs: Archivo "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta" o "`c(sysdir_site)'/users/$pais/$id/households.dta"
** Outputs: Archivo "`c(sysdir_site)'/users/$pais/$id/households.dta" actualizado más scalars ISRAS, ISRPF, ISRPM y CUOTAS.
* Anexo 8 de la Resolución Miscelánea Fiscal para 2023 *
* Tarifa para el cálculo del impuesto correspondiente al ejericio 2023 (página 782) *
*             INFERIOR			SUPERIOR	CF		TASA
matrix ISR =  (0.01,			8952.49,	0.0,		{{ISRTASA0}}	\    /// 1
			8952.49    +.01,	75984.55,	171.88,		{{ISRTASA1}}	\    /// 2
			75984.55   +.01,	133536.07,	4461.94,	{{ISRTASA2}}	\    /// 3
			133536.07  +.01,	155229.80,	10723.55,	{{ISRTASA3}}	\    /// 4
			155229.80  +.01,	185852.57,	14194.54,	{{ISRTASA4}}	\    /// 5
			185852.57  +.01,	374837.88,	19682.13,	{{ISRTASA5}}	\    /// 6
			374837.88  +.01,	590795.99,	60049.40,	{{ISRTASA6}}	\    /// 7
			590795.99  +.01,	1127926.84,	110842.74,	{{ISRTASA7}}	\    /// 8
			1127926.84 +.01,	1503902.46,	271981.99,	{{ISRTASA8}}	\    /// 9
			1503902.46 +.01,	3511707.37,	392294.17,	{{ISRTASA9}}	\    /// 10
			3511707.37 +.01,	1E+12,		1414947.85,	{{ISRTASA10}})	     //  11

* Tabla del subsidio para el empleo aplicable a la tarifa del numeral 5 del rubro B (página 773) *
*             INFERIOR			SUPERIOR	SUBSIDIO
matrix	SE =  (0.01,			1768.96*12,	{{SE0}}		\    /// 1
			1768.96*12 +.01,	2653.38*12,	{{SE1}}		\    /// 2
			2653.38*12 +.01,	3472.84*12,	{{SE2}}		\    /// 3
			3472.84*12 +.01,	3537.87*12,	{{SE3}}		\    /// 4
			3537.87*12 +.01,	4446.15*12,	{{SE4}}		\    /// 5
			4446.15*12 +.01,	4717.18*12,	{{SE5}}		\    /// 6
			4717.18*12 +.01,	5335.42*12,	{{SE6}}		\    /// 7
			5335.42*12 +.01,	6224.67*12,	{{SE7}}		\    /// 8
			6224.67*12 +.01,	7113.90*12,	{{SE8}}		\    /// 9
			7113.90*12 +.01,	7382.33*12,	{{SE9}}		\    /// 10
			7382.33*12 +.01,  	1E+12*12,	{{SE10}})		 /// 11

* Artículo 151, último párrafo (LISR) *
*            Ex. SS.MM.	Ex. 	% ing. gravable		% Informalidad PF	% Informalidad Salarios
matrix	DED	= 	({{DED0}},	{{DED1}}, 		{{DED2}}, 		{{DED3}})

* Artículo 9, primer párrafo (LISR) * 
*           Tasa ISR PM.	% Informalidad PM
matrix PM	= (	{{ISRMORA0}},	{{ISRMORA1}})


** 2.9 Parámetros: IMSS e ISSSTE **
* Informe al Ejecutivo Federal y al Congreso de la Unión la situación financiera y los riesgos del IMSS 2021-2022 *
* Anexo A, Cuadro A.4 *
matrix CSS_IMSS = ///
///		PATRONES			TRABAJADORES			GOBIERNO FEDERAL
		({{CSSIMSS0}},		{{CSSIMSS1}},			{{CSSIMSS2}}	\   /// Enfermedad y maternidad, asegurados (Tgmasg*)
		{{CSSIMSS3}},		{{CSSIMSS4}},			{{CSSIMSS5}}	\   /// Enfermedad y maternidad, pensionados (Tgmpen*)
		{{CSSIMSS6}},		{{CSSIMSS7}},			{{CSSIMSS8}}	\   /// Invalidez y vida (Tinvyvida*)
		{{CSSIMSS9}},		{{CSSIMSS10}},			{{CSSIMSS11}}	\   /// Riesgos de trabajo (Triesgo*)
		{{CSSIMSS12}},		{{CSSIMSS13}},			{{CSSIMSS14}}	\   /// Guarderias y prestaciones sociales (Tguard*)
		{{CSSIMSS15}},		{{CSSIMSS16}},			{{CSSIMSS17}}	\   /// Retiro, cesantia en edad avanzada y vejez (Tcestyvej*)
		{{CSSIMSS18}},		{{CSSIMSS19}},			{{CSSIMSS20}})	    //  Cuota social -- hasta 25 UMA -- (TcuotaSocIMSS*)

* Informe Financiero Actuarial ISSSTE 2021 *
matrix CSS_ISSSTE = ///
///		PATRONES			TRABAJADORES			GOBIERNO FEDERAL
		({{CSSISSSTE0}},	{{CSSISSSTE1}},			{{CSSISSSTE2}}	\   /// Seguro de salud, trabajadores en activo y familiares (Tfondomed* / TCuotaSocISSTEF)
		{{CSSISSSTE3}},		{{CSSISSSTE4}},			{{CSSISSSTE5}}	\   /// Seguro de salud, pensionados y familiares (Tpensjub*)
		{{CSSISSSTE6}},		{{CSSISSSTE7}},			{{CSSISSSTE8}}	\   /// Riesgo de trabajo
		{{CSSISSSTE9}},		{{CSSISSSTE10}},		{{CSSISSSTE11}}	\   /// Invalidez y vida
		{{CSSISSSTE12}},	{{CSSISSSTE13}},		{{CSSISSSTE14}}	\   /// Servicios sociales y culturales
		{{CSSISSSTE15}},	{{CSSISSSTE16}},		{{CSSISSSTE17}}	\   /// Retiro, cesantia en edad avanzada y vejez
		{{CSSISSSTE18}},	{{CSSISSSTE19}},		{{CSSISSSTE20}}	\   /// Vivienda
		{{CSSISSSTE21}},	{{CSSISSSTE22}},		{{CSSISSSTE23}})	//  Cuota social

if "1" == "{{moduloCambio}}" {
	noisily run "ISR_Mod.do"
	scalar ISRAS  = ISR_AS_Mod
	scalar ISRPF  = ISR_PF_Mod
	scalar ISRPM  = ISR_PM_Mod
	scalar CUOTAS = CUOTAS_Mod
}


** 2.10 Parámetros: IVA **
* Inputs: Archivo "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta" o "`c(sysdir_site)'/users/$pais/$id/households.dta"
* Outputs: Archivo "`c(sysdir_site)'/users/$pais/$id/households.dta" actualizado más scalar IVA.
matrix IVAT = ({{IVAT0}} \     ///  1  Tasa general 
	{{IVAT1}}   \     ///  2  Alimentos, input[1]: Tasa Cero, [2]: Exento, [3]: Gravado
	{{IVAT2}}  \     ///  3  Alquiler, idem
	{{IVAT3}}  \     ///  4  Canasta basica, idem
	{{IVAT4}}  \     ///  5  Educacion, idem
	{{IVAT5}}  \     ///  6  Consumo fuera del hogar, idem
	{{IVAT6}}  \     ///  7  Mascotas, idem
	{{IVAT7}}  \     ///  8  Medicinas, idem
	{{IVAT8}}  \     ///  9  Toallas sanitarias, idem
	{{IVAT9}}  \     /// 10  Otros, idem
	{{IVAT10}}  \     /// 11  Transporte local, idem
	{{IVAT11}}  \     /// 12  Transporte foraneo, idem
	{{IVAT12}})   //  13  Evasion e informalidad IVA, input[0-100]

if "1" == "{{moduloCambioIva}}" {
	noisily run "`c(sysdir_personal)'/IVA_Mod.do"
	scalar IVA = IVA_Mod
}


** 2.11 Parámetros: IEPS **
* Inputs: Archivo "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta" o "`c(sysdir_site)'/users/$pais/$id/households.dta"
* Outputs: Archivo "`c(sysdir_site)'/users/$pais/$id/households.dta" actualizado más scalar IEPS.
* Fuente: Ley del IEPS, Artículo 2.
*              Ad valorem		Específico
matrix IEPST = (26.5	,		0 			\ /// Cerveza y alcohol 14
				30.0	,		0 			\ /// Alcohol 14+ a 20
				53.0	,		0 			\ /// Alcohol 20+
				160.0	,		0.6166		\ /// Tabaco y cigarros
				30.0	,		0 			\ /// Juegos y sorteos
				3.0		,		0 			\ /// Telecomunicaciones
				25.0	,		0 			\ /// Bebidas energéticas
				0		,		1.5737		\ /// Bebidas saborizadas
				8.0		,		0 			\ /// Alto contenido calórico
				0		,		10.7037		\ /// Combustibles: gas licuado de petróleo (promedio propano y butano)
				0		,		21.1956		\ /// Combustibles (petróleo)
				0		,		19.8607		\ /// Combustibles (diésel)
				0		,		43.4269		\ /// Combustibles (carbón)
				0		,		21.1956		\ /// Combustibles (combustible para calentar)
				0		,		6.1752		\ /// Gasolina: magna
				0		,		5.2146		\ /// Gasolina: premium
				0		,		6.7865		) // Gasolina: diésel


** 2.12 Integración de módulos ***
noisily TasasEfectivas, anio(`=anioPE')
noisily GastoPC, aniope(`=anioPE') aniovp(2024)



*****************************/
***                        ***
**#    3. CICLO DE VIDA    ***
***                        ***
******************************
capture use `"`c(sysdir_personal)'/users/$id/ingresos.dta"', clear
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_personal)'/users/$id/gastos.dta", nogen replace update
if _rc != 0 {
	use "`c(sysdir_personal)'/SIM/perfiles`=anioPE'.dta", clear
}


** 3.1 (+) Impuestos y aportaciones **
capture drop ImpuestosAportaciones
egen ImpuestosAportaciones = rsum(ISRAS ISRPF CUOTAS ISRPM OTROSK IVA IEPSNP IEPSP ISAN IMPORT)
label var ImpuestosAportaciones "impuestos y aportaciones"


** 3.2 (-) Impuestos y aportaciones **
capture drop Transferencias
egen Transferencias = rsum(Pension Educación Salud IngBasico Pensión_AM Otras_inversiones)
label var Transferencias "transferencias públicas"


** 3.3 (=) Aportaciones netas **
capture drop AportacionesNetas
g AportacionesNetas = ImpuestosAportaciones - Transferencias
label var AportacionesNetas "aportaciones netas"
noisily Perfiles AportacionesNetas [fw=factor], reboot aniovp(2024) aniope(`=anioPE') $nographs //boot(20)


** 3.4 (*) Cuentas generacionales **
//noisily CuentasGeneracionales AportacionesNetas, anio(`=anioPE') discount(7)


** 3.5 (*) Sankey del sistema fiscal **
foreach k in decil grupoedad /*sexo rural escol*/ {
	noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `=aniovp'
}



********************************************/
***                                       ***
**#    4. PARTE IV: DEUDA + FISCAL GAP    ***
***                                       ***
*********************************************
scalar tasaEfectiva = {{DEUDA0}}

scalar shrfsp2024 = 48.8
scalar shrfspInterno2024 = 37.4
scalar shrfspExterno2024 = 11.4
scalar rfsp2024 = -5.4
scalar rfspPIDIREGAS2024 = -0.1
scalar rfspIPAB2024 = -0.1
scalar rfspFONADIN2024 = -0.1
scalar rfspDeudores2024 = 0.0
scalar rfspBanca2024 = 0.0
scalar rfspAdecuaciones2024 = -0.2
scalar rfspBalance2024 = -4.9
scalar tipoDeCambio2024 = 17.6
scalar balprimario2024 = 1.2
scalar costodeudaInterno2024 = 3.7
scalar costodeudaExterno2024 = 3.7

scalar shrfsp2025 = 48.8
scalar shrfspInterno2025 = 37.7
scalar shrfspExterno2025 = 11.2
scalar rfsp2025 = -2.6
scalar rfspPIDIREGAS2025 = -0.1
scalar rfspIPAB2025 = -0.1
scalar rfspFONADIN2025 = 0.0
scalar rfspDeudores2025 = 0.0
scalar rfspBanca2025 = 0.0
scalar rfspAdecuaciones2025 = -0.2
scalar rfspBalance2025 = -2.1
scalar tipoDeCambio2025 = 17.9
scalar balprimario2025 = -0.9
scalar costodeudaInterno2025 = 3.1
scalar costodeudaExterno2025 = 3.1

scalar shrfsp2026 = 49.4
scalar shrfspInterno2026 = 38.0
scalar shrfspExterno2026 = 10.9
scalar rfsp2026 = -2.7
scalar rfspPIDIREGAS2026 = -0.1
scalar rfspIPAB2026 = -0.1
scalar rfspFONADIN2026 = 0.0
scalar rfspDeudores2026 = 0.0
scalar rfspBanca2026 = 0.0
scalar rfspAdecuaciones2026 = -0.3
scalar rfspBalance2026 = -2.2
scalar tipoDeCambio2026 = 18.1
scalar balprimario2026 = -0.5
scalar costodeudaInterno2026 = 2.7
scalar costodeudaExterno2026 = 2.7

scalar shrfsp2027 = 48.8
scalar shrfspInterno2027 = 38.3
scalar shrfspExterno2027 = 10.6
scalar rfsp2027 = -2.7
scalar rfspPIDIREGAS2027 = -0.1
scalar rfspIPAB2027 = -0.1
scalar rfspFONADIN2027 = 0.0
scalar rfspDeudores2027 = 0.1
scalar rfspBanca2027 = 0.0
scalar rfspAdecuaciones2027 = -0.4
scalar rfspBalance2027 = -2.2
scalar tipoDeCambio2027 = 18.2
scalar balprimario2027 = -0.3
scalar costodeudaInterno2027 = 2.5
scalar costodeudaExterno2027 = 2.5

scalar shrfsp2028 = 48.8
scalar shrfspInterno2028 = 38.6
scalar shrfspExterno2028 = 10.3
scalar rfsp2028 = -2.7
scalar rfspPIDIREGAS2028 = -0.1
scalar rfspIPAB2028 = -0.1
scalar rfspFONADIN2028 = 0.1
scalar rfspDeudores2028 = 0.0
scalar rfspBanca2028 = 0.0
scalar rfspAdecuaciones2028 = -0.3
scalar rfspBalance2028 = -2.2
scalar tipoDeCambio2028 = 18.4
scalar balprimario2028 = -0.3
scalar costodeudaInterno2028 = 2.5
scalar costodeudaExterno2028 = 2.5

scalar shrfsp2029 = 48.8
scalar shrfspInterno2029 = 38.9
scalar shrfspExterno2029 = 10.0
scalar rfsp2029 = -2.7
scalar rfspPIDIREGAS2029 = -0.1
scalar rfspIPAB2029 = -0.1
scalar rfspFONADIN2029 = 0.0
scalar rfspDeudores2029 = 0.0
scalar rfspBanca2029 = 0.0
scalar rfspAdecuaciones2029 = -0.3
scalar rfspBalance2029 = -2.2
scalar tipoDeCambio2029 = 18.6
scalar balprimario2029 = -0.3
scalar costodeudaInterno2029 = 2.5
scalar costodeudaExterno2029 = 2.5

** Inputs: Archivo "`c(sysdir_site)'/users/$pais/$id/households.dta", SHRFSP, PEFs y LIFs.
** Outputs: Sostenibilidad de la deuda y brecha fiscal hasta 2030.
noisily FiscalGap, anio(`=anioPE') end(2030) aniomin(2016) $nographs desde(2016) discount(10) //update //anio(`=aniovp')



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
