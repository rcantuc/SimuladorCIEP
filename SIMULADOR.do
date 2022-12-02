******************************
***                        ***
***    SIMULADOR FISCAL    ***
***                        ***
******************************
clear all
macro drop _all
capture log close _all
timer on 1





******************************************************
***                                                ***
***    0. DIRECTORIOS DE TRABAJO (PROGRAMACION)    ***
***                                                ***
******************************************************
if "`c(username)'" == "ricardo" {                                               // Mac Ricardo
	sysdir set SITE "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladorCIEP/5.3/SimuladorCIEP/"
}
if "`c(username)'" == "ciepmx" & "`c(console)'" == "" {                         // Linux ServidorCIEP
	sysdir set SITE "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladorCIEP/5.3/SimuladorCIEP/"
}
if "`c(username)'" == "ciepmx" & "`c(console)'" == "console" {                  // Linux ServidorCIEP (WEB)
	sysdir set SITE "/SIM/OUT/5/5.3/"
}





************************/
***                   ***
***    1. OPCIONES    ***
***                   ***
*************************
*global export "/Users/ricardo/Dropbox (CIEP)/Textbook/images/"                 // EXPORTAR IMAGENES EN...
*global update "update"                                                         // UPDATE DATASETS/OUTPUTS
global output "output"                                                          // IMPRIMIR OUTPUTS (WEB)
global nographs "nographs"                                                      // SUPRIMIR GRAFICAS





*****************************************************
***                                               ***
***    2. DIRECTORIOS Y PARÁMETROS DEL USUARIO    ***
***                                               ***
*****************************************************



***************************
***    2.1. USERNAME    ***
***************************
global id = "{{idSession}}"                                                     // ID DEL USUARIO
capture mkdir `"`c(sysdir_site)'/SIM/"'
capture mkdir `"`c(sysdir_site)'/users/"'
capture mkdir `"`c(sysdir_site)'/users/$id/"'



**************************************************
***    2.2. CRECIMIENTO Y DEFLACTOR DEL PIB    ***
**************************************************
scalar aniovp = 2023
scalar anioend = 2030

global pib2022 = {{CRECPIB2022}} //2.4 //       CGPE 2023 (página 134)
global pib2023 = {{CRECPIB2023}} //2.9676 //    CGPE 2023 (página 134)
global pib2024 = {{CRECPIB2024}} //2.4 //       CGPE 2023 (página 134)
global pib2025 = {{CRECPIB2025}} //       CGPE 2023 (página 134) 
global pib2026 = {{CRECPIB2026}} //       CGPE 2023 (página 134) 
global pib2027 = {{CRECPIB2027}} //       CGPE 2023 (página 134) 
global pib2028 = {{CRECPIB2028}} //       CGPE 2023 (página 134) 

global def2022 = {{CRECDEF2022}} //    CGPE 2023 (página 134)
global def2023 = {{CRECDEF2023}} //    CGPE 2023 (página 134)
global def2024 = {{CRECDEF2024}} //    CGPE 2023 (página 134)
global def2025 = {{CRECDEF2025}} //    CGPE 2023 (página 134)
global def2026 = {{CRECDEF2026}} //    CGPE 2023 (página 134)
global def2027 = {{CRECDEF2027}} //    CGPE 2023 (página 134)
global def2028 = {{CRECDEF2028}} //    CGPE 2023 (página 134)

global tasaEfectiva = {{DEUDA0}} //6.6041 // Tasa de inter{c e'}s EFECTIVA
global tipoDeCambio = {{DEUDA1}} //20.4   // Tipo de cambio
global depreciacion = {{DEUDA2}} //0.2    // Depreciaci{c o'}n

PIBDeflactor, nographs



