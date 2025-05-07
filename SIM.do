****
**** SIMULADOR FISCAL CIEP (7 de mayo de 2025)
**** ver: ReadMe.md
**** Autor: Ricardo Cantú Calderón (ricardocantu@ciep.mx)
****



***
**# 0. Setup
***
clear all
macro drop _all
capture log close _all
timer on 1


** Directorios de trabajo (uno por computadora)
if "`c(username)'" == "ricardo" {						// iMac Ricardo
	sysdir set SITE "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
	//global export "/Users/ricardo/CIEP Dropbox/TextbookCIEP/images"
}
else if "`c(username)'" == "servidorciep" {					// Servidor CIEP
	sysdir set SITE "/home/servidorciep/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
	//global export "/home/servidorciep/CIEP Dropbox/TextbookCIEP/images"
}
else if "`c(console)'" != "" {							// Servidor Web
	sysdir set SITE "/SIM/OUT/6/"
}


** Parámetros iniciales
global id = "ciepmx"								// ID USUARIO
global paqueteEconomico "CGPE 2025"						// POLÍTICA FISCAL

local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
scalar aniovp = substr(`"`=trim("`fecha'")'"',1,4)				// ANIO VALOR PRESENTE
scalar anioPE = 2025								// ANIO PAQUETE ECONÓMICO

scalar anioenigh = 2022								// ANIO ENIGH


** Opciones
global nographs "nographs"							// SUPRIMIR GRAFICAS
//global update "update"							// UPDATE BASES DE DATOS
//global textbook "textbook"							// SCALAR TO LATEX
//global output "output"								// ARCHIVO DE SALIDA (WEB)
	if "$output" != "" {
		quietly log using `"`c(sysdir_site)'/users/$id/output.txt"', replace text name(output)
		quietly log off output
	}



***
**# 1. DEMOGRAFÍA
***
global entidadesL `" "Aguascalientes" "Baja California" "Baja California Sur" "Campeche" "Coahuila" "Colima" "Chiapas" "Chihuahua" "Ciudad de México" "Durango" "Guanajuato" "Guerrero" "Hidalgo" "Jalisco" "Estado de México" "Michoacán" "Morelos" "Nayarit" "Nuevo León" "Oaxaca" "Puebla" "Querétaro" "Quintana Roo" "San Luis Potosí" "Sinaloa" "Sonora" "Tabasco" "Tamaulipas" "Tlaxcala" "Veracruz" "Yucatán" "Zacatecas" "Nacional" "'


** 1.1 Pirámide demográfica 
//foreach entidad of global entidadesL {
	forvalues anio = `=anioPE'(1)`=anioPE' {
		//noisily Poblacion if entidad == "`entidad'", anioi(`anio') aniofinal(`=`=anioPE'+25') $textbook
	}
//}



**/
**# 2. ECONOMÍA
***
global pib2025 = 1.4541								// CRECIMIENTO ANUAL PIB
global pib2026 = 2.0708								// <-- AGREGAR O QUITAR AÑOS
global pib2027 = 2.5
global pib2028 = 2.5
global pib2029 = 2.5
global pib2030 = 2.5

global def2025 = 4.4								// CRECIMIENTO ANUAL PRECIOS IMPLÍCITOS
global def2026 = 4.0								// <-- AGREGAR O QUITAR AÑOS
global def2027 = 3.5
global def2028 = 3.5
global def2029 = 3.5
global def2030 = 3.5

global inf2025 = 3.5								// CRECIMIENTO ANUAL INFLACIÓN
global inf2026 = 3.0								// <-- AGREGAR O QUITAR AÑOS
global inf2027 = 3.0
global inf2028 = 3.0
global inf2029 = 3.0
global inf2030 = 3.0


** 2.1 Producto Interno Bruto
//noisily PIBDeflactor, aniovp(`=aniovp') geodef(1993) geopib(1993) $update $textbook