*************************
***    2.3. GASTOS    ***
*************************
if "$update" == "update" {
	noisily GastoPC
}
else {
	scalar basica      =   {{basica}} //26537 //    Educación b{c a'}sica
	scalar medsup      =   {{medsup}} //26439 //    Educación media superior
	scalar superi      =   {{superi}} //39157 //    Educación superior
	scalar posgra      =   {{posgra}} //64239 //    Posgrado
	scalar eduadu      =   {{eduadu}} //37573 //    Educación para adultos
	scalar otrose      =   {{otrose}} //3802 //    Otros gastos educativos

	scalar ssa         =   {{ssa}}    //  600 //    SSalud
	scalar imssbien    =   {{imssbien}} //    IMSS-Bienestar  
	scalar imss        =   {{imss}}   // 8273 //    IMSS (salud)
	scalar issste      =   {{issste}} //11072 //    ISSSTE (salud)
	scalar pemex       =   {{pemex}}  //27368 //    Pemex (salud) + ISSFAM (salud)
	
* Salud *
*scalar prospe = {{prospe}} // IMSS-Prospera*
*scalar segpop = {{segpop}} // Seguro Popular*

	scalar bienestar   =   {{bienestar}} //29239 //    Pensión Bienestar
	scalar penimss     =   {{penims}}    //169241 //    Pensión IMSS //se tomo como -> penims del simulador anterior
	scalar penisss     =   {{peniss}}    //249560 //    Pensión ISSSTE
	scalar penotro     =   {{penotr}}    //1507687 //    Pensión Pemex, CFE, Pensión LFC, ISSFAM, Otros

	scalar gascfe      =   {{gascfe}} //    Gasto en CFE 
	scalar gaspemex    =   {{gaspemex}} //    Gasto en Pemex 
	scalar gassener    =   {{gassener}} //    Gasto en SENER 
	scalar gasinfra    =   {{gasinfra}} //    Gasto en Inversión 
	scalar gascosto    =   {{gascosto}} //    Gasto en Costo de la deuda
	scalar gasfeder    =   {{gasfeder}} //    Participaciones y Otras aportaciones 
	scalar gasotros    =   {{gasotros}} //    Otros gastos 

	scalar IngBas      =    {{IngBas}}      //   0 //    Ingreso b{c a'}sico
	scalar ingbasico18 =    {{ingbasico18}} //   1 //    1: Incluye menores de 18 anios, 0: no
	scalar ingbasico65 =    {{ingbasico65}} //   1 //    1: Incluye mayores de 65 anios, 0: no

}


**************************/
***    2.4. INGRESOS    ***
***************************
if "$update" == "update" {
	noisily TasasEfectivas
}
else {
	scalar ISRAS   = ({{INGRESOS0}}/100*scalar(pibY)*(1+ 3.782*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // ISR (asalariados): 3.696
	scalar ISRPF   = ({{INGRESOS1}}/100*scalar(pibY)*(1+ 1.199*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // ISR (personas f{c i'}sicas): 0.240
	scalar CUOTAS  = ({{INGRESOS2}}/100*scalar(pibY)*(1+ 2.197*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Cuotas (IMSS): 1.499

	scalar ISRPM   = ({{INGRESOS4}}/100*scalar(pibY)*(1+ 4.664*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // ISR (personas morales): 4.064
	scalar OTROSK  = ({{INGRESOS5}}/100*scalar(pibY)*(1+-3.269*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Productos, derechos, aprovech.: 1.049

	scalar IVA     = ({{INGRESOS7}}/100*scalar(pibY)*(1+ 2.498*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // IVA: 4.520
	scalar ISAN    = ({{INGRESOS8}}/100*scalar(pibY)*(1+ 3.565*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // ISAN: 0.049
	scalar IEPSNP  = ({{INGRESOS9}}/100*scalar(pibY)*(1+ 0.362*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // IEPS (no petrolero): 0.887
	scalar IEPSP   =  {{INGRESOS10}}     // IEPS (petrolero): 0.662
	scalar IMPORT  = ({{INGRESOS11}}/100*scalar(pibY)*(1+ 5.303*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Importaciones: 0.313

	scalar FMP     = ({{INGRESOS15}}/100*scalar(pibY)*(1+-7.718*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Fondo Mexicano del Petróleo: 1.553

	scalar IMSS    = ({{INGRESOS13}}/100*scalar(pibY)*(1+-2.685*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Organismos y empresas (IMSS): 0.091
	scalar ISSSTE  = ({{INGRESOS14}}/100*scalar(pibY)*(1+-3.058*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Organismos y empresas (ISSSTE): 0.159
	scalar PEMEX   = ({{INGRESOS16}}/100*scalar(pibY)*(1+ 1.379*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Organismos y empresas (Pemex): 2.632
	scalar CFE     = ({{INGRESOS17}}/100*scalar(pibY)*(1+-3.024*(${pib2023}-2.9676)/100))/scalar(pibY)*100 // Organismos y empresas (CFE): 1.271

}




********************************************************
***       2.4.1. Impuesto Sobre la Renta (ISR)       ***
********************************************************
*             Inferior		Superior	CF		Tasa
matrix ISR =  (0.01,		7735.00,	0.0,		{{ISRTASA0}}	\    /// 1
              7735.01,		65651.07,	148.51,		{{ISRTASA1}}	\    /// 2
              65651.08,		115375.90,	3855.14,	{{ISRTASA2}}	\    /// 3
              115375.91,	134119.41,	9265.20,	{{ISRTASA3}}	\    /// 4
              134119.42,	160577.65,	12264.16,	{{ISRTASA4}}	\    /// 5
              160577.66,	323862.00,	17005.47,	{{ISRTASA5}}	\    /// 6
              323862.01,	510451.00,	51883.01,	{{ISRTASA6}}	\    /// 7
              510451.01,	974535.03,	95768.74,	{{ISRTASA7}}	\    /// 8
              974535.04,	1299380.04,	234993.95,	{{ISRTASA8}}	\    /// 9
              1299380.05,	3898140.12,	338944.34,	{{ISRTASA9}}	\    /// 10
              3898140.13,	1E+14,		1222522.76,	{{ISRTASA10}})	     //  11

*             Inferior		Superior	Subsidio
matrix	SE =  (0.01,		21227.52,	{{SE0}}		\    /// 1
              21227.53,		23744.40,	{{SE1}}		\    /// 2
              23744.41,		31840.56,	{{SE2}} 	\    /// 3
              31840.57,		41674.08,	{{SE3}}		\    /// 4
              41674.09,		42454.44,	{{SE4}}		\    /// 5
              42454.45,		53353.80,	{{SE5}}		\    /// 6
              53353.81,		56606.16,	{{SE6}}		\    /// 7
              56606.17,		64025.04,	{{SE7}}		\    /// 8
              64025.05,		74696.04,	{{SE8}}		\    /// 9
              74696.05,		85366.80,	{{SE9}}		\    /// 10
              85366.81,		88587.96,	{{SE10}}		\    /// 11
              88587.97, 	1E+14,		{{SE11}})		     	//  12

*            Ex. SS.MM.	Ex. 	% ing. gravable		% Informalidad PF	% Informalidad Salarios
matrix	DED	= 	({{DED0}},	{{DED1}}, 		{{DED2}}, 		{{DED3}})

*           Tasa ISR PM.	% Informalidad PM
matrix PM	= (	{{ISRMORA0}},	{{ISRMORA1}})

***       FIN: SIMULADOR ISR       ***
**************************************



***********************************************************
***       2.4.2. Impuesto al Valor Agregado (IVA)       ***
***********************************************************
matrix IVAT = ({{IVAT0}} \     ///  1  Tasa general 
               {{IVAT1}}  \     ///  2  Alimentos, input[1]: Tasa Cero, [2]: Exento, [3]: Gravado
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
***       FIN: SIMULADOR IVA       ***


****************************
***    2.4.5. DISPLAY    ***
****************************
noisily di _newline(10) in g _dup(23) "*" ///
	_newline in y " Simulador Fiscal CIEP" ///
	_newline in g _dup(23) "*" ///
	_newline in g "  A{c N~}O:  " in y "`=aniovp'" ///
	_newline in g "  USER: " in y "$id" ///
	_newline in g "  D{c I'}A:  " in y "`c(current_date)'" ///
	_newline in g "  HORA: " in y "`c(current_time)'" ///
	_newline in g _dup(23) "*"
if "$output" == "output" {
	quietly log using `"`c(sysdir_site)'/users/$id/output.txt"', replace text name(output)
	quietly log off output
}





************************************
***                              ***
***    3. POBLACION + ECONOMÍA   ***
***                              ***
***********************************
noisily Poblacion, aniofinal(`=scalar(anioend)') //$update
noisily PIBDeflactor, $update geodef(2013) geopib(2013)
noisily SCN, $update
*noisily Inflacion, $update





**************************/
***                     ***
***    4. HOUSEHOLDS    ***
***                     ***
***************************
capture confirm file "`c(sysdir_site)'/SIM/2020/households.dta"
if _rc != 0 {
	noisily run "`c(sysdir_site)'/Expenditure.do" `=aniovp'
	noisily run `"`c(sysdir_site)'/Households.do"' `=aniovp'
}
capture confirm file "`c(sysdir_site)'/users/ciepmx/bootstraps/1/ConsumoREC.dta"
if _rc != 0 {
	noisily run `"`c(sysdir_site)'/PerfilesSim.do"' `=aniovp'
}





******************************/
***                         ***
***    5. SISTEMA FISCAL    ***
***                         ***
*******************************
*noisily PEF, by(divPE) rows(2) min(0) $update
noisily GastoPC


** 5.1 Módulos **
if "`cambioisr'" == "1" {
	noisily run "`c(sysdir_site)'/ISR_Mod.do"
	scalar ISRAS = ISR_AS_Mod
	scalar ISRPF = ISR_PF_Mod
	scalar ISRPM = ISR_PM_Mod
}
if "`cambioiva'" == "1" {
	noisily run "`c(sysdir_site)'/IVA_Mod.do"
	scalar IVA = IVA_Mod
}


** 5.2 Integración **
*noisily LIF, by(divSIM) rows(2) min(0) eofp $update
noisily TasasEfectivas





*****************************/
***                        ***
***    6. CICLO DE VIDA    ***
***                        ***
******************************
use `"`c(sysdir_site)'/users/$id/households.dta"', clear
capture drop AportacionesNetas
g AportacionesNetas = ISRASSIM + ISRPFSIM + CUOTASSIM + ISRPMSIM /// + OTROSKSIM ///
	+ IVASIM + IEPSNPSIM + IEPSPSIM + ISANSIM + IMPORTSIM + FMPSIM ///
	- Pension - Educacion - Salud - IngBasico - _Infra - PenBienestar
label var AportacionesNetas "aportaciones netas"
noisily Simulador AportacionesNetas [fw=factor], base("ENIGH 2020") reboot anio(`=aniovp') folio("folioviv foliohog") $nographs
save "`c(sysdir_site)'/users/$id/households.dta", replace


** 6.2 CUENTA GENERACIONAL **
*noisily CuentasGeneracionales AportacionesNetas, anio(`=aniovp')


** 6.3 Sankey **
foreach k in /*grupoedad sexo decil*/ escol rural {
	noisily run "`c(sysdir_site)'/SankeySF.do" `k' `=aniovp'
}





********************************************
***                                       ***
***    7. PARTE IV: DEUDA + FISCAL GAP    ***
***                                       ***
*********************************************
*noisily SHRFSP, $update
noisily FiscalGap, anio(`=aniovp') end(`=anioend') aniomin(2015) $nographs $update





***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
run "`c(sysdir_site)'/output.do"
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