** 2.2 Sistema de Cuentas Nacionales
//noisily SCN, anio(`=aniovp') $update $textbook



**/
**# 3. SISTEMA FISCAL
***

** 3.1 Ley de Ingresos de la Federación
//noisily LIF, by(divSIM) rows(1) anio(`=anioPE') desde(`=`=anioPE'-15') min(0) title("Ingresos presupuestarios") $update nographs
//LIF if divLIF <= 6, by(divLIF) rows(1) anio(`=anioPE') desde(`=anioPE-15') min(0) title("Impuestos y contribuciones")
//LIF if divLIF > 6 & divLIF != 10, by(divLIF) rows(1) anio(`=anioPE') desde(`=anioPE-15') min(0) title("Ingresos propios")

//postfile TE double(anio ISRAS ISRPF CUOTAS IngLab ISRPM OTROSK IngCap IVA ISAN IEPSNP IEPSP IMPORT Consumo) using `"`c(sysdir_site)'/03_temp/TE.dta"', replace
forvalues anio = `=anioPE'(1)`=anioPE' {

	** 3.1.1 Parámetros: Ingresos **
	scalar ISRAS       =   3.678 //    ISR (asalariados)
	scalar ISRPF       =   0.233 //    ISR (personas f{c i'}sicas)
	scalar CUOTAS      =   1.679 //    Cuotas (IMSS)

	scalar ISRPM       =   4.049 //    ISR (personas morales)
	scalar OTROSK      =   1.290 //    Productos, derechos, aprovech.

	scalar FMP         =   0.779 //    Fondo Mexicano del Petróleo
	scalar PEMEX       =   2.397 //    Organismos y empresas (Pemex)
	scalar CFE         =   1.501 //    Organismos y empresas (CFE)
	scalar IMSS        =   0.118 //    Organismos y empresas (IMSS)
	scalar ISSSTE      =   0.162 //    Organismos y empresas (ISSSTE)

	scalar IVA         =   4.074 //    IVA
	scalar ISAN        =   0.057 //    ISAN
	scalar IEPSNP      =   0.669 //    IEPS (no petrolero)
	scalar IEPSP       =   1.318 //    IEPS (petrolero)
	scalar IMPORT      =   0.423 //    Importaciones


	** 3.1.2 Tasas Efectivas **/
	//capture scalar drop ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA ISAN IEPSNP IEPSP IMPORT
	noisily TasasEfectivas, anio(`anio')
	//post TE (`anio') (`=ISRASPor') (`=ISRPFPor') (`=CUOTASPor') (`=YlImpPor') ///
		//(`=ISRPMPor') (`=OTROSKPor') (`=IngKPrivadoTotPor') ///
		//(`=IVAPor') (`=ISANPor') (`=IEPSNPPor') (`=IEPSPPor') (`=IMPORTPor') (`=ingconsumoPor')
}
//postclose TE

if "$nographs" != "nographs" {
	use "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/03_temp/TE.dta", clear
	twoway connected IngLab IngCap Consumo anio, ///
		title("{bf:Tasas efectivas por tipos de impuesto}") ///
		xtitle("") ytitle("Tasa efectiva (%)") ///
		xlabel(`=anioPE-25'(1)`=anioPE') ///
		legend(label(1 "Impuestos al trabajo") ///
		label(2 "Impuestos al capital") ///
		label(3 "Impuestos al consumo")) ///
		name(TE, replace)
}


** 3.2 Presupuesto de Egresos de la Federación **
//noisily PEF, by(divSIM) rows(2) min(0) anio(`=anioPE') desde(`=`=anioPE'-1') title("Gasto presupuestario") $update

//postfile GastoPC double(anio iniciaA basica medsup superi posgra eduadu otrose invere cultur invest ssa imssbien imss issste pemex issfam invers pam penimss penisss penpeme penotro gascfe gaspemex gassener gasinverf gascosdeue gasinfra gasotros gasfeder gascosto IngBas gasmadres gascuidados) using `"`c(sysdir_site)'/03_temp/GastoPC.dta"', replace
forvalues anio = `=anioPE'(1)`=anioPE' {

	** 3.2.1 Parámetros: Gasto **
	scalar iniciaA     =     370 //    Inicial
	scalar basica      =   29529 //    Educación b{c a'}sica
	scalar medsup      =   28713 //    Educación media superior
	scalar superi      =   41404 //    Educación superior
	scalar posgra      =   66122 //    Posgrado
	scalar eduadu      =   40517 //    Educación para adultos
	scalar otrose      =    1720 //    Otros gastos educativos
	scalar invere      =     675 //    Inversión en educación
	scalar cultur      =     173 //    Cultura, deportes y recreación
	scalar invest      =     398 //    Ciencia y tecnología
	
	scalar ssa         =     276 //    SSalud
	scalar imssbien    =    3728 //    IMSS-Bienestar
	scalar imss        =    8923 //    IMSS (salud)
	scalar issste      =   11161 //    ISSSTE (salud)
	scalar pemex       =   29562 //    Pemex (salud)
	scalar issfam      =   18040 //    ISSFAM (salud)
	scalar invers      =     240 //    Inversión en salud

	scalar pam         =   39356 //    Pensión Bienestar
	scalar penimss     =  307742 //    Pensión IMSS
	scalar penisss     =  410655 //    Pensión ISSSTE
	scalar penpeme     =  923092 //    Pensión Pemex
	scalar penotro     = 3336107 //    Pensión CFE, LFC, ISSFAM, Ferronales

	scalar gascfe      =    3146 //    Gasto en CFE
	scalar gaspemex    =    1129 //    Gasto en Pemex
	scalar gassener    =     690 //    Gasto en SENER
	scalar gasinverf   =    3182 //    Gasto en inversión (energía)
	scalar gascosdeue  =    1397 //    Gasto en costo de la deuda (energía)

	scalar gasinfra    =    3966 //    Gasto en Otras Inversiones
	scalar gasotros    =    4233 //    Otros gastos
	scalar gasfeder    =   10720 //    Participaciones y Otras aportaciones
	scalar gascosto    =    9356 //    Gasto en Costo de la deuda

	scalar IngBas      =       0 //    Ingreso b{c a'}sico
	scalar ingbasico18 =       1 //    1: Incluye menores de 18 anios, 0: no
	scalar ingbasico65 =       1 //    1: Incluye mayores de 65 anios, 0: no
	scalar gasmadres   =     492 //    Apoyo a madres trabajadoras
	scalar gascuidados =    3339 //    Gasto en cuidados


	** 3.2.2 Gasto per cápita **/
	//capture scalar drop iniciaA basica medsup superi posgra eduadu otrose invere cultur invest ///
		//ssa imssbien imss issste pemex issfam invers ///
		//pam penimss penisss penpeme penotro ///
		//gascfe gaspemex gassener gasinverf gascosdeue ///
		//gasinfra gasotros gasfeder gascosto ///
		//IngBas gasmadres gascuidados
	noisily GastoPC, aniope(`anio') aniovp(`=aniovp')
	//post GastoPC (`anio') (`=iniciaA') (`=basica') (`=medsup') (`=superi') ///
		//(`=posgra') (`=eduadu') (`=otrose') (`=invere') (`=cultur') (`=invest') ///
		//(`=ssa') (`=imssbien') (`=imss') (`=issste') (`=pemex') (`=issfam') (`=invers') ///
		//(`=pam') (`=penimss') (`=penisss') (`=penpeme') (`=penotro') ///
		//(`=gascfe') (`=gaspemex') (`=gassener') (`=gasinverf') (`=gascosdeue') ///
		//(`=gasinfra') (`=gasotros') (`=gasfeder') (`=gascosto') ///
		//(`=IngBas') (`=gasmadres') (`=gascuidados')
}
//postclose GastoPC

if "$nographs" != "nographs" {
	use "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/03_temp/GastoPC.dta", clear
	twoway connected iniciaA basica medsup superi posgra eduadu otrose invere cultur anio, ///
		title("{bf:Gasto per cápita en educación}") ///
		xtitle("") ytitle("MXN `=aniovp'") ///
		xlabel(`=anioPE-10'(1)`=anioPE') ///
		legend(label(1 "Inicia A") ///
		label(2 "Educación básica") ///
		label(3 "Educación media superior") ///
		label(4 "Educación superior") ///
		label(5 "Posgrado") ///
		label(6 "Educación para adultos") ///
		label(7 "Otros gastos educativos") ///
		label(8 "Inversión en educación") ///
		label(9 "Cultura, deportes y recreación") ///
		label(10 "Ciencia y tecnología")) ///
		name(GastoPC_Educacion, replace)

	twoway connected ssa imssbien imss issste pemex issfam invers anio, ///
		title("{bf:Gasto per cápita en salud}") ///
		xtitle("") ytitle("MXN `=aniovp'") ///
		xlabel(`=anioPE-10'(1)`=anioPE') ///
		legend(label(1 "SSalud") ///
		label(2 "IMSS-Bienestar") ///
		label(3 "IMSS (salud)") ///
		label(4 "ISSSTE (salud)") ///
		label(5 "Pemex (salud)") ///
		label(6 "ISSFAM (salud)") ///
		label(7 "Inversión en salud")) ///
		name(GastoPC_Salud, replace)

	twoway connected pam penimss penisss penpeme penotro anio, ///
		title("{bf:Gasto per cápita en pensiones}") ///
		xtitle("") ytitle("MXN `=aniovp'") ///
		xlabel(`=anioPE-10'(1)`=anioPE') ///
		legend(label(1 "Pensión Bienestar") ///
		label(2 "Pensión IMSS") ///
		label(3 "Pensión ISSSTE") ///
		label(4 "Pensión Pemex") ///
		label(5 "Pensión CFE, LFC, ISSFAM, Ferronales")) ///
		name(GastoPC_Pensiones, replace)

	twoway connected gascfe gaspemex gassener gasinverf gascosdeue anio, ///
		title("{bf:Gasto per cápita en energía}") ///
		xtitle("") ytitle("MXN `=aniovp'") ///
		xlabel(`=anioPE-10'(1)`=anioPE') ///
		legend(label(1 "Gasto en CFE") ///
		label(2 "Gasto en Pemex") ///
		label(3 "Gasto en SENER") ///
		label(4 "Gasto en inversión (energía)") ///
		label(5 "Gasto en costo de la deuda (energía)")) ///
		name(GastoPC_Energia, replace)
	
	twoway connected gasinfra gasotros gasfeder gascosto anio, ///
		title("{bf:Gasto per cápita en otros gastos}") ///
		xtitle("") ytitle("MXN `=aniovp'") ///
		xlabel(`=anioPE-10'(1)`=anioPE') ///
		legend(label(1 "Gasto en Otras inversiones") ///
		label(2 "Otros gastos") ///
		label(3 "Participaciones y Otras aportaciones") ///
		label(4 "Gasto en Costo de la deuda")) ///
		name(GastoPC_Otros, replace)

	twoway connected IngBas gasmadres gascuidados anio, ///
		title("{bf:Gasto per cápita en transferencias}") ///
		xtitle("") ytitle("MXN `=aniovp'") ///
		xlabel(`=anioPE-10'(1)`=anioPE') ///
		legend(label(1 "Ingreso básico") ///
		label(2 "Apoyo a madres trabajadoras") ///
		label(3 "Gasto en cuidados")) ///
		name(GastoPC_Transferencias, replace)
}

** 3.3 Saldo Histórico de Requerimientos Financieros del Sector Público

/** 3.3.1 Parámetros: SHRFSP **
scalar tasaEfectiva = 6.3782

global shrfsp2024 = 51.4
global shrfspInterno2024 = 38.5
global shrfspExterno2024 = 12.9
global rfsp2024 = 5.9
global rfspPIDIREGAS2024 = -0.02
global rfspIPAB2024 = 0.03
global rfspFONADIN2024 = 0.04
global rfspDeudores2024 = 0.01
global rfspBanca2024 = -0.01
global rfspAdecuaciones2024 = 0.81
global rfspBalance2024 = 5.0
global tipoDeCambio2024 = 18.2
global balprimario2024 = -1.4
global costodeudaInterno2024 = 3.6
global costodeudaExterno2024 = 3.6

global shrfsp2025 = 51.4
global shrfspInterno2025 = 39.8
global shrfspExterno2025 = 11.6
global rfsp2025 = 3.9
global rfspPIDIREGAS2025 = 0.15
global rfspIPAB2025 = 0.1
global rfspFONADIN2025 = 0.03
global rfspDeudores2025 = 0.01
global rfspBanca2025 = -0.01
global rfspAdecuaciones2025 = 0.44
global rfspBalance2025 = 3.2
global tipoDeCambio2025 = 18.7
global balprimario2025 = -0.6
global costodeudaInterno2025 = 3.8
global costodeudaExterno2025 = 3.8

global shrfsp2026 = 51.4
global shrfspInterno2026 = 40.5
global shrfspExterno2026 = 10.9
global rfsp2026 = 3.2
global rfspPIDIREGAS2026 = 0.1
global rfspIPAB2026 = 0.1
global rfspFONADIN2026 = 0.0
global rfspDeudores2026 = 0.0
global rfspBanca2026 = 0.0
global rfspAdecuaciones2026 = 0.3
global rfspBalance2026 = 2.7
global tipoDeCambio2026 = 18.5
global balprimario2026 = -0.5
global costodeudaInterno2026 = 3.2
global costodeudaExterno2026 = 3.2

global shrfsp2027 = 51.4
global shrfspInterno2027 = 40.8
global shrfspExterno2027 = 10.6
global rfsp2027 = 2.9
global rfspPIDIREGAS2027 = 0.1
global rfspIPAB2027 = 0.1
global rfspFONADIN2027 = 0.0
global rfspDeudores2027 = -0.1
global rfspBanca2027 = 0.0
global rfspAdecuaciones2027 = 0.3
global rfspBalance2027 = 2.4
global tipoDeCambio2027 = 18.7
global balprimario2027 = -0.5
global costodeudaInterno2027 = 2.8
global costodeudaExterno2027 = 2.8

global shrfsp2028 = 51.4
global shrfspInterno2028 = 41.1
global shrfspExterno2028 = 10.3
global rfsp2028 = 2.9
global rfspPIDIREGAS2028 = 0.1
global rfspIPAB2028 = 0.1
global rfspFONADIN2028 = 0.0
global rfspDeudores2028 = 0.0
global rfspBanca2028 = 0.0
global rfspAdecuaciones2028 = 0.3
global rfspBalance2028 = 2.4
global tipoDeCambio2028 = 18.9
global balprimario2028 = -0.4
global costodeudaInterno2028 = 2.8
global costodeudaExterno2028 = 2.8

global shrfsp2029 = 51.4
global shrfspInterno2029 = 41.4
global shrfspExterno2029 = 10.0
global rfsp2029 = 2.9
global rfspPIDIREGAS2029 = 0.1
global rfspIPAB2029 = 0.1
global rfspFONADIN2029 = 0.0
global rfspDeudores2029 = 0.0
global rfspBanca2029 = 0.0
global rfspAdecuaciones2029 = 0.3
global rfspBalance2029 = 2.4
global tipoDeCambio2029 = 19.1
global balprimario2029 = -0.4
global costodeudaInterno2029 = 2.7
global costodeudaExterno2029 = 2.7

global shrfsp2030 = 51.4
global shrfspInterno2030 = 41.7
global shrfspExterno2030 = 9.7
global rfsp2030 = 2.9
global rfspPIDIREGAS2030 = 0.1
global rfspIPAB2030 = 0.1
global rfspFONADIN2030 = 0.0
global rfspDeudores2030 = 0.0
global rfspBanca2030 = 0.0
global rfspAdecuaciones2030 = 0.3
global rfspBalance2030 = 2.4
global tipoDeCambio2030 = 19.3
global balprimario2030 = -0.4
global costodeudaInterno2030 = 2.7
global costodeudaExterno2030 = 2.7

** 3.3.2 SHRFSP **/
noisily SHRFSP, anio(`=anioPE') ultanio(2008) $update $textbook $nographs



**/
**# 4. HOGARES: ARMONIZACIÓN MACRO-MICRO
***
forvalues anio = `=anioPE'(-1)`=anioPE' {

	** 4.1 Encuesta Nacional de Ingresos y Gastos de los Hogares (Usos)
	capture confirm file "`c(sysdir_site)'/04_master/`=anioenigh'/expenditures.dta"
	if _rc != 0 | "$update" == "update" ///
		noisily run "`c(sysdir_site)'/Expenditure.do" `anio'


	** 4.2 Encuesta Nacional de Ingresos y Gastos de los Hogares (Recursos)
	capture confirm file "`c(sysdir_site)'/04_master/`=anioenigh'/households.dta"
	if _rc != 0 | "$update" == "update" ///
		noisily run `"`c(sysdir_site)'/Households.do"' `anio'


	** 4.3 Perfiles de la política económica actual
	noisily di _newline in y "PerfilesSim `anio'"
	capture confirm file "`c(sysdir_site)'/04_master/perfiles`anio'.dta"
	if _rc != 0 | "$update" == "update" ///
		noisily run "`c(sysdir_site)'/PerfilesSim.do" `anio'
}



**/
**# 5. SIMULACIONES
***

** 5.1 Módulo ISR

** 5.1.1 Parámetros: ISR
* Anexo 8 de la Resolución Miscelánea Fiscal para 2024 *
* Tarifa para el cálculo del impuesto correspondiente al ejericio 2024 a que se refieren los artículos 97 y 152 de la Ley del ISR
* Tabla del subsidio para el empleo aplicable a la tarifa del numeral 5 del rubro B (página 773) *
*             INFERIOR			SUPERIOR		CF		TASA
matrix ISR =  (0.01,			8952.49,		0.0,		1.92	\    /// 1
		8952.49+.01,		75984.55,		171.88,		6.40	\    /// 2
		75984.55+.01,		133536.07,		4461.94,	10.88	\    /// 3
		133536.07+.01,		155229.80,		10723.55,	16.00	\    /// 4
		155229.80+.01,		185852.57,		14194.54,	17.92	\    /// 5
		185852.57+.01,		374837.88,		19682.13,	21.36	\    /// 6
		374837.88+.01,		590795.99,		60049.40,	23.52	\    /// 7
		590795.99+.01,		1127926.84,		110842.74,	30.00	\    /// 8
		1127926.84+.01,		1503902.46,		271981.99,	32.00	\    /// 9
		1503902.46+.01,		4511707.37,		392294.17,	34.00	\    /// 10
		4511707.37+.01,		1E+12,			1414947.85,	35.00)	     //  11

*             INFERIOR			SUPERIOR		SUBSIDIO
matrix	SE =  (0.01,			1768.96*12,		407.02*12		\    /// 1
		1768.96*12+.01,		2653.38*12,		406.83*12		\    /// 2
		2653.38*12+.01,		3472.84*12,		406.62*12		\    /// 3
		3472.84*12+.01,		3537.87*12,		392.77*12		\    /// 4
		3537.87*12+.01,		4446.15*12,		382.46*12		\    /// 5
		4446.15*12+.01,		4717.18*12,		354.23*12		\    /// 6
		4717.18*12+.01,		5335.42*12,		324.87*12		\    /// 7
		5335.42*12+.01,		6224.67*12,		294.63*12		\    /// 8
		6224.67*12+.01,		7113.90*12,		253.54*12		\    /// 9
		7113.90*12+.01,		7382.33*12,		217.61*12		\    /// 10
		7382.33*12+.01,		1E+12,			0)		 	     //  11

* Artículo 151, último párrafo (LISR) *
*            Ex. SS.MM.	Ex. 	% ing. gravable		% Informalidad PF	% Informalidad Salarios
matrix DED = (5,		15,			93.02, 			18.86)

* Artículo 9, primer párrafo (LISR) * 
*           Tasa ISR PM.	% Informalidad PM
matrix PM = (30,			48.45)

** 5.1.2 Parámetros: IMSS e ISSSTE **
* Informe al Ejecutivo Federal y al Congreso de la Unión la situación financiera y los riesgos del IMSS 2021-2022 *
* Anexo A, Cuadro A.4 *
matrix CSS_IMSS = ///
///		PATRONES	TRABAJADORES	GOBIERNO FEDERAL
		(5.42,		0.44,			3.21	\   /// Enfermedad y maternidad, asegurados (Tgmasg*)
		1.05,		0.37,			0.08	\   /// Enfermedad y maternidad, pensionados (Tgmpen*)
		1.75,		0.63,			0.13	\   /// Invalidez y vida (Tinvyvida*)
		1.83,		0.00,			0.00	\   /// Riesgos de trabajo (Triesgo*)
		1.00,		0.00,			0.00	\   /// Guarderias y prestaciones sociales (Tguard*)
		5.15,		1.12,			1.49	\   /// Retiro, cesantia en edad avanzada y vejez (Tcestyvej*)
		0.00,		0.00,			6.55)	    //  Cuota social -- hasta 25 UMA -- (TcuotaSocIMSS*)

* Informe Financiero Actuarial ISSSTE 2021 *
matrix CSS_ISSSTE = ///
///		PATRONES	TRABAJADORES	GOBIERNO FEDERAL
		(7.375,		2.750,			391.0	\   /// Seguro de salud, trabajadores en activo y familiares (Tfondomed* / TCuotaSocISSTEF)
		0.720,		0.625,			0.000	\   /// Seguro de salud, pensionados y familiares (Tpensjub*)
		0.750,		0.000,			0.000	\   /// Riesgo de trabajo
		0.625,		0.625,			0.000	\   /// Invalidez y vida
		0.500,		0.500,			0.000	\   /// Servicios sociales y culturales
		6.125,		2+3.175,		5.500	\   /// Retiro, cesantia en edad avanzada y vejez
		0.000,		5.000,			0.000	\   /// Vivienda
		0.000,		0.000,			13.9)		//  Cuota social

** 5.1.3 Submódulo ISR (web) **/
if "`cambioisrpf'" == "" {
	noisily run "`c(sysdir_site)'/ISR_Mod.do"
	scalar ISRAS  = ISR_AS_Mod						// NUEVA ESTIMACIÓN ISR ASALARIADOS
	scalar ISRPF  = ISR_PF_Mod						// NUEVA ESTIMACIÓN ISR P. FÍSICAS
	scalar ISRPM  = ISR_PM_Mod						// NUEVA ESTIMACIÓN ISR P. MORALES
	scalar CUOTAS = CUOTAS_Mod						// NUEVA ESTIMACIÓN CUOTAS IMSS
}


** 5.2 Módulo IVA

** 5.2.1 Parámetros: IVA
matrix IVAT = (16 \     ///  1  Tasa general 
	1  \     ///  2  Alimentos, input[1]: Tasa Cero, [2]: Exento, [3]: Gravado
	2  \     ///  3  Alquiler, idem
	1  \     ///  4  Canasta basica, idem
	2  \     ///  5  Educacion, idem
	3  \     ///  6  Consumo fuera del hogar, idem
	3  \     ///  7  Mascotas, idem
	1  \     ///  8  Medicinas, idem
	1  \     ///  9  Toallas sanitarias, idem
	3  \     /// 10  Otros, idem
	2  \     /// 11  Transporte local, idem
	3  \     /// 12  Transporte foraneo, idem
	15.1)   //  13  Evasion e informalidad IVA, input[0-100]

** 5.2.2 Parámetros: IEPS
* Fuente: Ley del IEPS, Artículo 2.
*              Ad valorem	Específico
matrix IEPST = (26.5	,	0 		\ /// Cerveza y alcohol 14
		30.0	,	0 		\ /// Alcohol 14+ a 20
		53.0	,	0 		\ /// Alcohol 20+
		160.0	,	0.6166		\ /// Tabaco y cigarros
		30.0	,	0 		\ /// Juegos y sorteos
		3.0	,	0 		\ /// Telecomunicaciones
		25.0	,	0 		\ /// Bebidas energéticas
		0	,	1.5737		\ /// Bebidas saborizadas
		8.0	,	0 		\ /// Alto contenido calórico
		0	,	10.7037		\ /// Gas licuado de petróleo (propano y butano)
		0	,	21.1956		\ /// Combustibles (petróleo)
		0	,	19.8607		\ /// Combustibles (diésel)
		0	,	43.4269		\ /// Combustibles (carbón)
		0	,	21.1956		\ /// Combustibles (combustible para calentar)
		0	,	6.1752		\ /// Gasolina: magna
		0	,	5.2146		\ /// Gasolina: premium
		0	,	6.7865		) // Gasolina: diésel

** 5.2.3 Submódulo IVA (web) **/
if "`cambioiva'" == "" {
	noisily run "`c(sysdir_site)'/IVA_Mod.do"
	scalar IVA = IVA_Mod							// NUEVA ESTIMACIÓN IVA
}


** 5.4 Subnacionales
//noisily run "Subnacional.do" $update



**/
**# 6. CICLO DE VIDA
***
use `"`c(sysdir_site)'/users/$id/ingresos.dta"', clear
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/gastos.dta", nogen
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/isr_mod.dta", ///
	nogen replace update keepus(ISRAS ISRPF ISRPM CUOTAS)
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/iva_mod.dta", ///
	nogen replace update keepus(IVA)


** 6.1 (+) Impuestos y aportaciones
capture drop ImpuestosAportaciones
egen ImpuestosAportaciones = rsum(ISRPM_Sim ISRAS_Sim ISRPF_Sim CUOTAS_Sim IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim) // FMP OTROSK
label var ImpuestosAportaciones "Impuestos y otras contribuciones"
//noisily Perfiles ImpuestosAportaciones [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
//noisily Simulador ImpuestosAportaciones [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)


** 6.2 (-) Impuestos y aportaciones
capture drop Transferencias
egen Transferencias = rsum(Pensiones Pensión_AM IngBasico Educación Salud) // Otras_inversiones
label var Transferencias "Transferencias públicas"
//noisily Perfiles Transferencias [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
//noisily Simulador Transferencias [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)


** 6.3 (=) Aportaciones netas
capture drop AportacionesNetas
g AportacionesNetas = ImpuestosAportaciones - Transferencias
label var AportacionesNetas "Ciclo de vida de las aportaciones netas"
noisily Perfiles AportacionesNetas [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
//noisily Simulador AportacionesNetas [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)


** 6.4 (*) Cuentas generacionales
//noisily CuentasGeneracionales AportacionesNetas, anio(`=anioPE') discount(7)



**/
**# 7. DEUDA + FISCAL GAP
***

** 7.1 Brecha fiscal
noisily FiscalGap, anio(`=anioPE') end(2030) aniomin(2015) $nographs desde(`=anioPE-15') discount(10) //update


** 7.2 Sankey del sistema fiscal
foreach k in decil grupoedad /*sexo rural escol*/ {
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
